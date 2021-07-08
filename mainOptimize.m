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
const.deltaTime = 1; % time increment IN HOURS

%BESS variables
const.initialEnergyBESS = 0; % MWh initial capacity
const.chargePowerCap = 15; %MW BESS charge Power Cap
const.dischargePowerCap = 15; %MW BESS discharge Power Cap
%--For percent of load based charge-discharge algorithm:
const.chargePerc = 110; %percentage of mean load to charge
const.dischargePerc = 110; %percentage of mean load to discharge
const.dischargeFactor = 90; %percentage for how much to bring down load to discharge threshold (0=none, 100=flat)

%substation overload variables
const.npCapacity = 90; %MW - nameplate rating of the substation transformer
%adjustmentFactorMax = 25; %percent maximum tolerable increase above substation rating
%adjustmentFactor = 0.4; %percent tolerable increase above rating for every percent the 24hr mean capacity factor is below 100%

%%%%
%%costs/optimization parameters
%%%%
const.percLoadGrowth = 5;
const.percSolarDeg = 0.6;
const.priceCarbon = 51; %CO2 price per Ton (will have option to select use)
const.isBlackoutAtNP = 1; %option to allow user to have limited overloads
const.projectLifetime = 30; %years that the solar and BESS system will be used

%most of the following values are currently arbitrary
%instalation costs (USD, C02)
const.instCostSolarPerMWUSD = 994135;%Cost = 994135*capacity+2.77E6 USD costs per MW for solar instalation
const.instCostStoragePerMWhUSD = 267678;%Cost = 267678*capacity+1.75E7 USD costs per MWh for BESS instalation
const.instCostSubstPerMWUSD = 120000; %USD costs per MW for substation upgrade
const.instCostSolarPerMWCO2 = 3.97; %tons of CO2 costs per MW for solar instalation
const.instCostStoragePerMWhCO2 = 8.69; %tons of CO2 costs per MWh for BESS instalation
const.instCostSubstPerMWCO2 = 42.0; %tons of CO2 costs per MW for substation upgrade

%annual maintaince costs (USD, C02)
const.annualMaintaincePerMWSolarUSD = 17460; %From NREL cost benchmark for kWdc of solar *1000, annual USD costs per MW of solar for maintaince
const.annualMaintaincePerMWhStorageUSD = 1000; %annual USD costs per MW of BESS for maintaince
const.annualMaintaincePerMWSubstUSD = 20000; %annual USD costs per MW of substation for maintaince
const.annualMaintaincePerMWSolarCO2 = 15; %annual co2 costs per MW of solar for maintaince
const.annualMaintaincePerMWhStorageCO2 = 15; %annual co2 costs per MW of BESS for maintaince
const.annualMaintaincePerMWSubstCO2 = 20; %annual co2 costs per MW of substation for maintaince

%power electronics replacement costs for solar and storage (CO2, USD)
%costHardwRepUSD = 10.135E6; %Uses mean cost of BESS function and solar function with capacity=0, USD costs for upgrading electronics for solar-storage
const.costHardwRepUSD = 7.4E6/100; %Used NREL cost benchmark for 100MW-240MWh solar+BESS instalation, divided by 100
const.costHardwRepPerMWCO2 = 3; %tons of CO2 costs for upgrade
const.yearsPerHardwRep = 10; %numbers of years until replacement of electronics is needed
%ALSO replacing batteries--future note: could add an additional input param. for battery
%type and have if-statements to select variables for time to replace, cost
const.yearsPerBattRep = 10;

%tons of CO2 emissions due to generation of electricity that's non-solar
%emissionsPerMWh = 0.5; %EPA regulation for natural gas emission standards
const.emissionsPerMWh = 0.1996; %EIA emission data for natural gas, converted from lb-CO2/Mbtu

