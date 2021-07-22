clc;
close all;
clear;
%%%general main function for the optimization

%list of variables, save as a struct format
% -"const."* "opt."** "runSolarBESS."*** "runUpgrade."****
    % (other option instead of "results.", have two structs, one for running simulation for solar+BESS, another for running
    % it with rhe substation upgrade.)
% -all constants and input data arrays (remain unchaged)*
% Calculated once initially:*
% -overload costs for status quo
% -...
% Generated prior to optimizing:**
% -2d matrix for solar capacity
% -2d matrix for BESS capacity
% -2d matrix for solar-BESS NPV results (via running simulation)
% -1d array for substation upgrade
% -1d array for substation upgrade NPV results (via running simulation)
% Changed between each run: (can omit some when doing substation
% upgrade)***/****
% -solar generation
% -all net loads
% -BESS outputs
% -...
% Generated after optimization:***/****
% -Solar+BESS data from best run
% -Substation upgrade data from best run

%% load input data

%import data (placeholder)
input = readmatrix('2020DemandandSolar-Sheet1.csv');
input = input(1:end-1,:); %remove totals (last row)

%assign arrays from inport data
const.load = input(:,5); %5th column for load data in MW
const.solarGen1MW = input(:,9); %solar generation data for 1MW array
const.timeMat = input(:,1:3); %maxtrix data of the time
const.time = 1:length(const.timeMat);
const.time = const.time'; %time in hours for dataset
const.initalTimeOfDay = 0; %start at 12am
const.deltaTime = 1; % time increment IN HOURS

%%%%%%%%%%%%%%%%%%%%%
%%%%%%%BESS variables
const.initialEnergyBESS = 0; % MWh initial capacity
const.isSpecPower = 0; %if user specifies the power capacity directly (1), otherwise allows it to change based on a set hour duration for maximum power output
const.chargePowerCap = 60; %MW BESS charge Power Cap
const.dischargePowerCap = 60; %MW BESS discharge Power Cap
const.hourPowerCapBESS = 4; %power capacity of BESS expressed as the duration in hours for the BESS to discharge completely
const.percDoDCap = 95; % user specified maximum discharge of BESS as percent of total capacity, used in BESS function
%maximum slope in load, for posLoadLim will discharge BESS - for neg will
%charge
const.posLoadChangeLim = 10;
const.negLoadChangeLim = -10;



const.isLoadBasedBESS = 0; %(1) if average load based, (0) if time based
%--For percent of load based charge-discharge algorithm:
const.chargePerc = 100; %percentage of mean load to charge
const.dischargePerc = 115; %percentage of mean load to discharge
const.dischargeFactor = 60; %percentage for how much to bring down load to discharge threshold (0=none, 100=flat)
%--For time based charge-discharge algorithm:
const.emerBESS = 30; %percentage of energy capacity left for emergency overloads
const.startCharge = 0; %time in which batteries will start scheduled charge
const.endCharge = 7; %time in which batteries will end scheduled charge
const.startDischarge = 17; %time when batteries will start scheduled discharge
const.endDischarge = 21; %time when batteries will end scheduled discharge
const.chargeViaSolarThreshold = 50; %percent of solar generation to solar DC power rating, at which addition generation will be used to charge BESS if possible regardless of time

%for BESS lifetime and degredation
const.percBESSDeg = 0; %placeholder for now
const.isSpecLifetime = 1; %if lifetime is determined from the following options:
    %(0) from capacity degredation
    %(1) user specified number of years
    %(2) from total number of cycles
    %(3) total energy throughput per MWh storage
const.percMinCapacityBattRep = 80; %user specified degredation (min SOH) as percent of total capacity to get lifetime
const.yearsPerBattRep = 12; %user specificed lifetime directly in year
const.maxNumCyclesBattRep = 6000; %number of cycles before storage must be replaced
const.maxEnergyThruBattRep = 2500; %maximum energy throughput of ESS, per MWh of storage
%battery efficiency for charging/discharging via grid or solar, charge loss
const.inverterEfficiency = .962;
const.converterEfficiency = .98;
const.roundTripEfficiency = .86;
const.chargeLossFactor = 0.999958904;
%ALSO replacing batteries--future note: could add an additional input param. for battery
%type and have if-statements to select variables for time to replace, cost


