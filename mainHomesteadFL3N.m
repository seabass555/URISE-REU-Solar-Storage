%clean command window
clc;
close all;
clear;

%import data
input = readmatrix('2020DemandandSolar-Sheet1.csv');
input = input(1:end-1,:); %remove totals (last row)


%% VARIABLE ASSIGNMENTS

load = input(:,5); %5th column for load data in MW
solar1MW = input(:,9); %solar generation data for 1MW array

timeMat = input(:,1:3); %maxtrix data of the time
time = 1:length(timeMat);
time = time'; %time in hours for dataset
deltaTime = 1; % time increment IN HOURS

%BESS variables
energyCapBESS = 100; % MWh maximum capacity
initialEnergyBESS = 40; % MWh initial capacity
chargePowerCap = 15; %MW BESS charge Power Cap
dischargePowerCap = 15; %MW BESS discharge Power Cap
inverterEfficiency = .962;
converterEfficiency = .98;
roundTripEfficiency = .86;
DoDCap = 0.5; %depth of discharge cap

%use these for BESSFunc original:
%chargeThreshold = 65; % load in MW at when BESS will charge
%dischargeThreshold = 90; % load in MW when BESS will discharge

%use these for BESSFunc2S:
chargePerc = 90; %percentage of mean load to charge
dischargePerc = 110; %percentage of mean load to discharge
dischargeFactor = 50; %percentage for how much to bring down load to discharge threshold (0=none, 100=flat)


arraySize = 40; % capacity of solar array in MW

%substation overload variables
npCapacity = 90; %MW - nameplate rating of the substation transformer
adjustmentFactorMax = 25; %percent maximum tolerable increase above substation rating
adjustmentFactor = 0.4; %percent tolerable increase above rating for every percent the 24hr mean capacity factor is below 100%
npCapacityInc = 10; %for potential substation upgrade - MW increase in nameplate capacity



%% COMPUTATION


%calculate load-with-solar and solar generation
[netLoadSolar,solarGen] = calcLoadWithSolar(load,solar1MW,arraySize);

%calculate load with BESS, Energy in BESS, Power out of BESS
%For BESSFunc original
%[powerOutBESS,energyBESS,netLoadBESS] = BESSFunc(time,deltaTime,netLoadSolar,initialEnergyBESS,energyCapBESS,chargePowerCap,dischargePowerCap,chargeThreshold,dischargeThreshold);
%For BESSFunc2S:
%[powerOutBESS,energyBESS,netLoadBESS] = BESSFunc2S(time,deltaTime,netLoadSolar,initialEnergyBESS,energyCapBESS,chargePowerCap,dischargePowerCap,chargePerc,dischargePerc,dischargeFactor, npCapacity);
%For BESSFunc2S:
[cycleNum,powerOutBESS,energyBESS,netLoadBESS] = BESSFunc3N(time,deltaTime,netLoadSolar,initialEnergyBESS,energyCapBESS,chargePowerCap,dischargePowerCap,chargePerc,dischargePerc,dischargeFactor, npCapacity,solarGen,roundTripEfficiency,inverterEfficiency,converterEfficiency,DoDCap);

%calculate overloads, both above nameplate rating and damaging
%overload for load without solar+BESS and no substation upgrade
[npOverloadsBaseline,adjustedOverloadsBaseline] = calcOverloads(load, npCapacity, time, adjustmentFactorMax, adjustmentFactor);

%overloads for load with solar+BESS
[npOverloadsBESS,adjustedOverloadsBESS] = calcOverloads(netLoadBESS, npCapacity, time, adjustmentFactorMax, adjustmentFactor);

%overloads for load with w/out solar+BESS but with potential upgrade
[npOverloadsUpgrade,adjustedOverloadsUpgrade] = calcOverloads(load, (npCapacity+npCapacityInc), time, adjustmentFactorMax, adjustmentFactor);

%calculate costs TBD...
%percLoadGrowth = 3;
%[netCostsCO2BESS,annualCO2BESS,netCostsUSDBESS,annualCostsUSDBESS] = calcCosts(netLoadBESS,percLoadGrowth,arraySize,energyCapBESS,npCapacity,0,adjustedOverloadsBESS);
%[netCostsCO2Upgrade,annualCO2Upgrade,netCostsUSDUpgrade,annualCostsUSDUpgrade] = calcCosts(load,percLoadGrowth,0,0,(npCapacity+npCapacityInc),npCapacityInc,adjustedOverloadsUpgrade);


%% Generate graphs

plotSolarBESSLoad(1,load,netLoadSolar,netLoadBESS,solarGen,powerOutBESS,1,'Title Text');
plotSolarBESSLoad(2,load,netLoadSolar,netLoadBESS,solarGen,powerOutBESS,0,'Net Loads and Solar, BESS Outputs');

