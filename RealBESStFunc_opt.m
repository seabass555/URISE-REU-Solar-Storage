function [runSolarBESS] = RealBESStFunc_opt(const, runSolarBESS)
% % This is a time-based discharging BESS function, where the batteries
% % discharge evenly throughout a specified time period.  They will charge up
% % to 80% at night (when electricity prices are the lowest) and allow for
% % solar production that would have been curtailed to be harnessed.
%additional inputs:
%const.emerBESS,const.startCharge,const.endCharge,const.startDischarge,const.endDischarge,const.chargeViaSolarThreshold,

%% Variable Assignment

%determine power caps from hour capacity (or user input)
if const.isSpecPower == 0
chargePowerCap = runSolarBESS.sizeBESS / const.hourPowerCapBESS; %MW BESS charge Power Cap, based on hour duration of max operation
dischargePowerCap = chargePowerCap; %MW BESS discharge Power Cap
else
    chargePowerCap = const.chargePowerCap;
    dischargePowerCap = const.dischargePowerCap;
end

% const.emerBESS = 30; %percentage of energy left for emergency overloads
emerBESSPercent = const.emerBESS/100; %convert to percentage
emerBESSnrg = runSolarBESS.sizeBESS * emerBESSPercent;
% const.startDischarge = 17;
% const.endDischarge = 21;
% const.startCharge = 0;
% const.endCharge = 7;
% const.chargeViaSolarThreshold = 60;
chargeviaSolarFactor = const.chargeViaSolarThreshold/100; %percent of NP Capacity production at which solar production would otherwise be curtailed

%initialize energy, power output, threshold arrays
runSolarBESS.energyBESS = zeros(length(const.time),1);
runSolarBESS.powerOutBESS = zeros(length(const.time),1);
runSolarBESS.energyTotBESS = 0;

%Create a logical array to account for where Overloads take place as well
%as where solar would create an intense duck curve
isOverloadDischarge = (runSolarBESS.netLoadSolar > const.npCapacity);
isChargeViaSolar = (runSolarBESS.solarGen > runSolarBESS.sizeSolar .* chargeviaSolarFactor);