%substation overload variables
const.npCapacity = 90; %MW - nameplate rating of the substation transformer
%adjustmentFactorMax = 25; %percent maximum tolerable increase above substation rating
%adjustmentFactor = 0.4; %percent tolerable increase above rating for every percent the 24hr mean capacity factor is below 100%


%%%%
%%costs/optimization parameters
%%%%
const.percLoadGrowth = 5;
const.percSolarDeg = 0.7; %from NREL 2020 PV cost benchmarks
const.priceCarbon = 51/1016.04691; %CO2 price per kg (will have option to select use)
const.rampCostPerMWDiff = 5; %cost of every MW/h ramp outside of the bounds specificed in ESS system specs


const.isBlackoutAtNP = 1; %option to allow user to have limited overloads
const.projectLifetime = 30; %years that the solar and BESS system will be used

%percent reducation in overal costs for solar and BESS each year -
%exponential decay rate as percentage
const.percCostReductionSolar = 0.9804; %from NREL website
const.percCostReductionBESS = 2.7848; %from NREL cost predictions (used average for 30 year prediction)

%Solar Investment Tax Credit
const.percITCSolar = 26;


%most of the following values are currently arbitrary
%instalation costs (USD)
const.instCostSolarPerMWUSD = 994135; %Cost = 994135*capacity(MW) +2.77E6 USD costs per MW for solar instalation
const.instCostSolarFixedUSD = 2.77E6;
const.instCostStoragePerMWhUSD = 340567; %Cost = 321612*capacity(MWh)+1.3E7 USD costs per MWh for BESS instalation
const.instCostStorageFixedUSD = 312041;
const.instCostSubstPerMWUSD = 300000; %based on inst. cost for 4MW transformer, USD costs per MW for substation upgrade
%for co2
const.instCostSolarPerMWCO2 = 474852.9633; %kg of CO2 costs per MW for solar instalation
const.instCostStoragePerMWhCO2 = 400000; %arbitrary - kg of CO2 costs per MWh for BESS instalation
const.instCostSubstPerMWCO2 = 1000000; %arbitrary - kg of CO2 costs per MW for substation upgrade

%annual maintaince costs (USD)
%NOTE, address variable change names
const.annualOMPerMWSolarUSD = 17460; %From NREL cost benchmark for kWdc of solar *1000, annual USD costs per MW of solar for maintaince
const.annualOMSolarFixedUSD = 0;
const.annualOMPerMWhStorageUSD = 8514.175; %from NREL 'Utility Scale Battery Storage' based on 2.5% of inst. costs - annual USD costs per MWh of BESS for maintaince
const.annualOMStorageFixedUSD = 7801.025; %2.5% inst. cost
const.annualOMPerMWSubstUSD = 75000; %arbitrary -annual USD costs per MW of substation for maintaince
%for co2
const.annualOMPerMWSolarCO2 = 43043.12345; %annual co2 costs per MW of solar for maintaince
const.annualOMPerMWhStorageCO2 = 30000; %arbitrary -annual co2 costs per MW of BESS for maintaince (could do 2.5% of inst.)
const.annualOMPerMWSubstCO2 = 50000; %arbitrary -annual co2 costs per MW of substation for maintaince

%power electronics replacement costs for solar and storage (CO2, USD)
%const.costHardwRepUSD = 10.135E6; %Uses mean cost of BESS function and solar function with capacity=0, USD costs for upgrading electronics for solar-storage
%const.costHardwRepFixedUSD = 7.4E6/100; %arbitrary? - Used NREL cost benchmark for 100MW-240MWh solar+BESS instalation, divided by 100
const.costHardwRepFixedUSD = 2.77E6; %used fixed costs of installation for PV (i.e. cost if capacity = 0)
const.yearsPerHardwRep = 10; %numbers of years until replacement of electronics is needed
const.costHardwRepPerMWCO2 = 0; %set to zero, as inverter costs factored into solar lifecylce co2 - kg of CO2 costs for upgrade, per MW solar

