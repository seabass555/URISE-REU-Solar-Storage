function [runSolarBESS] = calcCosts2BESS_opt(const, runSolarBESS)
%calcCosts determines total CO2 emissions and costs in USD for solar+storage
%and substation upgeade. Determines costs annually and projects for 30 years NPV.
%intended to be called twice in main function, once to calculate for solar+BESS,
%the other for substation upgrade calculations.
%Also uses data from no infrastrucutre invetment whatsoever to extrapolate
%the gains made from reducing overloads.

%[runSolarBESS.netCO2BESS,runSolarBESS.annualCO2BESS,runSolarBESS.NPV_BESS,runSolarBESS.annualCB_BESS] = calcCosts2(const.energyLoad,runSolarBESS.energySolar,const.percLoadGrowth,const.percSolarDeg,runSolarBESS.sizeSolar,runSolarBESS.sizeBESS,const.npCapacity,0,runSolarBESS.durationOverloadBESS,runSolarBESS.isDamagingBESS,const.durationOverloadOrig,const.isDamagingOrig,const.priceCarbon,const.isBlackoutAtNP);
%do delete: substUpgradeMW
%INPUTS: const.energyLoad,runSolarBESS.energySolar,const.percLoadGrowth,const.percSolarDeg,runSolarBESS.sizeSolar,runSolarBESS.sizeBESS,const.npCapacity,runSolarBESS.durationOverloadBESS,runSolarBESS.isDamagingBESS,const.durationOverloadOrig,const.isDamagingOrig,const.priceCarbon,const.isBlackoutAtNP
%OUTPUTS: runSolarBESS.netCO2BESS,runSolarBESS.annualCO2BESS,runSolarBESS.NPV_BESS,runSolarBESS.annualCB_BESS


%% Calculate annual net energy consumption

%initalize array for annual demand (baseline load) and solar energy
annualEnergyDemand = zeros(const.projectLifetime,1);
annualEnergySolar = zeros(const.projectLifetime,1);

annualEnergyDemand(1) = const.energyLoad; %assign year 1 data
annualEnergySolar(1) = runSolarBESS.energySolar;

for i=2:const.projectLifetime %interate through years, adjust for load growth, solar deg.
    annualEnergyDemand(i)=annualEnergyDemand(i-1)*(1+const.percLoadGrowth/100);
    annualEnergySolar(i)=annualEnergySolar(i-1)*(1-const.percSolarDeg/100);
end

annualNetEnergy = annualEnergyDemand - annualEnergySolar; %determine net energy as vector
%correct annualNetEnergy if it's negative or zero (will have 1 MWh as minimum)
annualNetEnergy(annualNetEnergy < 1) = 1;


% disp("annual Net energy");
% disp(length(annualNetEnergy));
% disp(annualNetEnergy);

%% Emissions costs

%%%Determine annual emission reduction from the power generation of solar
annualLoadCO2 = -annualEnergySolar*const.emissionsPerMWh;


%initalize arrays for total CO2 emissions, determine maintaince/inst. costs
runSolarBESS.netCO2BESS = zeros(const.projectLifetime,1);
runSolarBESS.annualCO2BESS = zeros(const.projectLifetime,1);
%net costs is the sum of all previous years, while annual is for each year
annualMaintainceSolarCO2 = const.annualMaintaincePerMWSolarCO2*runSolarBESS.sizeSolar;
annualMaintainceBESSCO2 = const.annualMaintaincePerMWhStorageCO2*runSolarBESS.sizeBESS;
annualMaintainceSubstCO2 = const.annualMaintaincePerMWSubstCO2*const.npCapacity;
instCostSolarCO2 = const.instCostSolarPerMWCO2*runSolarBESS.sizeSolar;
instCostBESSCO2 = const.instCostStoragePerMWhCO2*runSolarBESS.sizeBESS;
%instCostSubstCO2 = const.instCostSubstPerMWCO2*substUpgradeMW;

%determine for year 1
runSolarBESS.netCO2BESS(1) = annualLoadCO2(1)+annualMaintainceSolarCO2+annualMaintainceBESSCO2+annualMaintainceSubstCO2+instCostSolarCO2+instCostBESSCO2; %+instCostSubstCO2;
runSolarBESS.annualCO2BESS(1) = runSolarBESS.netCO2BESS(1);