%Overload costs
%costPerMWhOverloadUSD = 100+36.66+250; %Costs per MWh overload non-tolerable by substation (USD). Arbitrary, now unused
const.costPerHourOverloadUSD = 5000; %Currently arbitrary, cost for every hour a non-tolerable overload occurs
const.costBaselinePerOverloadUSD = 1000; %currently arbitrary, baseline cost of a damaging overload

%peak and off peak costs of energy generation (conventional power plant)
const.peakGenCostPerMWh = 36.66*1.2; %arbitrary
const.offPeakGenCostPerMWh = 36.66*0.75; %arbitrary

const.r = 0.03; %3 percent interest rate

%for later use: also could have option for certain benefits of storage,
%such as selling power during peak




%check for errors, display input data as load and 1MW solar
%potential errors: data entered wrong, or as NaN, constants set to wrong
%values that may cause errors.

%% initalize "opt." from inputs

%demo input data
solarCapMin = 0;
solarCapMax = 100;
BESSCapMin = 0;
BESSCapMax = 200;
upgradeMin = 0;
upgradeMax = 100;

deltaSolarCap = 1; %10MW difference
deltaBESSCap = 1; %10MWh difference between cases
deltaUpgrade = 1; %difference of 1MW between subst. upgrade cases

%compute arrays: (alternatively, could replace with linspace, and have a
%total number of test cases specified)
%will also need to add a condition in the case that the user manually
%enteres the cases
solarCapacity = solarCapMin:deltaSolarCap:solarCapMax;
BESSCapacity = BESSCapMin:deltaBESSCap:BESSCapMax;
solar_maxi = length(solarCapacity);
BESS_maxi = length(BESSCapacity);

opt.substUpgrade = upgradeMin:deltaUpgrade:upgradeMax;
upgrade_maxi = length(opt.substUpgrade);

%compute matricies for solar and BESS
%assume solar as x-axis, BESS and y-axis
[opt.solarCapacity, opt.BESSCapacity] = meshgrid(solarCapacity, BESSCapacity);

%initalize the arrays for NPV result from solar and BESS, subst. upgrade
opt.NPVSolarAndBESS = zeros(BESS_maxi,solar_maxi);
opt.NPVSubstUpgrade = zeros(upgrade_maxi,1);

disp("size of solar-BESS matrix");
disp(size(opt.NPVSolarAndBESS));
disp("size of substation upgrade array");
disp(length(opt.NPVSubstUpgrade));

%display estimated runtime...
disp("estimated runtime (sec): ");
estRuntime = 0.0417*(solar_maxi*BESS_maxi + upgrade_maxi);
disp(estRuntime);

tic

%% run simulation
%pre-calculate anything that only needs to run once
%total energy demand for year 1:
const.energyLoad = sum(const.load,'omitnan')*1; %hour increments

%overloads at original (nameplate capacity with no solar+BESS)
[const] = calcOverloadsOrig_opt(const);
%INPUTS: const.load, const.npCapacity, const.time
%OUTPUTS: const.npOverloadsOrig,const.durationOverloadOrig,const.intensityOverloadOrig,const.timeOverloadOrig,const.isDamagingOrig

%revenue from solar MWh of generation and BESS load shifting
const.gainsPerMWhSolar = (const.peakGenCostPerMWh + const.offPeakGenCostPerMWh)/2; %average peak/off peak generation cost
const.gainsPerMWhBESS = const.peakGenCostPerMWh - const.offPeakGenCostPerMWh;      %assume BESS discharges during peak time, use difference between on and off peak cost of generation