%battery replacement costs, based on 20% inst. cost
const.costBattRepPerMWhStorageUSD = 68113.4; %20% cited from NREL cost benchmark
const.costBattRepFixedUSD = 62408.2;



%kg of CO2 emissions due to generation of electricity that's non-solar
%emissionsPerMWh = 0.5; %EPA regulation for natural gas emission standards (imperial tons)
const.emissionsPerMWh = 202.8141544; %EIA emission data for natural gas, converted from lb-CO2/Mbtu to kg/MWh

%Overload costs
%costPerMWhOverloadUSD = 100+36.66+250; %Costs per MWh overload non-tolerable by substation (USD). Arbitrary, now unused
%const.costPerHourOverloadUSD = 7500; %arbitrary - cost for every hour a non-tolerable overload occurs
const.costPerMWhOverloadUSD = 725; %average cost for WTP to stop a blackout
const.costBaselinePerOverloadUSD = 200; %arbitrary - baseline cost of a damaging overload

%peak and off peak costs of energy generation (conventional power plant)
const.peakGenCostPerMWh = 36.66*1.2; %arbitrary
const.offPeakGenCostPerMWh = 36.66*0.75; %arbitrary
%peak start and end times for the cost of generation
const.peakTimeStart = 14; %3pm
const.peakTimeEnd = 20; %9pm

const.r = 3; %3 percent interest rate

%check for errors, display input data as load and 1MW solar
%potential errors: data entered wrong, or as NaN, constants set to wrong
%values that may cause errors.

%% initalize "opt." from inputs


%manual user input as an array matrix
const.isManualInput = 0; %(1) if user specifies inputs manually into a matrix
%solar cap
const.manualSolar = [0, 600];
const.manualSolarInstUSD = [NaN, NaN];
const.manualSolarOMUSD = [NaN, NaN];
%BESS cap
const.manualBESS = [100, 20];
const.manualBESSInstUSD = [NaN, NaN];
const.manualBESSOMUSD = [NaN, NaN];
%substation upgrades
const.manualSubst = [25, 50];
const.manualSubstInstUSD = [NaN, NaN];
const.manualSubstOMUSD = [NaN, NaN];

% %determine if manual inputs, all are entered for costs
% %will be used in cost function to set the cost of the installation if = 1
% %solar
% if (length(const.manualSolar) == length(const.manualSolarInstUSD)) && (length(const.manualSolar) == length(const.manualSolarOMUSD))
%     const.manualSolarCostsUSD = 1;
% else
%     const.manualSolarCostsUSD = 0;
% end
% %BESS
% if (length(const.manualBESS) == length(const.manualBESSInstUSD)) && (length(const.manualBESS) == length(const.manualBESSOMUSD))
%     const.manualBESSCostsUSD = 1;
% else
%     const.manualBESSCostsUSD = 0;
% end
% %substation
% if (length(const.manualSubst) == length(const.manualSubstInstUSD)) && (length(const.manualSubst) == length(const.manualSubstOMUSD))
%     const.manualSubstCostsUSD = 1;
% else
%     const.manualSubstCostsUSD = 0;
% end


%demo input data, later will be from GUI
const.solarCapMin = 0;
const.solarCapMax = 300;
const.BESSCapMin = 0;
const.BESSCapMax = 600;
const.upgradeMin = 0;
const.upgradeMax = 100;

const.deltaSolarCap = 5; %10MW difference
const.deltaBESSCap = 10; %10MWh difference between cases
const.deltaUpgrade = 1; %difference of 1MW between subst. upgrade cases

%compute arrays: (alternatively, could replace with linspace, and have a
%total number of test cases specified)
%will also need to add a condition in the case that the user manually
%enteres the cases
if const.isManualInput == 0
    solarCapacity = const.solarCapMin:const.deltaSolarCap:const.solarCapMax;
    BESSCapacity = const.BESSCapMin:const.deltaBESSCap:const.BESSCapMax;
    opt.substUpgrade = const.upgradeMin:const.deltaUpgrade:const.upgradeMax;
