function [powerOutBESS,energyBESS,netLoadBESS] = BESSt2Func(npCapacity,timeofday,netLoadSolar,solarGen,arraySize,energyCapBESS,deltaTime,chargePowerCap,dischargePowerCap,initialEnergyBESS,time)
% % This is a time-based discharging BESS function, where the batteries
% % discharge evenly throughout a specified time period.  They will charge up
% % to 80% at night (when electricity prices are the lowest) and allow for
% % solar production that would have been curtailed to be harnessed.

%% Variable Assignment

emerBESS = 20; %percentage of energy left for emergency overloads
emerBESSPercent = emerBESS/100; %convert to percentage
startdischarge = 19;
enddischarge = 23;
startcharge = 0;
endcharge = 7;
chargeviaSolarFactor = 60/100; %percent of NP Capacity production at which solar production would otherwise be curtailed


%initialize energy, power output, threshold arrays
energyBESS = zeros(length(time),1);
powerOutBESS = zeros(length(time),1);

%correct for any power that is outside of power capacity limit (check both pos/neg limit)
powerOutBESS(powerOutBESS > chargePowerCap) = chargePowerCap;
powerOutBESS(powerOutBESS < -dischargePowerCap) = -dischargePowerCap;

%% Determine Power Output
isscheDischarge = (timeofday >= startdischarge) & (timeofday <= enddischarge); %Sets the discharging time
isscheCharge = (timeofday >= startcharge) & (timeofday <= endcharge); %Sets the charging time

isOverloadDischarge = (netLoadSolar > npCapacity); %Accounting for Overloads
isChargeViaSolar = (solarGen > arraySize .* chargeviaSolarFactor); %Allows the batteries to charge via solar

powerOutBESS(isscheDischarge) = (energyCapBESS * emerBESSPercent)/(enddischarge - startdischarge); %Allows for an even distribution of discharge
powerOutBESS(isscheCharge) = (energyCapBESS * emerBESSPercent)/(endcharge - startcharge); %Allows for an even distribution of charge
powerOutBESS(isOverloadDischarge) = netLoadSolar(isOverloadDischarge) - npCapacity; %Quells overload back to the npCapacity
powerOutBESS(isChargeViaSolar) = solarGen(isChargeViaSolar) - (arraySize .* chargeviaSolarFactor); %Will chage the batteries whenever the solar generates >60% of its nameplate

%Account for the range of charge within the batteries
% energyBESS(energyBESS > energyCapBESS) = energyCapBESS;
% energyBESS(energyBESS < 0) = 0;

%% Determine Energy Output
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
% powerOutBESS = schepowerOutBESS + emerpowerOutBESS;
netLoadBESS = netLoadSolar - powerOutBESS;
end


