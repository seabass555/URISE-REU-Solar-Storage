clc;
close all;
clear;

% *** indicates that the variable declared in this line will be an input to the function in the future

input = readmatrix('2020DemandandSolar-Sheet1.csv');
input = input(1:end-1,:); %remove totals

load = input(:,5);
solar1MW = input(:,9);
timeMat = input(:,1:3);
time = 1:length(timeMat); % ***
time = time';

deltaTime = 1; % time increment IN HOURS - Nate will kick you if you add time in minutes ***
energyCapBESS = 100; % 40 MWh maximum capacity ***
initialEnergyBESS = 40; % 40 MWh initial capacity ***
chargeThreshold = 65; % ***
dischargeThreshold = 90; % ***
energyBESS = zeros(length(time),1);
powerOutBESS = zeros(length(time),1);
chargePowerCap = 15; %15 MW BESS charge Power Cap ***
dischargePowerCap = 15; %15 MW BESS discharge Power Cap ***
arraysize = 40; % capacity of solar array in MW
solar = solar1MW .* arraysize;

netLoad = load - solar; % ***

%get indices where we have charge/discharge
isDischarge = netLoad > dischargeThreshold;
isCharge =  netLoad < chargeThreshold;

%determine power output of BESS
powerOutBESS(isDischarge) = netLoad(isDischarge) - dischargeThreshold;
powerOutBESS(isCharge) = netLoad(isCharge) - chargeThreshold;
%correct for any power that is outside of power capacity limit (check both pos/neg limit)
powerOutBESS(powerOutBESS > chargePowerCap) = chargePowerCap;
powerOutBESS(powerOutBESS < -dischargePowerCap) = -dischargePowerCap;
%plot(time, powerOutBESS);

%%% get energy %%%
for i = 1:length(time)
    %calculate change in energy at index
    deltaEnergyBESS = -powerOutBESS(i) * deltaTime; %Sebastian will kick you if you don't convert to energy
    %determine energy at each index from change in energy due to power
    if i == 1 %if first index
        energyBESS(i) = initialEnergyBESS + deltaEnergyBESS;
    else
        energyBESS(i) = energyBESS(i-1) + deltaEnergyBESS;
    end
    
    %check to see if energy went above capacity or below 0 and correct energy and power
    %over capacity
    
    if energyBESS(i) > energyCapBESS
        energyBESS(i) = energyCapBESS;
        %recalculate power based on new change in energy
        if i == 1
            powerOutBESS(i) = -(energyBESS(i) - initialEnergyBESS)/deltaTime;
        else
            powerOutBESS(i) = -(energyBESS(i) - energyBESS(i-1))/deltaTime;
        end
    end
    
    %energy below zero
    if energyBESS(i) < 0
        energyBESS(i) = 0;
        
        %recalculate power based on new change in energy
        if i == 1
            powerOutBESS(i) = -(energyBESS(i) - initialEnergyBESS)/deltaTime;
        else
            powerOutBESS(i) = -(energyBESS(i) - energyBESS(i-1))/deltaTime;
        end
    end
end

netLoadAdjusted = netLoad - powerOutBESS;

hold on;
%plot(time,powerOutBESS);
plot(time,netLoad, 'r');
plot(time,powerOutBESS,'k');
%plot(time,energyBESS, 'b');
plot(time,netLoadAdjusted, 'g');
plot(time,solar, 'y');