else %manual user inputs:
    solarCapacity = const.manualSolar;
    BESSCapacity = const.manualBESS;
    opt.substUpgrade = const.manualSubst;
end
const.solar_maxi = length(solarCapacity);
const.BESS_maxi = length(BESSCapacity);
const.upgrade_maxi = length(opt.substUpgrade);

%compute matricies for solar and BESS
%assume solar as x-axis, BESS and y-axis
[opt.solarCapacity, opt.BESSCapacity] = meshgrid(solarCapacity, BESSCapacity);

%initalize the arrays for NPV result from solar and BESS, subst. upgrade
opt.NPVSolarAndBESS = zeros(const.BESS_maxi,const.solar_maxi);
opt.NPVSubstUpgrade = zeros(const.upgrade_maxi,1);

disp("BESS, Solar data points");
disp(size(opt.NPVSolarAndBESS));
disp("size of substation upgrade array");
disp(length(opt.NPVSubstUpgrade));

%display estimated runtime...
disp("estimated runtime (sec, min): ");
estRuntime = 0.0424*(const.solar_maxi*const.BESS_maxi+const.upgrade_maxi)+(4.08e-07*(const.solar_maxi*const.BESS_maxi + const.upgrade_maxi).^2);
disp(estRuntime);
disp(estRuntime/60);


%% run simulation
tic


%idefity maximum NPV for solar-ESS and substation upgrade
[const, opt] = runOptimization(const, opt);


toc


%% graph data and return results
subplot(2,1,1);
hold on;
%surf(opt.solarCapacity, opt.BESSCapacity, opt.NPVSolarAndBESS./1000000, 'FaceAlpha', 0.5);
if const.solar_maxi > 1 && const.BESS_maxi > 1
mesh(opt.solarCapacity, opt.BESSCapacity, opt.NPVSolarAndBESS./1000000); %will need to add condition for corner cases here
end
plot3(opt.optSolar, opt.optBESS, opt.maxNPVBESS/1000000, 'rs', 'MarkerSize', 10);
%mesh(opt.solarCapacity, opt.BESSCapacity, zeros(size(opt.NPVSolarAndBESS)), 'FaceAlpha', 0.1); %plot zero NPV
%plot3(solarCapacity,zeros(solar_maxi,1),zeros(solar_maxi,1),'k--');
%plot3(zeros(BESS_maxi,1),BESSCapacity,zeros(BESS_maxi),'k--');
view(3);
ax = gca;
ax.FontSize = 13;
xlabel("Solar Capacity (MW)");
ylabel("BESS Capacity (MWh)");
zlabel("Million USD");
title("NPV for Solar and BESS");

subplot(2,1,2);
hold on;
plot(opt.substUpgrade, opt.NPVSubstUpgrade./1000000);
plot(opt.optUpgrade, opt.maxNPVUpgrade/1000000, 'rs','MarkerSize',10);
%plot(opt.substUpgrade, zeros(length(opt.NPVSubstUpgrade),1), 'k--');
ax = gca;
ax.FontSize = 13;
xlabel("Substation Upgrade (MW)");
ylabel("Million USD");
title("NPV for Substation Upgrade");

disp("optimal BESS capacity and Solar Capacity:");
disp(opt.optBESS);
disp(opt.optSolar);
disp("optimal substation upgrade:");
disp(opt.optUpgrade);

%DEMO finding maximum value and point
% [data.x,data.y] = meshgrid(-10:10,-10:10);
%disp(data.x);
%disp(data.y);
% data.z = -((data.x-2).^2 + (data.y-3).^2);
% mesh(data.x,data.y,data.z); %corner case, single data point or 1d vector will give error here
% [maxes,y_ar] = max(data.z);
% disp("y max index");
% disp(y_ar);
% [max,x_i] = max(maxes);
% disp("max");
% disp(max);
% disp("x max index");
% disp(x_i);
% disp("y max index");
% y_i = y_ar(x_i);
% disp(y_i);
% disp("max from indeces");
% disp(data.z(y_i,x_i));
% disp("x, y from indeces");
% disp(data.x(y_i,x_i));
% disp(data.y(y_i,x_i));
% xlabel("x axis");
% ylabel("y axis");


