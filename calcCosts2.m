function [netCostsCO2, annualCostsCO2, NPV_USD, annualCostBenefitUSD] = calcCosts2(energyLoad,energySolar,percLoadGrowth,percSolarDeg,sizeSolarMW,sizeBESSMWh,substRatingMW,substUpgradeMW,durationOverloads,isDamaging,durationOverloadsOrig,isDamagingOrig,priceCarbon,isBlackoutAtNP)
%calcCosts determines total CO2 emissions and costs in USD for solar+storage
%and substation upgeade. Determines costs annually and projects for 30 years NPV.
%intended to be called twice in main function, once to calculate for solar+BESS,
%the other for substation upgrade calculations.
%Also uses data from no infrastrucutre invetment whatsoever to extrapolate
%the gains made from reducing overloads.
%% variable definitions
%**most values are currently arbitrary
%instalation costs (USD, C02)
instCostSolarPerMWUSD = 994135;%Cost = 994135*capacity+2.77E6 USD costs per MW for solar instalation
instCostStoragePerMWhUSD = 267678;%Cost = 267678*capacity+1.75E7 USD costs per MWh for BESS instalation
instCostSubstPerMWUSD = 60000; %USD costs per MW for substation upgrade
instCostSolarPerMWCO2 = 3.97; %tons of CO2 costs per MW for solar instalation
instCostStoragePerMWhCO2 = 8.69; %tons of CO2 costs per MWh for BESS instalation
instCostSubstPerMWCO2 = 42.0; %tons of CO2 costs per MW for substation upgrade

%annual maintaince costs (USD, C02)
annualMaintaincePerMWSolarUSD = 17460; %From NREL cost benchmark for kWdc of solar *1000, annual USD costs per MW of solar for maintaince
annualMaintaincePerMWhStorageUSD = 1000; %annual USD costs per MW of BESS for maintaince
annualMaintaincePerMWSubstUSD = 10000; %annual USD costs per MW of substation for maintaince
annualMaintaincePerMWSolarCO2 = 15; %annual co2 costs per MW of solar for maintaince
annualMaintaincePerMWhStorageCO2 = 15; %annual co2 costs per MW of BESS for maintaince
annualMaintaincePerMWSubstCO2 = 20; %annual co2 costs per MW of substation for maintaince


%power electronics replacement costs for solar and storage (CO2, USD)
%costHardwRepUSD = 10.135E6; %Uses mean cost of BESS function and solar function with capacity=0, USD costs for upgrading electronics for solar-storage
costHardwRepUSD = 7.4E6/100; %Used NREL cost benchmark for 100MW-240MWh solar+BESS instalation, divided by 100
costHardwRepPerMWCO2 = 3; %tons of CO2 costs for upgrade
yearsPerHardwRep = 10; %numbers of years until replacement of electronics is needed
%ALSO replacing batteries--future note: could add an additional input param. for battery
%type and have if-statements to select variables for time to replace, cost
yearsPerBattRep = 10;


%tons of CO2 emissions due to generation of electricity that's non-solar
emissionsPerMWh = 0.5; %EPA regulation for natural gas emission standards

%Overload costs
%costPerMWhOverloadUSD = 100+36.66+250; %Costs per MWh overload non-tolerable by substation (USD). Arbitrary, now unused
costPerHourOverloadUSD = 5000; %Currently arbitrary, cost for every hour a non-tolerable overload occurs
costBaselinePerOverloadUSD = 1000; %currently arbitrary, baseline cost of a damaging overload

%revenue from solar MWh of generation
gainsPerMWhSolar = 23.11; %fuel cost of NG per MWh

%time scale for calculations
yearsTot = 30;

%% Calculate annual net energy consumption

%initalize array for annual demand (baseline load) and solar energy
annualEnergyDemand = zeros(yearsTot,1);
annualEnergySolar = zeros(yearsTot,1);

annualEnergyDemand(1) = energyLoad; %assign year 1 data
annualEnergySolar(1) = energySolar;

