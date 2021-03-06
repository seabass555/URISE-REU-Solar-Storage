function [runUpgrade] = calcCosts2Upgrade_opt(const, runUpgrade)
%calcCosts determines total CO2 emissions and costs in USD for solar+storage
%and substation upgeade. Determines costs annually and projects for 30 years NPV.
%intended to be called twice in main function, once to calculate for solar+BESS,
%the other for substation upgrade calculations.
%Also uses data from no infrastrucutre invetment whatsoever to extrapolate
%the gains made from reducing overloads.

%INPUTS: const.energyLoad,runSolarBESS.energySolar,const.percLoadGrowth,const.percSolarDeg,runSolarBESS.sizeSolar,runSolarBESS.sizeBESS,const.npCapacity,runUpgrade.durationOverloadUpgrade,runUpgrade.isDamagingUpgrade,const.durationOverloadOrig,const.isDamagingOrig,const.priceCarbon,const.isBlackoutAtNP
%OUTPUTS: runUpgrade.netCO2Upgrade,runUpgrade.annualCO2Upgrade,runUpgrade.NPV_Upgrade,runUpgrade.annualCB_Upgrade


%% Calculate annual net energy consumption

%initalize array for annual demand (baseline load) and solar energy
annualEnergyDemand = zeros(const.projectLifetime,1);
%annualEnergySolar = zeros(const.projectLifetime,1);

annualEnergyDemand(1) = const.energyLoad; %assign year 1 data
%annualEnergySolar(1) = runSolarBESS.energySolar;

for i=2:const.projectLifetime %interate through years, adjust for load growth, solar deg.
    annualEnergyDemand(i)=annualEnergyDemand(i-1)*(1+const.percLoadGrowth/100);
    %annualEnergySolar(i)=annualEnergySolar(i-1)*(1-const.percSolarDeg/100);
end

annualNetEnergy = annualEnergyDemand; %- annualEnergySolar; %determine net energy as vector

% disp("annual Net energy");
% disp(length(annualNetEnergy));
% disp(annualNetEnergy);

%% Emissions costs

%%%Determine annual emission reduction from the power generation of solar
%annualLoadCO2 = zeros(const.projectLifetime,1);
%annualLoadCO2 =-annualEnergySolar*const.emissionsPerMWh;


%initalize arrays for total CO2 emissions, determine maintaince/inst. costs
runUpgrade.netCO2Upgrade = zeros(const.projectLifetime,1);
runUpgrade.annualCO2Upgrade = zeros(const.projectLifetime,1);
%net costs is the sum of all previous years, while annual is for each year
%annualMaintainceSolarCO2 = const.annualMaintaincePerMWSolarCO2*runSolarBESS.sizeSolar;
%annualMaintainceBESSCO2 = const.annualMaintaincePerMWhStorageCO2*runSolarBESS.sizeBESS;
annualOMSubstCO2 = const.annualOMPerMWSubstCO2*(const.npCapacity+runUpgrade.sizeUpgrade);
%instCostSolarCO2 = const.instCostSolarPerMWCO2*runSolarBESS.sizeSolar;
%instCostBESSCO2 = const.instCostStoragePerMWhCO2*runSolarBESS.sizeBESS;
instCostSubstCO2 = const.instCostSubstPerMWCO2*runUpgrade.sizeUpgrade;

%determine for year 1
runUpgrade.netCO2Upgrade(1) = annualOMSubstCO2+instCostSubstCO2; %annualLoadCO2(1)+annualOMSolarCO2+annualOMBESSCO2+instCostSolarCO2+instCostBESSCO2;
runUpgrade.annualCO2Upgrade(1) = runUpgrade.netCO2Upgrade(1);

for i = 2:const.projectLifetime %iterate through years of calculation
    %determine annual CO2 for this year
    runUpgrade.annualCO2Upgrade(i)=annualOMSubstCO2;
    %determine if hardware replacement
%     if mod(i,const.yearsPerHardwRep) == 0
%         runUpgrade.annualCO2Upgrade(i) = runUpgrade.annualCO2Upgrade(i) + const.costHardwRepPerMWCO2*runSolarBESS.sizeSolar; %assume scales linearly w/ size of solar
%     end
%     %determine if battery replacement
%     if mod(i,const.yearsPerBattRep) == 0
%          runUpgrade.annualCO2Upgrade(i) = runUpgrade.annualCO2Upgrade(i) + instCostBESSCO2*0.2; %assume replacing batteries is same cost as installing BESS (20% batt. rep)
%     end
    %sum up annual contributions (costCO2 is total emissions, i.e. sum over all years)
    runUpgrade.netCO2Upgrade(i)=runUpgrade.netCO2Upgrade(i-1)+runUpgrade.annualCO2Upgrade(i);
end