plotOverloads(3,load,npCapacity,npOverloadsBaseline,adjustedOverloadsBaseline,0,'Title Text');
title("Baseline Overloads");
plotOverloads(4,netLoadBESS,npCapacity,npOverloadsBESS,adjustedOverloadsBESS,0,'Title Text');
title("Overloads w/ Solar and BESS");

plotBESSData(5,netLoadBESS,powerOutBESS,energyBESS,0,'Title Text');

%plotCosts(6,netCostsCO2BESS,netCostsCO2Upgrade,netCostsUSDBESS,netCostsUSDUpgrade,'Title Text','Title 2 Text');
%title("Net Costs in C02 and USD");


% %graph of netload with just solar, netload with BESS+solar, solar generation, BESS power out
% %subplot(4,1,1);
% subplot(2,1,1);
% hold on;
% axis([4200 4500 -15 130]); %% parts of June and July only
% %axis([0 8040 -15 130]);
% plot(time,netLoadSolar, 'r');
% plot(time,powerOutBESS,'k');
% plot(time,netLoadBESS, 'g');
% plot(time,solarGen, 'y');
% xlabel('Time in hours after 12 am 1/1/20');
% ylabel('MW');
% legend('Load with Solar generation', 'BESS Power Output', 'Load with Solar and Storage', 'Solar Generation');
% title('Net Loads and Solar, BESS Outputs');
% xticks([0 744 1440 2184 2904 3648 4368 5112 5856 6576 7320 8040]);
% xticklabels({'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'});

%graph for overloads with BESS+solar system (also display BESS energy)
%subplot(4,1,2);
%subplot(2,1,2);
% colororder({'r','b'});
% %axis([4200 4500 0 30]); %% parts of June and July only
% hold on;
% yyaxis left
% axis([0 8800 0 28]);
% plot(time, npOverloadsBESS, 'k');
% plot(time, adjustedOverloadsBESS, 'r');
% ylabel('MW');
% yyaxis right
% axis([0 8800 0 250]);
% plot(time,energyBESS,'b'); %energy/10 to fit better on graph
% xlabel('Time in hours after 12 am 1/1/20');
% ylabel('MWh');
% legend('Overloads above Nameplate Capacity (MW)', 'Overloads above Nameplate Capacity that may result in damage (MW)', 'Energy Stored in BESS (MWh)');
% title('Overloads with Solar and BESS System');
% xticks([0 744 1440 2184 2904 3648 4368 5112 5856 6576 7320 8040]);
% xticklabels({'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'});



%graph for overloads without BESS+solar or upgrade
% subplot(4,1,3);
% hold on;
% axis([0 8800 0 70]);
% %axis([4200 4500 0 60]); %% parts of June and July only
% plot(time, npOverloadsBaseline, 'k');
% plot(time, adjustedOverloadsBaseline, 'r');
% xlabel('Time in hours after 12 am 1/1/20');
% ylabel('MW');
% legend('Overloads above Nameplate Capacity (MW)', 'Overloads above Nameplate Capacity that may result in damage (MW)');
% title('Overloads without Solar and BESS System or Upgrade');
% xticks([0 744 1440 2184 2904 3648 4368 5112 5856 6576 7320 8040]);
% xticklabels({'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'});
% 
% %graph for overloads with substation upgrade
% subplot(4,1,4);
% hold on;
% axis([0 8800 0 45]);
% %axis([4200 4500 0 45]); %% parts of June and July only
% plot(time, npOverloadsUpgrade, 'k');
% plot(time, adjustedOverloadsUpgrade, 'r');
% xlabel('Time in hours after 12 am 1/1/20');
% ylabel('MW');
% legend('Overloads above Nameplate Capacity (MW)', 'Overloads above Nameplate Capacity that may result in damage (MW)');
% title('Overloads with 10MW Substation Upgrade');
% xticks([0 744 1440 2184 2904 3648 4368 5112 5856 6576 7320 8040]);
% xticklabels({'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'});

%graph costs for CO2
% hold on;
% yyaxis left;
% plot(netCostsCO2BESS, '--o');
% plot(netCostsCO2Upgrade, 'k--o');
% ylabel('Tons CO2');
% yyaxis right;
% plot(netCostsUSDBESS, 'g--*');
% plot(netCostsUSDUpgrade, 'r--*');
% ylabel('US Dollars')
% xlabel('Years');
% legend('CO2 emissions BESS','CO2 emissions subst. upgrade','USD costs BESS','USD costs subst. upgrade');
% title('Costs in Net CO2 Emissions/USD');



