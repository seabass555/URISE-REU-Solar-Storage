function [cycleNum,powerOutBESS,energyBESS,netLoadBESS] = BESSFunc3N(time,deltaTime,netLoad,initialEnergyBESS,energyCapBESS,chargePowerCap,dischargePowerCap,chargePerc,dischargePerc,dischargeFactor,overloadThreshold,solarGen,roundTripEfficiency,inverterEfficiency,converterEfficiency,DoDCap)
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
    for i = 1:(length(time)-168) %iterate through all indices up to last week
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
    if powerOutBESS(i) < 0 && solarGen(i) < -powerOutBESS(i) % if batteries are charging AND solar output is NOT enough to cover their charging completely
        deltaEnergyBESS = solarGen(i) * deltaTime * roundTripEfficiency * converterEfficiency;
        powerOutBESS(i) = powerOutBESS(i) + solarGen(i);
        deltaEnergyBESS = deltaEnergyBESS + -powerOutBESS(i) * deltaTime * roundTripEfficiency * inverterEfficiency;
    elseif powerOutBESS(i) < 0 && solarGen(i) > -powerOutBESS(i) % if batteries are charging AND solar output is enough to cover their charging completely
        deltaEnergyBESS = -powerOutBESS(i) * deltaTime * roundTripEfficiency * converterEfficiency;
    else % if batteries are discharging OR neither charging nor discharging
        deltaEnergyBESS = -powerOutBESS(i) * deltaTime; %Sebastian will kick you if you don't convert to energy
    end
    %determine energy at each index from change in energy due to power 
    
    if i == 1 %if first index
        energyBESS(i) = initialEnergyBESS + deltaEnergyBESS;
    else
        energyBESS(i) = energyBESS(i-1) + deltaEnergyBESS;
    end
    
    %implement charge loss; <= 3% per month is 0.00004196% per hour
    energyBESS(i) = energyBESS(i) * 0.999958904; 
    
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
    if energyBESS(i) < ((1 - DoDCap) * energyCapBESS)
        energyBESS(i) = ((1 - DoDCap) * energyCapBESS);
        
        %recalculate power based on new change in energy
        if i == 1
            powerOutBESS(i) = -(energyBESS(i) - initialEnergyBESS)/deltaTime;
        else
            powerOutBESS(i) = -(energyBESS(i) - energyBESS(i-1))/deltaTime;
        end
    end
end

% find the amount of cycles. A cycle is defined as a local minimum in the
%      energy stored in the ESS when at least 50% of the maximum daily
%      depth of discharge is used
localMinArr = islocalmin(energyBESS);
localMinArr(energyBESS(localMinArr) > (1 - DoDCap/2) * energyCapBESS)
cycleNum = sum(sum(localMinArr));

%determine net load with solar+BESS
netLoadBESS = netLoad - powerOutBESS;
end