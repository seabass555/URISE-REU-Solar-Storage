function [powerOutBESS,energyBESS,netLoadBESS] = BESStFunc(npCapacity,timeofday,netLoadSolar,energyCapBESS,deltaTime,arraySize,solarGen,chargePowerCap,dischargePowerCap,initialEnergyBESS,time)
% % This is a time-based discharging BESS function, where the batteries
% % discharge evenly throughout a specified time period.  They will charge up
% % to 80% at night (when electricity prices are the lowest) and allow for
% % solar production that would have been curtailed to be harnessed.

%% Variable Assignment

emerBESS = 20/100; %percentage of energy left for emergency overloads
startdischarge = 19;
enddischarge = 23;
startcharge = 0;
endcharge = 7;
chargeviaSolarFactor = 60/100; %percent of NP Capacity production at which solar production would otherwise be curtailed

dischargetime = ((startdischarge):(enddischarge-1)); %have to subtract the end time by one, otherwise it will discharge for the hour it was supposed to end
chargetime = ((startcharge):(endcharge-1));

%initialize energy, power output, threshold arrays
energyBESS = zeros(length(time),1);
powerOutBESS = zeros(length(time),1);
schepowerOutBESS = zeros(length(time),1);
emerpowerOutBESS = zeros(length(time),1);
scheBESSnrg = zeros(length(time),1);
emerBESSnrg = zeros(length(time),1);

scheBESSnrgEmpty = energyCapBESS * emerBESS; %Allows for emergency energy to remained untouched by scheduled dishcharges
% % scheBESSnrg(i) = energyBESS(i).*[1-(emerBESS)]; %amount of energy in the batteries for scheduled discharges 

%correct for any power that is outside of power capacity limit (check both pos/neg limit)
schepowerOutBESS(schepowerOutBESS > chargePowerCap) = chargePowerCap;
schepowerOutBESS(schepowerOutBESS < -dischargePowerCap) = -dischargePowerCap;
emerpowerOutBESS(emerpowerOutBESS > chargePowerCap) = chargePowerCap;
emerpowerOutBESS(emerpowerOutBESS < -dischargePowerCap) = -dischargePowerCap;

%Account for the range of charge within the batteries
energyBESS(energyBESS > energyCapBESS) = energyCapBESS;
energyBESS(energyBESS < 0) = 0;
scheBESSnrg(scheBESSnrg > energyCapBESS) = energyCapBESS;
scheBESSnrg(scheBESSnrg < scheBESSnrgEmpty) = scheBESSnrgEmpty;
emerBESSnrg(emerBESSnrg > scheBESSnrgEmpty) = scheBESSnrgEmpty;
emerBESSnrg(emerBESSnrg < 0) = 0;

powerOutBESS = schepowerOutBESS + emerpowerOutBESS;

for i = (timeofday+1)
    deltaenergyBESS = -schepowerOutBESS(i) * deltaTime;
    emerdeltaenergyBESS = -emerpowerOutBESS(i) * deltaTime;
%     energyBESS(i) = (energyCapBESS * emerBESS) + scheBESSrng - emerpowerOutBESS(i);
    energyBESS(i) = scheBESSnrg(i) + emerBESSnrg(i);
    if i == i(:,1)
        scheBESSnrg(i) = initialEnergyBESS + deltaenergyBESS;
        emerBESSnrg(i) = emerdeltaenergyBESS;
    else
        scheBESSnrg(i) = scheBESSnrg(i-1) + deltaenergyBESS;
        emerBESSnrg(i) = emerBESSnrg(i-1) + emerdeltaenergyBESS;
    end
    
%% To determine Discharging Time

    if i == dischargetime
        schepowerOutBESS(i) = scheBESSnrg/(enddischarge-startdischarge); %averages out the power in BESS over the time period
    elseif netLoadSolar > npCapacity
        emerpowerOutBESS(i) = energyBESS(i); %accounts for emergency discharge
    else 
        schepowerOutBESS(i) = 0;
        emerpowerOutBESS(i) = 0;
    end

%% To Determine Charging Time

    if i == chargetime
        schepowerOutBESS(i) = -scheBESSnrg/(endcharge-startcharge); %averages out the BESS charging over the time period
    elseif solarGen > arraySize*chargeviaSolarFactor %Curtailed production would charge the batteries over 80% to full if possible 
        schepowerOutBESS(i) = solarGen - (arraySize.*chargeviaSolarFactor); %will charge the batteries based on the difference of solar generation and the percentage of the array size at which solar charging will start<> 
    else 
        schepowerOutBESS(i) = 0;
        emerpowerOutBESS(i) = 0;
    end
    
    if emerBESSnrg(i) < scheBESSnrgEmpty
        emerpowerOutBESS(i) = -chargePowerCap;
    else 
        emerpowerOutBESS(i) = 0;
    end
end
% powerOutBESS = schepowerOutBESS + emerpowerOutBESS;
netLoadBESS = netLoadSolar - powerOutBESS;
end

