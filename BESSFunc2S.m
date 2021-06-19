function [powerOutBESS,energyBESS,netLoadBESS] = BESSFunc2S(time,deltaTime,netLoad,initialEnergyBESS,energyCapBESS,chargePowerCap,dischargePowerCap,chargePerc,dischargePerc,dischargeFactor, overloadThreshold)
%This is a modified version of the BESSFunc to implement thresholds that
%change over time based on a percentage of mean load (chargePerc, dischargePerc). Also uses a
%"dischargeFactor" which allows the load to go above the discharge
%threshold but stay under the overloadThreshold.
%Time increments must be in HOURS

%initialize energy, power output, threshold arrays
energyBESS = zeros(length(time),1);
powerOutBESS = zeros(length(time),1);
dischargeThreshold = zeros(length(time),1);
chargeThreshold = zeros(length(time),1);

%% calculate charge/discharge thresholds

if length(time) > 168 %check for over a week of data (time in hours)
    for i = 1:(length(time)-168) %interate through all indecies up to last week
        %determine threshold by percentage * mean load over next week
        chargeThreshold(i) = (chargePerc/100)*mean(netLoad(i:i+168));
        dischargeThreshold(i)= (dischargePerc/100)*mean(netLoad(i:i+168));
    end
    %make last week of dataset constant
    chargeThreshold(end-168:end) = chargeThreshold(end-169);
    dischargeThreshold(end-168:end) = dischargeThreshold(end-169);
    
else %if we have a week or less of data
    chargeThreshold = (chargePerc/100)*mean(netLoad);
    dischargeThreshold =(dischargePerc/100)*mean(netLoad);
end

%% calculate power output of BESS

%get indices where we have charge/discharge
isDischarge = netLoad > dischargeThreshold;
isCharge =  netLoad < chargeThreshold;

%determine power output of BESS from thresholds
powerOutBESS(isDischarge) = (netLoad(isDischarge) - dischargeThreshold(isDischarge)).*(dischargeFactor/100);
powerOutBESS(isCharge) = netLoad(isCharge) - chargeThreshold(isCharge);

%increase discharge if needed to reduce any overloads
isOverload = (netLoad-powerOutBESS) > overloadThreshold;
powerOutBESS(isOverload) = netLoad(isOverload) - overloadThreshold;

%correct for any power that is outside of power capacity limit (check both pos/neg limit)
powerOutBESS(powerOutBESS > chargePowerCap) = chargePowerCap;
powerOutBESS(powerOutBESS < -dischargePowerCap) = -dischargePowerCap;
%plot(time, powerOutBESS);

%% determine energy output

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

%determine net load with solar+BESS
netLoadBESS = netLoad - powerOutBESS;
end