for i = 1:length(const.time)
    %Determine Power Output of Batteries
    if const.timeOfDay(i) == const.startCharge %to start scheduled charge 
        runSolarBESS.powerOutBESS(i:(i+(const.endCharge - const.startCharge))) = -((runSolarBESS.sizeBESS - emerBESSnrg)/(const.endCharge - const.startCharge));
    elseif const.timeOfDay(i) == const.startDischarge && i > 1 %to start scheduled discharge
        runSolarBESS.powerOutBESS(i:(i+(const.endDischarge - const.startDischarge))) = (runSolarBESS.energyBESS(i-1) - emerBESSnrg)/(const.endDischarge - const.startDischarge); %averages out the power in BESS over the time period
    %disp(runSolarBESS.powerOutBESS(i));
    end

    if isOverloadDischarge(i) == 1 %to define when overloads occur
        runSolarBESS.powerOutBESS(i) = runSolarBESS.netLoadSolar(i) - const.npCapacity;
    elseif isChargeViaSolar(i) == 1 %to define when solar generation charges the batteries
        runSolarBESS.powerOutBESS(i) = -(runSolarBESS.solarGen(i) - (runSolarBESS.sizeSolar * chargeviaSolarFactor));
    end
    
    %Establish the maximums at which the batteries can charge and discharge
    if runSolarBESS.powerOutBESS(i) > chargePowerCap
        runSolarBESS.powerOutBESS(i) = chargePowerCap;
    elseif runSolarBESS.powerOutBESS(i) < -dischargePowerCap
        runSolarBESS.powerOutBESS(i) = -dischargePowerCap;
    end
    
    %check to make sure that the net-load will not go negative
    if runSolarBESS.netLoadSolar(i) - runSolarBESS.powerOutBESS(i) < 0
        runSolarBESS.powerOutBESS(i) = runSolarBESS.netLoadSolar(i); %set power output equal to load
    end
    
    %calculate change in energy at index
    if runSolarBESS.powerOutBESS(i) < 0 && runSolarBESS.solarGen(i) < -runSolarBESS.powerOutBESS(i) % if batteries are charging AND solar output is NOT enough to cover their charging completely
        deltaEnergyBESS = runSolarBESS.solarGen(i) * const.deltaTime * const.roundTripEfficiency * const.converterEfficiency;
        runSolarBESS.powerOutBESS(i) = runSolarBESS.powerOutBESS(i) + runSolarBESS.solarGen(i);
        deltaEnergyBESS = deltaEnergyBESS + -runSolarBESS.powerOutBESS(i) * const.deltaTime * const.roundTripEfficiency * const.inverterEfficiency;
    elseif runSolarBESS.powerOutBESS(i) < 0 && runSolarBESS.solarGen(i) > -runSolarBESS.powerOutBESS(i) % if batteries are charging AND solar output is enough to cover their charging completely
        deltaEnergyBESS = -runSolarBESS.powerOutBESS(i) * const.deltaTime * const.roundTripEfficiency * const.converterEfficiency;
    else % if batteries are discharging OR neither charging nor discharging
        deltaEnergyBESS = -runSolarBESS.powerOutBESS(i) * const.deltaTime; %Sebastian will kick you if you don't convert to energy
    end
    
    %determine energy at each index from change in energy due to power
    if i == 1 %if first index
        runSolarBESS.energyBESS(i) = const.initialEnergyBESS + deltaEnergyBESS;
    else
        runSolarBESS.energyBESS(i) = runSolarBESS.energyBESS(i-1) + deltaEnergyBESS;
    end
    
    %implement charge loss; <= 3% per month is 0.00004196% per hour
    runSolarBESS.energyBESS(i) = runSolarBESS.energyBESS(i) * const.chargeLossFactor;
    
    %check to see if energy went above capacity or below 0 and correct energy and power
    %over capacity
    
    if runSolarBESS.energyBESS(i) > runSolarBESS.sizeBESS
        runSolarBESS.energyBESS(i) = runSolarBESS.sizeBESS;
        %recalculate power based on new change in energy
        if i == 1
            runSolarBESS.powerOutBESS(i) = -(runSolarBESS.energyBESS(i) - const.initialEnergyBESS)/const.deltaTime;
        else
            runSolarBESS.powerOutBESS(i) = -(runSolarBESS.energyBESS(i) - runSolarBESS.energyBESS(i-1))/const.deltaTime;
        end
    end
    
    %energy below zero (and specified max DoD)
    if runSolarBESS.energyBESS(i) < ((1 - const.percDoDCap/100) * runSolarBESS.sizeBESS)
        runSolarBESS.energyBESS(i) = ((1 - const.percDoDCap/100) * runSolarBESS.sizeBESS);
        
        %recalculate power based on new change in energy
        if i == 1
            runSolarBESS.powerOutBESS(i) = -(runSolarBESS.energyBESS(i) - const.initialEnergyBESS)/const.deltaTime;
        else
            runSolarBESS.powerOutBESS(i) = -(runSolarBESS.energyBESS(i) - runSolarBESS.energyBESS(i-1))/const.deltaTime;
        end
    end
    
    %determine the total energy output of the BESS over year 1
    %add any change in energy over the last hour
    if runSolarBESS.powerOutBESS(i) > 0 %positive power output means discharge
        if i == 1 %corner case, first index
            runSolarBESS.energyTotBESS = runSolarBESS.energyTotBESS + (const.initialEnergyBESS-runSolarBESS.energyBESS(i));
        else %otherwise if it's not first index
            %accumulate the difference in energy over previous hour
            runSolarBESS.energyTotBESS = runSolarBESS.energyTotBESS + (runSolarBESS.energyBESS(i-1)-runSolarBESS.energyBESS(i));
        end
    end
end

% find the amount of cycles. A cycle is defined as a local minimum in the
%      energy stored in the ESS when at least 50% of the maximum daily
%      depth of discharge is used
localMinArr = islocalmin(runSolarBESS.energyBESS);
localMinArr(runSolarBESS.energyBESS(localMinArr) > (1 - (const.percDoDCap/100)/2) * runSolarBESS.sizeBESS);
runSolarBESS.cyclesPerYear = sum(sum(localMinArr));

%calculate net load
runSolarBESS.netLoadBESS = runSolarBESS.netLoadSolar - runSolarBESS.powerOutBESS;

%determine total year-one gains from BESS operation (from load shifting,
%reducing cost of generation from peak hours)
hourGainsOfBESS = runSolarBESS.powerOutBESS .* const.hourCostOfGen;
runSolarBESS.yrOneGainsBESS = sum(hourGainsOfBESS,'omitnan');

end