for i = 2:const.projectLifetime %iterate through years of calculation
    %determine annual CO2 for this year
    runSolarBESS.annualCO2BESS(i)=annualLoadCO2(i)+annualMaintainceSolarCO2+annualMaintainceBESSCO2+annualMaintainceSubstCO2;
    %determine if hardware replacement
    if mod(i,const.yearsPerHardwRep) == 0
        runSolarBESS.annualCO2BESS(i) = runSolarBESS.annualCO2BESS(i) + const.costHardwRepPerMWCO2*runSolarBESS.sizeSolar; %assume scales linearly w/ size of solar
    end
    %determine if battery replacement
    if mod(i,const.yearsPerBattRep) == 0
         runSolarBESS.annualCO2BESS(i) = runSolarBESS.annualCO2BESS(i) + instCostBESSCO2*0.2; %assume replacing batteries is same cost as installing BESS (20% batt. rep)
    end
    %sum up annual contributions (costCO2 is total emissions, i.e. sum over all years)
    runSolarBESS.netCO2BESS(i)=runSolarBESS.netCO2BESS(i-1)+runSolarBESS.annualCO2BESS(i);
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
    totalDurationOverloadOrig = sum(const.durationOverloadOrig.*const.isDamagingOrig,'omitnan'); %total hours of overloads in year 1
    costsBaselineOverloadsOrig = sum(const.isDamagingOrig,'omitnan')*const.costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloadsOrig(1) = totalDurationOverloadOrig*const.costPerHourOverloadUSD+costsBaselineOverloadsOrig;

    %determine overload costs for the remainder of the years using proportion to annual energy consuption
    costsOverloadsOrig = costsOverloadsOrig(1).*(annualEnergyDemand./annualEnergyDemand(1));
    
  %%%determine overload costs for current system (i.e. solar/storage or upgrade)
    %use total duration of damaging overloads along with a
    %baseline cost for each damaging overload that occurs
    totalDurationOverloads = sum(runSolarBESS.durationOverloadBESS.*runSolarBESS.isDamagingBESS,'omitnan'); %total hours of overloads in year 1
    costsBaselineOverloads = sum(runSolarBESS.isDamagingBESS,'omitnan')*const.costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloads(1) = totalDurationOverloads*const.costPerHourOverloadUSD+costsBaselineOverloads;

    %determine overload costs for the remainder of the years using proportion
    costsOverloads = costsOverloads(1).*(annualNetEnergy./annualNetEnergy(1));

else
%%%calculate overload costs assuming blackouts for any overload above np
    %assume all overloads contribute to cost (ignore isDamaging)
    totalDurationOverloadOrig = sum(const.durationOverloadOrig,'omitnan'); %total hours of overloads in year 1
    costsBaselineOverloadsOrig = length(const.durationOverloadOrig)*const.costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloadsOrig(1) = totalDurationOverloadOrig*const.costPerHourOverloadUSD+costsBaselineOverloadsOrig;

    %determine overload costs for the remainder of the years using proportion to annual energy consuption
    costsOverloadsOrig = costsOverloadsOrig(1).*(annualEnergyDemand./annualEnergyDemand(1));
    
  %%%determine overload costs for current system (i.e. solar/storage or upgrade)
    %use total duration of all overloads along with a baseline cost per overload
    totalDurationOverloads = sum(runSolarBESS.durationOverloadBESS,'omitnan'); %total hours of overloads in year 1
    costsBaselineOverloads = length(runSolarBESS.durationOverloadBESS)*const.costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloads(1) = totalDurationOverloads*const.costPerHourOverloadUSD+costsBaselineOverloads;

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
gainsSolarGen = annualEnergySolar*const.gainsPerMWhSolar;
gainsBESS = runSolarBESS.energyTotBESS*const.gainsPerMWhBESS;

%%%Determine annual gains from carbon pricing if used
%%%Assume carbon pricing is a gain provided for reducing emissions compared to original system
%initalize
gainsCarbonCredit = zeros(const.projectLifetime,1);
if const.priceCarbon ~= 0
    gainsCarbonCredit = -const.priceCarbon.*runSolarBESS.annualCO2BESS; %"negative" emissions means positive gains
