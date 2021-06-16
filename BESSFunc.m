function [powerOutBESS,energyBESS,netLoadBESS] = BESSFunc(time,deltaTime,netLoad,initialEnergyBESS,energyCapBESS,chargePowerCap,dischargePowerCap,chargeThreshold,dischargeThreshold)
energyBESS = zeros(length(time),1);
powerOutBESS = zeros(length(time),1);

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

netLoadBESS = netLoad - powerOutBESS;
end