%clean command window
clc;
close all;
clear;

%import data
input = readmatrix('WA2020SolarandDemand-Sheet1.csv');
input = input(1:end-1,:); %remove totals (last row)


%% VARIABLE ASSIGNMENTS

load = input(:,5); %5th column for load data in MW
solar1MW = input(:,7); %solar generation data for 1MW array

timeMat = input(:,1:3); %maxtrix data of the time
time = 1:length(timeMat);
time = time'; %time in hours for dataset
deltaTime = 1; % time increment IN HOURS

%BESS variables
energyCapBESS = 400; % MWh maximum capacity
initialEnergyBESS = 80; % MWh initial capacity
chargePowerCap = 100; %MW BESS charge Power Cap
dischargePowerCap = 100; %MW BESS discharge Power Cap

%use these for BESSFunc original:
%chargeThreshold = 65; % load in MW at when BESS will charge
%dischargeThreshold = 90; % load in MW when BESS will discharge

%use these for BESSFunc2S:
chargePerc = 110; %percentage of mean load to charge
dischargePerc = 110; %percentage of mean load to discharge
dischargeFactor = 45; %percentage for how much to bring down load to discharge threshold (0=none, 100=flat)


arraySize = 160; % capacity of solar array in MW

%substation overload variables
npCapacity = 375; %MW - nameplate rating of the substation transformer
adjustmentFactorMax = 25; %percent maximum tolerable increase above substation rating
adjustmentFactor = 0.4; %percent tolerable increase above rating for every percent the 24hr mean capacity factor is below 100%
npCapacityInc = 20; %for potential substation upgrade - MW increase in nameplate capacity



%% COMPUTATION


%calculate load-with-solar and solar generation
[netLoadSolar,solarGen] = calcLoadWithSolar(load,solar1MW,arraySize);

%calculate load with BESS, Energy in BESS, Power out of BESS
%For BESSFunc original
%[powerOutBESS,energyBESS,netLoadBESS] = BESSFunc(time,deltaTime,netLoadSolar,initialEnergyBESS,energyCapBESS,chargePowerCap,dischargePowerCap,chargeThreshold,dischargeThreshold);
%For BESSFunc2S:
[powerOutBESS,energyBESS,netLoadBESS] = BESSFunc2S(time,deltaTime,netLoadSolar,initialEnergyBESS,energyCapBESS,chargePowerCap,dischargePowerCap,chargePerc,dischargePerc,dischargeFactor, npCapacity);

%calculate overloads, both above nameplate rating and damaging
%overload for load without solar+BESS and no substation upgrade
[npOverloadsBaseline,adjustedOverloadsBaseline] = calcOverloads(load, npCapacity, time, adjustmentFactorMax, adjustmentFactor);

%overloads for load with solar+BESS
[npOverloadsBESS,adjustedOverloadsBESS] = calcOverloads(netLoadBESS, npCapacity, time, adjustmentFactorMax, adjustmentFactor);

%overloads for load with w/out solar+BESS but with potential upgrade
[npOverloadsUpgrade,adjustedOverloadsUpgrade] = calcOverloads(load, (npCapacity+npCapacityInc), time, adjustmentFactorMax, adjustmentFactor);

%calculate costs TBD...


%% Generate graphs

plotSolarBESSLoad(1,load,netLoadSolar,netLoadBESS,solarGen,powerOutBESS,1);
plotSolarBESSLoad(2,load,netLoadSolar,netLoadBESS,solarGen,powerOutBESS,0);

plotOverloads(3,load,npCapacity,npOverloadsBaseline,adjustedOverloadsBaseline,0);
title("Baseline Overloads");
plotOverloads(4,netLoadBESS,npCapacity,npOverloadsBESS,adjustedOverloadsBESS,0);
title("Overloads w/ Solar and BESS");

plotBESSData(5,netLoadBESS,powerOutBESS,energyBESS,0);

plotCosts(6,netCostsCO2BESS,netCostsCO2Upgrade,netCostsUSDBESS,netCostsUSDUpgrade);
title("Net Costs in C02 and USD");