for i=2:yearsTot %interate through years, adjust for load growth, solar deg.
    annualEnergyDemand(i)=annualEnergyDemand(i-1)*(1+percLoadGrowth/100);
    annualEnergySolar(i)=annualEnergySolar(i-1)*(1-percSolarDeg/100);
end

annualNetEnergy = annualEnergyDemand - annualEnergySolar; %determine net energy as vector

% disp("annual Net energy");
% disp(length(annualNetEnergy));
% disp(annualNetEnergy);

%% Emissions costs

%%%Old method for determining emissions by calculating net energy from an
%%%input load. Net energy is now calculated seperately (above) and accounts
%%%for solar degredation.
%determine annual CO2 emissions from load data set, scale linearly for load growth
% %initalize energy and time increment
% annualEnergy = 0;
% deltaTime = 1; %1 hour between increments
% %disp("annual Energy: ");
% %disp(annualEnergy);
% 
% for i = 1:length(netLoad) %assume load data is for 1 year, with 1hr increments
%     if ~isnan(netLoad(i))
%         annualEnergy = annualEnergy + netLoad(i)*deltaTime; %energy is Reimann sum of load w/ respect to time
%     end
% %     if i == 1
% %         disp("annual Energy in loop: ");
% %         disp(annualEnergy);
% %         pause(5);
% %     end
% end
% % %Debug:
% % disp("annual Energy: ");
% % disp(annualEnergy);
% % pause(2.5);

%%%calculate annual emissions from power generation -- old
% annualLoadCO2 = zeros(yearsTot,1);
% annualLoadCO2(1) = annualNetEnergy(1)*emissionsPerMWh; %for year 1
% %determine for all other years based on proportionality to net energy
% annualLoadCO2 = annualLoadCO2(1).*(annualNetEnergy./annualNetEnergy(1));

%%%Determine annual emission reduction from the power generation of solar
annualLoadCO2 = -annualEnergySolar*emissionsPerMWh;


% disp("annual load CO2: ");
% disp(length(annualLoadCO2));
% disp(annualLoadCO2);
% pause(2.5);

%initalize arrays for total CO2 emissions, determine maintaince/inst. costs
netCostsCO2 = zeros(yearsTot,1);
annualCostsCO2 = zeros(yearsTot,1);
%net costs is the sum of all previous years, while annual is for each year
annualMaintainceSolarCO2 = annualMaintaincePerMWSolarCO2*sizeSolarMW;
annualMaintainceBESSCO2 = annualMaintaincePerMWhStorageCO2*sizeBESSMWh;
annualMaintainceSubstCO2 = annualMaintaincePerMWSubstCO2*substRatingMW;
instCostSolarCO2 = instCostSolarPerMWCO2*sizeSolarMW;
instCostBESSCO2 = instCostStoragePerMWhCO2*sizeBESSMWh;
instCostSubstCO2 = instCostSubstPerMWCO2*substUpgradeMW;

%determine for year 1
% disp(netCostsCO2);
% disp(length(netCostsCO2));
% disp("annual load CO2 index 1:");
% disp(annualLoadCO2(1));
netCostsCO2(1) = annualLoadCO2(1)+annualMaintainceSolarCO2+annualMaintainceBESSCO2+annualMaintainceSubstCO2+instCostSolarCO2+instCostBESSCO2+instCostSubstCO2;
% disp("net costsCO2 index 1: ");
% disp(netCostsCO2);
% pause(2.5);
annualCostsCO2(1) = netCostsCO2(1);