%% USD costs
%%%first determine overload cost for original grid system
%%%solar/storage or upgrade will have NPV benefits compared to original
%initalize
costsOverloadsOrig = zeros(const.projectLifetime,1); %will be cost w/ status quo
costsOverloads = zeros(const.projectLifetime,1); %cost for proposed system

if const.isBlackoutAtNP == 0 %in this case, allow limited overloads 
    %use total duration of damaging overloads along with a
    %baseline cost for each damaging overload that occurs
    %Old method
    %%totalDurationOverloadOrig = sum(const.durationOverloadOrig.*const.isDamagingOrig,'omitnan'); %total hours of overloads in year 1
    costsEnergyOverloadsOrig = const.costPerMWhOverloadUSD*const.energyDamagingOverloadOrig;
    costsBaselineOverloadsOrig = sum(const.isDamagingOrig,'omitnan')*const.costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloadsOrig(1) = costsEnergyOverloadsOrig+costsBaselineOverloadsOrig;

    %determine overload costs for the remainder of the years using proportion to annual energy consuption
    costsOverloadsOrig = costsOverloadsOrig(1).*(annualEnergyDemand./annualEnergyDemand(1));
    
  %%%determine overload costs for current system (i.e. solar/storage or upgrade)
    %use total duration of damaging overloads along with a
    %baseline cost for each damaging overload that occurs
    %Old method
    %%totalDurationOverloads = sum(runUpgrade.durationOverloadUpgrade.*runUpgrade.isDamagingUpgrade,'omitnan'); %total hours of overloads in year 1
    costsEnergyOverloads = const.costPerMWhOverloadUSD*runUpgrade.energyDamagingOverload;
    costsBaselineOverloads = sum(runUpgrade.isDamagingUpgrade,'omitnan')*const.costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloads(1) = costsEnergyOverloads+costsBaselineOverloads;

    %determine overload costs for the remainder of the years using proportion
    costsOverloads = costsOverloads(1).*(annualNetEnergy./annualNetEnergy(1));

else
%%%calculate overload costs assuming blackouts for any overload above np
    %assume all overloads contribute to cost (ignore isDamaging)
    %Old method
    %%totalDurationOverloadOrig = sum(const.durationOverloadOrig,'omitnan'); %total hours of overloads in year 1
    costsEnergyOverloadsOrig = const.costPerMWhOverloadUSD*const.energyNPOverloadOrig;
    costsBaselineOverloadsOrig = length(const.durationOverloadOrig)*const.costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloadsOrig(1) = costsEnergyOverloadsOrig+costsBaselineOverloadsOrig;

    %determine overload costs for the remainder of the years using proportion to annual energy consuption
    costsOverloadsOrig = costsOverloadsOrig(1).*(annualEnergyDemand./annualEnergyDemand(1));
    
  %%%determine overload costs for current system (i.e. solar/storage or upgrade)
    %use total duration of all overloads along with a baseline cost per overload
    %Old method
    %%totalDurationOverloads = sum(runUpgrade.durationOverloadUpgrade,'omitnan'); %total hours of overloads in year 1
    costsEnergyOverloads = const.costPerMWhOverloadUSD*runUpgrade.energyNPOverload;
    costsBaselineOverloads = length(runUpgrade.durationOverloadUpgrade)*const.costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloads(1) = costsEnergyOverloads+costsBaselineOverloads;

    %determine overload costs for the remainder of the years using proportion
    costsOverloads = costsOverloads(1).*(annualNetEnergy./annualNetEnergy(1));
end
%determine the net costs caused by overloads -- i.e. the gain benefits (ideally gains) of
%improving the system to prevent overloads.
gainsOverloads = costsOverloadsOrig - costsOverloads; %will be positive (i.e. good for NPV)

%DEBUG
%disp("Annual gains from preventing overloads");
%disp(gainsOverloads);

%%%determine annual gains from solar generation and BESS load shifting
% gainsSolarGen = annualEnergySolar*const.gainsPerMWhSolar;
% gainsBESS = runSolarBESS.energyTotBESS*const.gainsPerMWhBESS;

%%%Determine annual gains from carbon pricing if used
%%%Assume carbon pricing is a gain provided for reducing emissions compared to original system
%initalize
gainsCarbonCredit = zeros(const.projectLifetime,1);
if const.priceCarbon ~= 0
    gainsCarbonCredit = -const.priceCarbon.*runUpgrade.annualCO2Upgrade; %"negative" emissions means positive gains
end
%DEBUG
%disp("Annual gains from carbon pricing");
%disp(gainsCarbonCredit);

%determine costs for ramping up/down load too qucikly
slopeLoad = diff(const.load);
costRamping = 0;
for i = 1:length(slopeLoad)
    if slopeLoad(i) > const.posLoadChangeLim || slopeLoad(i) < const.negLoadChangeLim
        costRamping = costRamping + abs(slopeLoad(i))*const.rampCostPerMWDiff;
    end
