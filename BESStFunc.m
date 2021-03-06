function [powerOutBESS,energyBESS,netLoadBESS] = BESStFunc(npCapacity,timeofday,netLoadSolar,solarGen,arraySize,energyCapBESS,deltaTime,chargePowerCap,dischargePowerCap,initialEnergyBESS,time)
% % This is a time-based discharging BESS function, where the batteries
% % discharge evenly throughout a specified time period.  They will charge up
% % to 80% at night (when electricity prices are the lowest) and allow for
% % solar production that would have been curtailed to be harnessed.

%% Variable Assignment

emerBESS = 20; %percentage of energy left for emergency overloads
emerBESSPercent = emerBESS/100; %convert to percentage
emerBESSnrg = energyCapBESS * emerBESSPercent;
startdischarge = 19;
enddischarge = 23;
startcharge = 0;
endcharge = 7;
chargeviaSolarFactor = 60/100; %percent of NP Capacity production at which solar production would otherwise be curtailed


%initialize energy, power output, threshold arrays
energyBESS = zeros(length(time),1);
powerOutBESS = zeros(length(time),1);
% schepowerOutBESS = zeros(length(time),1);
% emerpowerOutBESS = zeros(length(time),1);
% scheBESSnrg = zeros(length(time),1);
% emerBESSnrg = zeros(length(time),1);

scheBESSnrgEmpty = energyCapBESS * emerBESS; %Allows for emergency energy to remained untouched by scheduled dishcharges
% % scheBESSnrg(i) = energyBESS(i).*[1-(emerBESS)]; %amount of energy in the batteries for scheduled discharges 

%correct for any power that is outside of power capacity limit (check both pos/neg limit)
powerOutBESS(powerOutBESS > chargePowerCap) = chargePowerCap;
powerOutBESS(powerOutBESS < -dischargePowerCap) = -dischargePowerCap;
% emerpowerOutBESS(emerpowerOutBESS > chargePowerCap) = chargePowerCap;
% emerpowerOutBESS(emerpowerOutBESS < -dischargePowerCap) = -dischargePowerCap;

%Create a logical array that will output when the batteries charge and
%discharge
% dischargestart = (timeofday == startdischarge);
% chargestart = (timeofday == startcharge);
% dischargetime = (timeofday >= startdischarge+1) & (timeofday < enddischarge);
% chargetime = (timeofday >= startcharge+1) & (timeofday < endcharge);

isscheDischarge = (timeofday >= startdischarge) & (timeofday <= enddischarge);
isscheCharge = (timeofday >= startcharge) & (timeofday <= endcharge);

isOverloadDischarge = (netLoadSolar > npCapacity);
isChargeViaSolar = (solarGen > arraySize .* chargeviaSolarFactor);

powerOutBESS(isscheDischarge) = (energyCapBESS * emerBESSPercent)/(enddischarge - startdischarge);
powerOutBESS(isscheCharge) = (energyCapBESS * emerBESSPercent)/(endcharge - startcharge);
powerOutBESS(isOverloadDischarge) = netLoadSolar(isOverloadDischarge) - npCapacity;
powerOutBESS(isChargeViaSolar) = solarGen(isChargeViaSolar) - (arraySize .* chargeviaSolarFactor);

%Account for the range of charge within the batteries
energyBESS(energyBESS > energyCapBESS) = energyCapBESS;
energyBESS(energyBESS < 0) = 0;
% scheBESSnrg(scheBESSnrg > energyCapBESS) = energyCapBESS;
% scheBESSnrg(scheBESSnrg < scheBESSnrgEmpty) = scheBESSnrgEmpty;
% emerBESSnrg(emerBESSnrg > scheBESSnrgEmpty) = scheBESSnrgEmpty;
% emerBESSnrg(emerBESSnrg < 0) = 0;
% 
% %% Determine Power Output
% isDischarge = startdischarge:enddischarge;
% isCharge = startcharge:endcharge;
% 
% powerOutBESS(isDischarge) = (energyBESS - emerBESS)/(enddischarge - startdischarge);
% powerOutBESS(isCharge) = -(energyCapBESS - energyBESS)/(endcharge - startcharge);
% 
% %increase discharge if needed to reduce any overloads
% isOverload = (netLoad-powerOutBESS) > npCapacity;
% powerOutBESS(isOverload) = netLoad(isOverload) - npCapacity;