end
%DEBUG
%disp("Annual gains from carbon pricing");
%disp(gainsCarbonCredit);



%%%determine instalation costs/upgrade costs/annual maintaince costs for
%%%this system.
if runSolarBESS.sizeSolar > 0
    instCostSolarUSD = const.instCostSolarPerMWUSD*runSolarBESS.sizeSolar + 2.77E6;
    annualMaintainceSolarUSD = const.annualMaintaincePerMWSolarUSD*runSolarBESS.sizeSolar;
else
    instCostSolarUSD = 0;
    annualMaintainceSolarUSD = 0;
end
if runSolarBESS.sizeBESS > 0
    instCostBESSUSD = const.instCostStoragePerMWhUSD*runSolarBESS.sizeBESS + 1.75E7;
    annualMaintainceBESSUSD = const.annualMaintaincePerMWhStorageUSD*runSolarBESS.sizeBESS;
    instCostStoragePerMWhUSD_run = const.instCostStoragePerMWhUSD;
    costHardwRepUSD_run = const.costHardwRepUSD;
else
    instCostBESSUSD = 0;
    annualMaintainceBESSUSD = 0;
    costHardwRepUSD_run = 0; %set hardware rep. costs for BESS/solar to be zero. Assume if no BESS, then there's no solar
    instCostStoragePerMWhUSD_run = 0; %set to zero, since used later to determine battery rep. costs
end
% if substUpgradeMW > 0
%     %arbirary inst. cost function for now
%     instCostUpgradeUSD = instCostSubstPerMWUSD*(0.5*substUpgradeMW+const.npCapacity);
% else
%     instCostUpgradeUSD = 0;
% end
annualMaintainceSubstUSD=const.annualMaintaincePerMWSubstUSD*const.npCapacity; %not in if statement, since solar/BESS still has it

%%%%%start calculating annual net costs-benefits
%initalize
runSolarBESS.annualCB_BESS = zeros(const.projectLifetime,1);


%determine upfront costs
upfrontCost = instCostSolarUSD+instCostBESSUSD; %+instCostUpgradeUSD;
%determine total costs after year 1
runSolarBESS.annualCB_BESS(1) = gainsBESS+gainsSolarGen(1)+gainsOverloads(1)+gainsCarbonCredit(1)-(annualMaintainceSolarUSD+annualMaintainceBESSUSD+annualMaintainceSubstUSD);

%run through all years
for i = 2:const.projectLifetime
    %maintaince costs+overload costs
    runSolarBESS.annualCB_BESS(i) = gainsBESS+gainsSolarGen(i)+gainsOverloads(i)+gainsCarbonCredit(i)-(annualMaintainceSolarUSD+annualMaintainceBESSUSD+annualMaintainceSubstUSD);
    %check for hardware upgrade
    if mod(i,const.yearsPerHardwRep) == 0
        runSolarBESS.annualCB_BESS(i) = runSolarBESS.annualCB_BESS(i) - costHardwRepUSD_run; %add fixed cost for replacing hardware
    end
    %determine if battery replacement
    if mod(i,const.yearsPerBattRep) == 0
         runSolarBESS.annualCB_BESS(i) = runSolarBESS.annualCB_BESS(i) - (instCostStoragePerMWhUSD_run*runSolarBESS.sizeBESS).*0.2; %use slope of BESS cost function w/out its y-intercept, assumes 20% battery rep.
    end
end

%determine NPV from annual cost-benefits, interest rate, and upfront costs
runSolarBESS.NPV_BESS = zeros(const.projectLifetime,1);

%Use nested for loop to determine NPV up to year i in [1,const.projectLifetime], with sum of annual
%costs for years t in [1,i] accounting for interest rate
for i = 1:const.projectLifetime
    runSolarBESS.NPV_BESS(i) = -upfrontCost; %start by adding upfront cost (negative)
    for t = 1:i
        %apply geometric series
        runSolarBESS.NPV_BESS(i) = runSolarBESS.NPV_BESS(i) + runSolarBESS.annualCB_BESS(t)/((1+const.r).^t);
    end
end

%after determining NPV, add the upfront costs to the annual benefits-costs
runSolarBESS.annualCB_BESS(1) = runSolarBESS.annualCB_BESS(1) - upfrontCost;


end