end
%compare costs of ramping to costs in original
costRamping = costRamping - const.costRampingOrig; %if original ramping is worse, the cost goes negative and becomes a benefit

%%%determine instalation costs/upgrade costs/annual maintaince costs for
%%%this system.
% if runSolarBESS.sizeSolar > 0
%     instCostSolarUSD = const.instCostSolarPerMWUSD*runSolarBESS.sizeSolar + 2.77E6;
%     annualMaintainceSolarUSD = const.annualMaintaincePerMWSolarUSD*runSolarBESS.sizeSolar;
% else
%     instCostSolarUSD = 0;
%     annualMaintainceSolarUSD = 0;
% end
% if runSolarBESS.sizeBESS > 0
%     instCostBESSUSD = const.instCostStoragePerMWhUSD*runSolarBESS.sizeBESS + 1.75E7;
%     annualMaintainceBESSUSD = const.annualMaintaincePerMWhStorageUSD*runSolarBESS.sizeBESS;
%     instCostStoragePerMWhUSD_run = const.instCostStoragePerMWhUSD;
%     costHardwRepUSD_run = const.costHardwRepUSD;
% else
%     instCostBESSUSD = 0;
%     annualMaintainceBESSUSD = 0;
%     costHardwRepUSD_run = 0; %set hardware rep. costs for BESS/solar to be zero. Assume if no BESS, then there's no solar
%     instCostStoragePerMWhUSD_run = 0; %set to zero, since used later to determine battery rep. costs
% end
if runUpgrade.sizeUpgrade > 0
    %arbirary inst. cost function for now
    instCostUpgradeUSD = const.instCostSubstPerMWUSD*(runUpgrade.sizeUpgrade+const.npCapacity);
else
    instCostUpgradeUSD = 0;
end
annualOMSubstUSD=const.annualOMPerMWSubstUSD*(const.npCapacity+runUpgrade.sizeUpgrade); %not in if statement, since solar/BESS still has it

%check if costs were entered manually, and if so, use those instead
if const.isManualInput == 1
    if ~isnan(const.manualSubstInstUSD(runUpgrade.upgrade_i))
        instCostUpgradeUSD = const.manualSubstInstUSD(runUpgrade.upgrade_i);
    end
    if ~isnan(const.manualSubstOMUSD(runUpgrade.upgrade_i))
        annualOMSubstUSD = const.manualSubstOMUSD(runUpgrade.upgrade_i);
    end
end



%%%%%start calculating annual net costs-benefits
%initalize
runUpgrade.annualCB_Upgrade = zeros(const.projectLifetime,1);


%determine upfront costs
upfrontCost = instCostUpgradeUSD;
%determine total costs after year 1
runUpgrade.annualCB_Upgrade(1) = gainsOverloads(1)+gainsCarbonCredit(1)-(annualOMSubstUSD+costRamping);

%run through all years
for i = 2:const.projectLifetime
    %maintaince costs+overload costs
    runUpgrade.annualCB_Upgrade(i) = gainsOverloads(i)+gainsCarbonCredit(i)-(annualOMSubstUSD+costRamping);
    %check for hardware upgrade
%     if mod(i,const.yearsPerHardwRep) == 0
%         runUpgrade.annualCB_Upgrade(i) = runUpgrade.annualCB_Upgrade(i) - costHardwRepUSD_run; %add fixed cost for replacing hardware
%     end
%     %determine if battery replacement
%     if mod(i,const.yearsPerBattRep) == 0
%          runUpgrade.annualCB_Upgrade(i) = runUpgrade.annualCB_Upgrade(i) - (instCostStoragePerMWhUSD_run*runSolarBESS.sizeBESS).*0.2; %use slope of BESS cost function w/out its y-intercept, assumes 20% battery rep.
%     end
end

%determine NPV from annual cost-benefits, interest rate, and upfront costs
runUpgrade.NPV_Upgrade = zeros(const.projectLifetime,1);

%Use nested for loop to determine NPV up to year i in [1,const.projectLifetime], with sum of annual
%costs for years t in [1,i] accounting for interest rate
for i = 1:const.projectLifetime
    runUpgrade.NPV_Upgrade(i) = -upfrontCost; %start by adding upfront cost (negative)
    for t = 1:i
        %apply geometric series
        runUpgrade.NPV_Upgrade(i) = runUpgrade.NPV_Upgrade(i) + runUpgrade.annualCB_Upgrade(t)/((1+const.r).^t);
    end
end

%after determining NPV, add the upfront costs to the annual benefits-costs
runUpgrade.annualCB_Upgrade(1) = runUpgrade.annualCB_Upgrade(1) - upfrontCost;


end

