function [costsCO2, annualCostsCO2, costsUSD] = calcCosts(netLoad,percLoadGrowth,sizeSolarMW,sizeBESSMWh,substRatingMW,substUpgradeMW,overloads)
%calcCosts determines total CO2 emissions and costs in USD for solar+storage
%and substation upgeade. Determines costs annually and projects for 30 years.
%intended to be called twice in main function, once to calculate for solar+BESS,
%the other for substation upgrade calculations.
%% variable definitions
%**all values are currently arbitrary**
%instalation costs (USD, C02)
instCostSolarPerMWUSD = 100000; %USD costs per MW for solar instalation
instCostStoragePerMWhUSD = 150000; %USD costs per MWh for BESS instalation
instCostSubstPerMWUSD = 600000; %USD costs per MW for substation upgrade
instCostSolarPerMWCO2 = 3.97; %tons of CO2 costs per MW for solar instalation
instCostStoragePerMWhCO2 = 8.69; %tons of CO2 costs per MWh for BESS instalation
instCostSubstPerMWCO2 = 42.0; %tons of CO2 costs per MW for substation upgrade

%annual maintaince costs (USD, C02)
annualMaintaincePerMWSolarUSD = 100; %annual USD costs per MW of solar for maintaince
annualMaintaincePerMWhStorageUSD = 1000; %annual USD costs per MW of BESS for maintaince
annualMaintaincePerMWSubstUSD = 1000; %annual USD costs per MW of substation for maintaince
annualMaintaincePerMWSolarCO2 = 2; %annual co2 costs per MW of solar for maintaince
annualMaintaincePerMWhStorageCO2 = 2; %annual co2 costs per MW of BESS for maintaince
annualMaintaincePerMWSubstCO2 = 2.5; %annual co2 costs per MW of substation for maintaince


%power electronics replacement costs for solar and storage (CO2, USD)
costHardwRepPerMWUSD = 0; %USD costs for upgrading electronics for solar-storage
costHardwRepPerMWCO2 = 3; %tons of CO2 costs for upgrade
yearsPerHardwRep = 10; %numbers of years until replacement of electronics is needed
%ALSO replacing batteries--future note: could add an additional input param. for battery
%type and have if-statements to select variables for time to replace, cost
yearsPerBattRep = 15;

%tons of CO2 emissions due to generation of electricity that's non-solar
emissionsPerMWh = 0.5;

%Costs per MWh overload non-tolerable by substation (USD)
costPerMWhOverloadUSD = 10;

%time scale for calculations
yearsTot = 30;

%% computation

%determine annual CO2 emissions from load data set, scale linearly for load growth
%initalize energy and time increment
annualEnergy = 0;
deltaTime = 1; %1 hour between increments
%disp("annual Energy: ");
%disp(annualEnergy);

for i = 1:length(netLoad) %assume load data is for 1 year, with 1hr increments
    if ~isnan(netLoad(i))
        annualEnergy = annualEnergy + netLoad(i)*deltaTime; %energy is Reimann sum of load w/ respect to time
    end
%     if i == 1
%         disp("annual Energy in loop: ");
%         disp(annualEnergy);
%         pause(5);
%     end
end
% disp("annual Energy: ");
% disp(annualEnergy);
% pause(2.5);

%calculate annual emissions from power generation
annualLoadCO2 = zeros(yearsTot,1);
annualLoadCO2(1) = annualEnergy*emissionsPerMWh; %for year 1
for i = 2:yearsTot
    %determine emissions, considering load growth
    annualLoadCO2(i) = annualLoadCO2(i-1)*(1+percLoadGrowth/100);
end
disp("annual load CO2: ");
disp(annualLoadCO2);
pause(2.5);

%initalize arrays for total CO2 emissions, determine maintaince/inst. costs
costsCO2 = zeros(yearsTot,1);
annualCostsCO2 = zeros(yearsTot,1);
annualMaintainceSolarCO2 = annualMaintaincePerMWSolarCO2*sizeSolarMW;
annualMaintainceBESSCO2 = annualMaintaincePerMWhStorageCO2*sizeBESSMWh;
annualMaintainceSubstCO2 = annualMaintaincePerMWSubstCO2*substRatingMW;
instCostSolarCO2 = instCostSolarPerMWCO2*sizeSolarMW;
instCostBESSCO2 = instCostStoragePerMWhCO2*sizeBESSMWh;
instCostSubstCO2 = instCostSubstPerMWCO2*substUpgradeMW;

%determine for year 1
costsCO2(1)=annualLoadCO2(1)+annualMaintainceSolarCO2+annualMaintainceBESSCO2+annualMaintainceSubstCO2+instCostSolarCO2+instCostBESSCO2+instCostSubstCO2;
disp("costsCO2 index 1: ");
disp(costsCO2);
pause(2.5);
annualCostsCO2(1) = costsCO2(1);

for i = 2:yearsTot %iterate through years of calculation
    %determine annual CO2 for this year
    annualCostsCO2(i)=annualLoadCO2(i)+annualMaintainceSolarCO2+annualMaintainceBESSCO2+annualMaintainceSubstCO2;
    %determine if hardware replacement
    if mod(i,yearsPerHardwRep) == 0
        annualCostsCO2(i) = annualCostsCO2(i) + costHardwRepPerMWCO2*sizeSolarMW; %assume scales linearly w/ size of solar
    end
    %determine if battery replacement
    if mod(i,yearsPerBattRep) == 0
         annualCostsCO2(i) = annualCostsCO2(i) + instCostBESSCO2; %assume replacing batteries is same cost as installing BESS
    end
    %sum up annual contributions (costCO2 is total emissions, i.e. sum over all years)
    costsCO2(i)=costsCO2(i-1)+annualCostsCO2(i);
end

%% TBD USD costs
overloadEnergy = 0;
for i = 1:length(netLoad)
    overloadEnergy = overloadEnergy+overloads(i)*deltaTime;
end
costsUSD = instCostSolarPerMWUSD+instCostStoragePerMWhUSD+instCostSubstPerMWUSD+annualMaintaincePerMWSolarUSD+annualMaintaincePerMWhStorageUSD+annualMaintaincePerMWSubstUSD+costHardwRepPerMWUSD;
costsUSD = overloadEnergy*costPerMWhOverloadUSD;


end