%% run simulation for best 2 cases
%display results from best 2 runs, display NPV optimization graphs

%get indecies in arrays for max values
runSolarBESS.solar_i = opt.optSolar_i;
runSolarBESS.BESS_i = opt.optBESS_i;
runUpgrade.upgrade_i = opt.optUpgrade_i;

%get size of solar and BESS
runSolarBESS.sizeSolar = opt.optSolar;
runSolarBESS.sizeBESS = opt.optBESS;
%get size of Upgrade
runUpgrade.sizeUpgrade = opt.optUpgrade;

%override inputs
%runSolarBESS.sizeSolar = 600;
%runSolarBESS.sizeBESS = 300;
%runUpgrade.sizeUpgrade = 60;
% const.isManualInput = 0; %to avoid errors if it is looking for manual cost data

%run simulation for optimal two cases
[runSolarBESS, runUpgrade] = runOptSimulation(const, runSolarBESS, runUpgrade);

%%graph results

%plotSolarBESSLoad(1,const.load,runSolarBESS.netLoadSolar,runSolarBESS.netLoadBESS,runSolarBESS.solarGen,runSolarBESS.powerOutBESS,1,'Yearly Net Loads and Solar, BESS Outputs');
%plotSolarBESSLoad(2,const.load,runSolarBESS.netLoadSolar,runSolarBESS.netLoadBESS,runSolarBESS.solarGen,runSolarBESS.powerOutBESS,0,'Net Loads and Solar, BESS Outputs');

%plotOverloads2(3,const.load,const.npCapacity,const.npOverloadsOrig,const.timeOverloadOrig,const.isDamagingOrig,0,'Baseline Overloads');
plotOverloads2(4,runSolarBESS.netLoadBESS,const.npCapacity,runSolarBESS.npOverloadsBESS,runSolarBESS.timeOverloadBESS,runSolarBESS.isDamagingBESS,0,'Overloads w/ Solar and BESS');
  
%plotBESSData(5,runSolarBESS.netLoadBESS,runSolarBESS.powerOutBESS,runSolarBESS.energyBESS,0,'Solar, BESS Outputs');

%plotCosts(6,runSolarBESS.annualCO2BESS,runUpgrade.annualCO2Upgrade,runSolarBESS.annualCB_BESS,runUpgrade.annualCB_Upgrade,'Annual Costs in C02','Annual Benefits-Costs in USD');
plotCosts(7,runSolarBESS.netCO2BESS,runUpgrade.netCO2Upgrade,runSolarBESS.NPV_BESS,runUpgrade.NPV_Upgrade,'Net Costs in C02','Net Present Value in USD');

figure(8);
%plot(diff(runSolarBESS.netLoadBESS));
subplot(2, 1, 1);
%plot(diff(runSolarBESS.netLoadBESS),'b:','LineWidth',2);
axis([4167 4188 -15 130]);
hold on;
%plot(diff(runSolarBESS.netLoadSolar),'r:','LineWidth',2);
plot(runSolarBESS.energyBESS,'o');
plot(runSolarBESS.powerOutBESS,'k');
plot(runSolarBESS.netLoadBESS,'g-');
plot(runSolarBESS.netLoadSolar, "r--");
legend('ESS energy','ESS power out','net load with ESS','net load with solar');
title('ESS Energy, Net-Load & Solar Net-Load');
ylabel('Power (MW), Energy (MWh)');

subplot(2, 1, 2);
plot(diff(runSolarBESS.netLoadBESS),'b:','LineWidth',1.5);
axis([4167 4188 -15 130]);
hold on;
plot(diff(runSolarBESS.netLoadSolar),'r:','LineWidth',1.5);
plot(diff(const.load),'k:','LineWidth',1.5');
legend('slope of ESS net load','slope of solar net load','slope of orig. load');
title('Slope of Net-Load Profiles');
ylabel('Change-in-Power (MW/h)');

disp("total energy output of solar and BESS");
disp(runSolarBESS.totEnergyGenSolar);
disp(runSolarBESS.totEnergyThruBESS);