% -calculate 30 year NPV for each run, store in opt. , use for loop
%run simulation for solar+BESS, store variables in runSolarBESS.
for solar_i = 1:solar_maxi
    %calculate solar variables, energy, etc.
    runSolarBESS.sizeSolar = opt.solarCapacity(1,solar_i); %determine size of solar array for the upcoming runs
    
    %determine the net load with solar and energy generated by solar
    [runSolarBESS] = calcLoadWithSolar_opt(const, runSolarBESS);
    %inputs: const.load, const.solarGen1MW, runSolarBESS.sizeSolar
    %outputs: runSolarBESS.netLoadSolar,runSolarBESS.solarGen,runSolarBESS.energySolar,runSolarBESS.percSolarPen
    
    for BESS_i = 1:BESS_maxi
        %iterate through runs with the same solar capacity but varying BESS
        runSolarBESS.sizeBESS = opt.BESSCapacity(BESS_i,1); %determine size of BESS for this run
        
        %determine energy and power output, net load with BESS
        %for future - add condition for different BESS algorithms
        [runSolarBESS] = BESSFunc2S_opt(const, runSolarBESS);
        %INPUTS: const.time,const.deltaTime,runSolarBESS.netLoadSolar,const.initialEnergyBESS,runSolarBESS.sizeBESS,const.chargePowerCap,const.dischargePowerCap,const.chargePerc,const.dischargePerc,const.dischargeFactor, const.npCapacity
        %OUTPUTS: runSolarBESS.powerOutBESS,runSolarBESS.energyBESS,runSolarBESS.energyTotBESS,runSolarBESS.netLoadBESS
        
        %determine overloads for the given run
        [runSolarBESS] = calcOverloadsBESS_opt(const, runSolarBESS);
        %INPUTS: runSolarBESS.netLoadBESS, const.npCapacity, const.time
        %OUTPUTS: runSolarBESS.npOverloadsBESS,runSolarBESS.durationOverloadBESS,runSolarBESS.intensityOverloadBESS,runSolarBESS.timeOverloadBESS,runSolarBESS.isDamagingBESS
    
        %calculate NPV for the given run at the lifetime of the system
        [runSolarBESS] = calcCosts2BESS_opt(const, runSolarBESS);
        %INPUTS: const.energyLoad,runSolarBESS.energySolar,runSolarBESS.energyTotBESS,const.percLoadGrowth,const.percSolarDeg,runSolarBESS.sizeSolar,runSolarBESS.sizeBESS,const.npCapacity,runSolarBESS.durationOverloadBESS,runSolarBESS.isDamagingBESS,const.durationOverloadOrig,const.isDamagingOrig,const.priceCarbon,const.isBlackoutAtNP
        %OUTPUTS: runSolarBESS.netCO2BESS,runSolarBESS.annualCO2BESS,runSolarBESS.NPV_BESS,runSolarBESS.annualCB_BESS
        
        %assign NPV to current position in NPV results matrix
        opt.NPVSolarAndBESS(BESS_i,solar_i) = runSolarBESS.NPV_BESS(end);
        
    end
end

for upgrade_i = 1:upgrade_maxi
    %run simulation for substation upgrade, store vars in runUpgrade.
    %omit BESS+Solar calculations for these
    runUpgrade.sizeUpgrade = opt.substUpgrade(upgrade_i);
    
    %determine overloads for this run
    [runUpgrade] = calcOverloadsUpgrade_opt(const, runUpgrade);
    %INPUTS: const.load, const.npCapacity, runUpgrade.sizeUpgrade, const.time
    %OUTPUTS: runUpgrade.npOverloadsUpgrade,runUpgrade.durationOverloadUpgrade,runUpgrade.intensityOverloadUpgrade,runUpgrade.timeOverloadUpgrade,runUpgrade.isDamagingUpgrade
    
    %calculate NPV after system lifetime for the subst. upgrade
    [runUpgrade] = calcCosts2Upgrade_opt(const, runUpgrade);
    %INPUTS: const.energyLoad,runSolarBESS.energySolar,const.percLoadGrowth,const.percSolarDeg,runSolarBESS.sizeSolar,runSolarBESS.sizeBESS,const.npCapacity,runUpgrade.durationOverloadUpgrade,runUpgrade.isDamagingUpgrade,const.durationOverloadOrig,const.isDamagingOrig,const.priceCarbon,const.isBlackoutAtNP
    %OUTPUTS: runUpgrade.netCO2Upgrade,runUpgrade.annualCO2Upgrade,runUpgrade.NPV_Upgrade,runUpgrade.annualCB_Upgrade
    
    %assign current NPV
    opt.NPVSubstUpgrade(upgrade_i) = runUpgrade.NPV_Upgrade(end);