for i = 2:yearsTot %iterate through years of calculation
    %determine annual CO2 for this year
    annualCostsCO2(i)=annualLoadCO2(i)+annualMaintainceSolarCO2+annualMaintainceBESSCO2+annualMaintainceSubstCO2;
    %determine if hardware replacement
    if mod(i,yearsPerHardwRep) == 0
        annualCostsCO2(i) = annualCostsCO2(i) + costHardwRepPerMWCO2*sizeSolarMW; %assume scales linearly w/ size of solar
    end
    %determine if battery replacement
    if mod(i,yearsPerBattRep) == 0
         annualCostsCO2(i) = annualCostsCO2(i) + instCostBESSCO2*0.2; %assume replacing batteries is same cost as installing BESS (20% batt. rep)
    end
    %sum up annual contributions (costCO2 is total emissions, i.e. sum over all years)
    netCostsCO2(i)=netCostsCO2(i-1)+annualCostsCO2(i);
end

%% USD costs
%%%first determine overload cost for original grid system
%%%solar/storage or upgrade will have NPV benefits compared to original
%initalize
costsOverloadsOrig = zeros(yearsTot,1); %will be cost w/ status quo
costsOverloads = zeros(yearsTot,1); %cost for proposed system

if isBlackoutAtNP == 0 %in this case, allow limited overloads 
    %use total duration of damaging overloads along with a
    %baseline cost for each damaging overload that occurs
    totalDurationOverloadsOrig = sum(durationOverloadsOrig.*isDamagingOrig,'omitnan'); %total hours of overloads in year 1
    costsBaselineOverloadsOrig = sum(isDamagingOrig,'omitnan')*costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloadsOrig(1) = totalDurationOverloadsOrig*costPerHourOverloadUSD+costsBaselineOverloadsOrig;

    %determine overload costs for the remainder of the years using proportion to annual energy consuption
    costsOverloadsOrig = costsOverloadsOrig(1).*(annualEnergyDemand./annualEnergyDemand(1));
    
  %%%determine overload costs for current system (i.e. solar/storage or upgrade)
    %use total duration of damaging overloads along with a
    %baseline cost for each damaging overload that occurs
    totalDurationOverloads = sum(durationOverloads.*isDamaging,'omitnan'); %total hours of overloads in year 1
    costsBaselineOverloads = sum(isDamaging,'omitnan')*costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloads(1) = totalDurationOverloads*costPerHourOverloadUSD+costsBaselineOverloads;

    %determine overload costs for the remainder of the years using proportion
    costsOverloads = costsOverloads(1).*(annualNetEnergy./annualNetEnergy(1));

else
%%%calculate overload costs assuming blackouts for any overload above np
    %assume all overloads contribute to cost (ignore isDamaging)
    totalDurationOverloadsOrig = sum(durationOverloadsOrig,'omitnan'); %total hours of overloads in year 1
    costsBaselineOverloadsOrig = length(durationOverloadsOrig)*costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloadsOrig(1) = totalDurationOverloadsOrig*costPerHourOverloadUSD+costsBaselineOverloadsOrig;

    %determine overload costs for the remainder of the years using proportion to annual energy consuption
    costsOverloadsOrig = costsOverloadsOrig(1).*(annualEnergyDemand./annualEnergyDemand(1));
    
  %%%determine overload costs for current system (i.e. solar/storage or upgrade)
    %use total duration of all overloads along with a baseline cost per overload
    totalDurationOverloads = sum(durationOverloads,'omitnan'); %total hours of overloads in year 1
    costsBaselineOverloads = length(durationOverloads)*costBaselinePerOverloadUSD;
    %determine year 1 overload costs
    costsOverloads(1) = totalDurationOverloads*costPerHourOverloadUSD+costsBaselineOverloads;

    %determine overload costs for the remainder of the years using proportion
    costsOverloads = costsOverloads(1).*(annualNetEnergy./annualNetEnergy(1));
end
%determine the net costs caused by overloads -- i.e. the gain benefits (ideally gains) of
%improving the system to prevent overloads.
gainsOverloads = costsOverloadsOrig - costsOverloads; %will be positive (i.e. good for NPV)

%DEBUG
%disp("Annual gains from preventing overloads");
%disp(gainsOverloads);

%%%determine annual gains from solar generation
gainsSolarGen = annualEnergySolar*gainsPerMWhSolar;