%Charge via solar here

% powerOutBESS = schepowerOutBESS + emerpowerOutBESS;

%%Adam's Attempt at Code
% for i = 1:length(time)
% %     hoursinDay = timeofday(i);
% %     schedeltaenergyBESS = -schepowerOutBESS(i) * deltaTime;
% %     emerdeltaenergyBESS = -emerpowerOutBESS(i) * deltaTime;
% %     powerOutBESS(i) = schepowerOutBESS(i) + emerpowerOutBESS(i);
% %     energyBESS(i) = (energyCapBESS * emerBESS) + scheBESSrng - emerpowerOutBESS(i);
% %     energyBESS(i) = scheBESSnrg(i) + emerBESSnrg(i);
%         deltaEnergyBESS = -powerOutBESS(i) * deltaTime;
%     if i == 1
% %         disp(scheBESSnrg)
% %         disp(initialEnergyBESS)
% %         disp(schedeltaenergyBESS)
%             energyBESS(i) = initialEnergyBESS + deltaEnergyBESS;
%     else
%             energyBESS(i) = energyBESS(i-1) + deltaEnergyBESS;
%     end
%     
% %% To determine Discharging Time
% 
%     if dischargestart(i) == 1 && energyBESS(i) > emerBESS
%     
%   SEB's suggestion: (make sure variable names are correct, this is just phsedocode)
%     %
%     if timeofday(i) == startcharge
%             powerOutBESS(i:i+(endcharge - startcharge)) = -((energyBESS(i) - emerBESSnrg)/(endcharge - startcharge));
%     elseif timeofday(i) == startdischarge
%         powerOutBESS(i:i+(enddischarge - startdischarge)) = (energyBESS(i) - emerBESSnrg)/(enddischarge - startdischarge); %averages out the power in BESS over the time period
%     end
%
%     if isOverloadDischarge(i) == 1
%            %powerOutBESS(i) = NetLoadSolar(i) - npCapacity;
%     elseif isChargedBySolar(i) == 1
%            %powerOutBESS(i) = -(power charged by solar at this index)
% 
%     
%     
% elseif netLoadSolar(i) > npCapacity %accounts for emergency discharge
%         powerOutBESS(i) = netLoadSolar - npCapacity;
%     else 
%         powerOutBESS(i) = 0;
%     end
% 
% %% To Determine Charging Time
% % 
%     if chargestart(i) == 1 % && netLoadSolar < npCapacity
%         powerOutBESS(i) = (energyCapBESS - energyBESS(i))/(endcharge - startcharge);
%     elseif chargetime(i) == 1
%         powerOutBESS(i) = powerOutBESS(i-1);
%     elseif netLoadSolar > npCapacity
%         powerOutBESS(i) = netLoadSolar - npCapacity;
%     else
%         powerOutBESS(i) = 0;
%     end
%     
%     if hoursinDay == chargetime
%         schepowerOutBESS(i) = -scheBESSnrg/(endcharge-startcharge); %averages out the BESS charging over the time period
%     elseif solarGen > arraySize*chargeviaSolarFactor %Curtailed production would charge the batteries over 80% to full if possible 
%         schepowerOutBESS(i) = solarGen - (arraySize.*chargeviaSolarFactor); %will charge the batteries based on the difference of solar generation and the percentage of the array size at which solar charging will start<> 
%     else 
%         schepowerOutBESS(i) = 0;
%         emerpowerOutBESS(i) = 0;
%     end
%     
%     if emerBESSnrg(i) < scheBESSnrgEmpty
%         emerpowerOutBESS(i) = -chargePowerCap;
%     else 
%         emerpowerOutBESS(i) = 0;
%     end
%     
%     deltaEnergyBESS = powerOutBESS(i) * deltaTime;
%   
%     if i > 1
%         energyBESS(i) = energyBESS(i-1) + deltaEnergyBESS;
%     else
%         energyBESS(i) = initialEnergyBESS + deltaEnergyBESS;
%     end

% Seb's Code
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