end

    %note: may be able to improve program in a few ways
    %omit BESS+Solar function from substation upgrade calculations
    %calculate all status-quo costs prior to for loop (e.g. in calcCosts,
    %overloads, total energy, etc.)
    %remove calculation of any unused variables, such as adjustedOverloads
% -identify maximum NPV
% -idenfity the best case substation upgrade, solar & BESS capacity


%DEMO run - arbitrary NPV
% opt.NPVSolarAndBESS = -((opt.solarCapacity-60).^2 + opt.BESSCapacity.^2);
%opt.NPVSubstUpgrade = 10 - opt.substUpgrade.^2;

%calculate maximum NPV
[opt] = calcMaxNPV(opt);

toc

%graph data and return results
subplot(2,1,1);
mesh(opt.solarCapacity, opt.BESSCapacity, opt.NPVSolarAndBESS); %will need to add condition for corner cases here
xlabel("solar capacity (MW)");
ylabel("BESS capacity (MWh)");
zlabel("NPV");

subplot(2,1,2);
plot(opt.substUpgrade, opt.NPVSubstUpgrade);
xlabel("substation upgrade (MW)");
ylabel("NPV");

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

%get size of solar and BESS
runSolarBESS.sizeSolar = opt.optSolar;
runSolarBESS.sizeBESS = opt.optBESS;

%run load with solar function
[runSolarBESS] = calcLoadWithSolar_opt(const, runSolarBESS);
%Run BESS function
[runSolarBESS] = BESSFunc2S_opt(const, runSolarBESS);
%calculate overloads for solar-BESS
[runSolarBESS] = calcOverloadsBESS_opt(const, runSolarBESS);
%run cost calculation for solar-BESS
[runSolarBESS] = calcCosts2BESS_opt(const, runSolarBESS);

%get size of Upgrade
runUpgrade.sizeUpgrade = opt.optUpgrade;

%determine overloads
[runUpgrade] = calcOverloadsUpgrade_opt(const, runUpgrade);
%determine costs
[runUpgrade] = calcCosts2Upgrade_opt(const, runUpgrade);

%%graph results

% plotSolarBESSLoad(1,const.load,runSolarBESS.netLoadSolar,runSolarBESS.netLoadBESS,runSolarBESS.solarGen,runSolarBESS.powerOutBESS,1,'Yearly Net Loads and Solar, BESS Outputs');
% plotSolarBESSLoad(2,const.load,runSolarBESS.netLoadSolar,runSolarBESS.netLoadBESS,runSolarBESS.solarGen,runSolarBESS.powerOutBESS,0,'Net Loads and Solar, BESS Outputs');
% 
% plotOverloads2(3,const.load,const.npCapacity,const.npOverloadsOrig,const.timeOverloadOrig,const.isDamagingOrig,0,'Baseline Overloads');
% plotOverloads2(4,runSolarBESS.netLoadBESS,const.npCapacity,runSolarBESS.npOverloadsBESS,runSolarBESS.timeOverloadBESS,runSolarBESS.isDamagingBESS,0,'Overloads w/ Solar and BESS');
%   
% plotBESSData(5,runSolarBESS.netLoadBESS,runSolarBESS.powerOutBESS,runSolarBESS.energyBESS,0,'Solar, BESS Outputs');
% 
% plotCosts(6,runSolarBESS.annualCO2BESS,runUpgrade.annualCO2Upgrade,runSolarBESS.annualCB_BESS,runUpgrade.annualCB_Upgrade,'Annual Costs in C02','Annual Benefits-Costs in USD');
% plotCosts(7,runSolarBESS.netCO2BESS,runUpgrade.netCO2Upgrade,runSolarBESS.NPV_BESS,runUpgrade.NPV_Upgrade,'Net Costs in C02','Net Present Value in USD');







