function [powerOutBESS,energyBESS,netLoadBESS] = RealBESStFunc(npCapacity,timeofday,netLoadSolar,solarGen,arraySize,energyCapBESS,deltaTime,chargePowerCap,dischargePowerCap,initialEnergyBESS,time)
% % This is a time-based discharging BESS function, where the batteries
% % discharge evenly throughout a specified time period.  They will charge up
% % to 80% at night (when electricity prices are the lowest) and allow for
% % solar production that would have been curtailed to be harnessed.

%% Variable Assignment

emerBESS = 30; %percentage of energy left for emergency overloads
emerBESSPercent = emerBESS/100; %convert to percentage
emerBESSnrg = energyCapBESS * emerBESSPercent;
startdischarge = 17;
enddischarge = 21;
startcharge = 0;
endcharge = 7;
chargeviaSolarFactor = 60/100; %percent of NP Capacity production at which solar production would otherwise be curtailed

%initialize energy, power output, threshold arrays
energyBESS = zeros(length(time),1);
powerOutBESS = zeros(length(time),1);

%Create a logical array to account for where Overloads take place as well
%as where solar would create an intense duck curve
isOverloadDischarge = (netLoadSolar > npCapacity);
isChargeViaSolar = (solarGen > arraySize .* chargeviaSolarFactor);

for i = 1:length(time)
    %Determine Power Output of Batteries
    if timeofday(i) == startcharge %to start scheduled charge 
        powerOutBESS(i:(i+(endcharge - startcharge))) = -((energyCapBESS - emerBESSnrg)/(endcharge - startcharge));
    elseif timeofday(i) == startdischarge && i > 1 %to start scheduled discharge
        powerOutBESS(i:(i+(enddischarge - startdischarge))) = (energyBESS(i-1) - emerBESSnrg)/(enddischarge - startdischarge); %averages out the power in BESS over the time period
%    disp(powerOutBESS(i));
    end

    if isOverloadDischarge(i) == 1 %to define when overloads occur
        powerOutBESS(i) = netLoadSolar(i) - npCapacity;
    elseif isChargeViaSolar(i) == 1 %to define when solar generation charges the batteries
        powerOutBESS(i) = -(solarGen(i) - (arraySize * chargeviaSolarFactor));
    end
    
    %Establish the maximums at which the batteries can charge and discharge
    if powerOutBESS(i) > chargePowerCap
        powerOutBESS(i) = chargePowerCap;
    elseif powerOutBESS(i) < -dischargePowerCap
        powerOutBESS(i) = -dischargePowerCap;
    end
    
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
netLoadBESS = netLoadSolar - powerOutBESS;
end