%%%Determine annual gains from carbon pricing if used
%%%Assume carbon pricing is a gain provided for reducing emissions compared to original system
%initalize
gainsCarbonCredit = zeros(yearsTot,1);
if priceCarbon ~= 0
    gainsCarbonCredit = -priceCarbon.*annualCostsCO2; %"negative" emissions means positive gains
end
%DEBUG
%disp("Annual gains from carbon pricing");
%disp(gainsCarbonCredit);



%%%determine instalation costs/upgrade costs/annual maintaince costs for
%%%this system.
if sizeSolarMW > 0
    instCostSolarUSD = instCostSolarPerMWUSD*sizeSolarMW + 2.77E6;
    annualMaintainceSolarUSD=annualMaintaincePerMWSolarUSD*sizeSolarMW;
else
    instCostSolarUSD = 0;
    annualMaintainceSolarUSD = 0;
end
if sizeBESSMWh > 0
    instCostBESSUSD = instCostStoragePerMWhUSD*sizeBESSMWh + 1.75E7;
    annualMaintainceBESSUSD=annualMaintaincePerMWhStorageUSD*sizeBESSMWh;
else
    instCostBESSUSD = 0;
    annualMaintainceBESSUSD = 0;
    costHardwRepUSD = 0; %set hardware rep. costs for BESS/solar to be zero. Assume if no BESS, then there's no solar
    instCostStoragePerMWhUSD = 0; %set to zero, since used later to determine battery rep. costs
end
if substUpgradeMW > 0
    %arbirary inst. cost function for now
    instCostUpgradeUSD = instCostSubstPerMWUSD*(0.5*substUpgradeMW+substRatingMW);
else
    instCostUpgradeUSD = 0;
end
annualMaintainceSubstUSD=annualMaintaincePerMWSubstUSD*substRatingMW; %not in if statement, since solar/BESS still has it

%%%%%start calculating annual net costs-benefits
%initalize
annualCostBenefitUSD = zeros(yearsTot,1);


%determine upfront costs
upfrontCost = instCostSolarUSD+instCostBESSUSD+instCostUpgradeUSD;
%determine total costs after year 1
annualCostBenefitUSD(1) = gainsSolarGen(1)+gainsOverloads(1)+gainsCarbonCredit(1)-(annualMaintainceSolarUSD+annualMaintainceBESSUSD+annualMaintainceSubstUSD);

%run through all years
for i = 2:yearsTot
    %maintaince costs+overload costs
    annualCostBenefitUSD(i) = gainsSolarGen(i)+gainsOverloads(i)+gainsCarbonCredit(i)-(annualMaintainceSolarUSD+annualMaintainceBESSUSD+annualMaintainceSubstUSD);
    %check for hardware upgrade
    if mod(i,yearsPerHardwRep) == 0
        annualCostBenefitUSD(i) = annualCostBenefitUSD(i) - costHardwRepUSD; %add fixed cost for replacing hardware
    end
    %determine if battery replacement
    if mod(i,yearsPerBattRep) == 0
         annualCostBenefitUSD(i) = annualCostBenefitUSD(i) - (instCostStoragePerMWhUSD*sizeBESSMWh).*0.2; %use slope of BESS cost function w/out its y-intercept, assumes 20% battery rep.
    end
end

%determine NPV from annual cost-benefits, interest rate, and upfront costs
NPV_USD = zeros(yearsTot,1);
r = 0.03; %3 percent interest rate

%Use nested for loop to determine NPV up to year i in [1,yearsTot], with sum of annual
%costs for years t in [1,i] accounting for interest rate
for i = 1:yearsTot
    NPV_USD(i) = -upfrontCost; %start by adding upfront cost (negative)
    for t = 1:i
        %apply geometric series
        NPV_USD(i) = NPV_USD(i) + annualCostBenefitUSD(t)/((1+r).^t);
    end
end

%after determining NPV, add the upfront costs to the annual benefits-costs
annualCostBenefitUSD(1) = annualCostBenefitUSD(1) - upfrontCost;


end

