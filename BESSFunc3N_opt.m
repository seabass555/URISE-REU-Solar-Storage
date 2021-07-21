function [runSolarBESS] = BESSFunc3N_opt(const, runSolarBESS)
%This is a modified version of the BESSFunc to implement thresholds that
%change over time based on a percentage of mean load (chargePerc, dischargePerc). Also uses a
%"dischargeFactor" which allows the load to go above the discharge
%threshold but stay under the overloadThreshold.
%Time increments must be in HOURS

%initialize energy, power output, threshold arrays
runSolarBESS.energyBESS = zeros(length(const.time),1);
runSolarBESS.powerOutBESS = zeros(length(const.time),1);
dischargeThreshold = zeros(length(const.time),1);
chargeThreshold = zeros(length(const.time),1);
runSolarBESS.energyTotBESS = 0; %total energy discharged by the BESS in one year

%determine power caps from hour capacity
if const.isSpecPower == 0
chargePowerCap = runSolarBESS.sizeBESS / const.hourPowerCapBESS; %MW BESS charge Power Cap, based on hour duration of max operation
dischargePowerCap = chargePowerCap; %MW BESS discharge Power Cap
else
    chargePowerCap = const.chargePowerCap;
    dischargePowerCap = const.dischargePowerCap;
end


%% calculate charge/discharge thresholds

if length(const.time) > 168 %check for over a week of data (time in hours)
    for i = 1:(length(const.time)-168) %iterate through all indices up to last week
        %determine threshold by percentage * mean load over next week
        chargeThreshold(i) = (const.chargePerc/100)*mean(runSolarBESS.netLoadSolar(i:i+168));
        dischargeThreshold(i)= (const.dischargePerc/100)*mean(runSolarBESS.netLoadSolar(i:i+168));
    end
    %make last week of dataset constant
    chargeThreshold(end-168:end) = chargeThreshold(end-169);
    dischargeThreshold(end-168:end) = dischargeThreshold(end-169);
    
else %if we have a week or less of data
    chargeThreshold = (const.chargePerc/100)*mean(runSolarBESS.netLoadSolar);
    dischargeThreshold =(const.dischargePerc/100)*mean(runSolarBESS.netLoadSolar);
end

%% calculate power output of BESS

%get indices where we have charge/discharge
isDischarge = runSolarBESS.netLoadSolar > dischargeThreshold;
isCharge =  runSolarBESS.netLoadSolar < chargeThreshold;

%determine power output of BESS from thresholds
runSolarBESS.powerOutBESS(isDischarge) = (runSolarBESS.netLoadSolar(isDischarge) - dischargeThreshold(isDischarge)).*(const.dischargeFactor/100);
runSolarBESS.powerOutBESS(isCharge) = runSolarBESS.netLoadSolar(isCharge) - chargeThreshold(isCharge);

%increase discharge if needed to reduce any overloads
isOverload = (runSolarBESS.netLoadSolar-runSolarBESS.powerOutBESS) > const.npCapacity;
runSolarBESS.powerOutBESS(isOverload) = runSolarBESS.netLoadSolar(isOverload) - const.npCapacity;

%correct for any power that is outside of power capacity limit (check both pos/neg limit)
runSolarBESS.powerOutBESS(runSolarBESS.powerOutBESS > dischargePowerCap) = dischargePowerCap;
runSolarBESS.powerOutBESS(runSolarBESS.powerOutBESS < -chargePowerCap) = -chargePowerCap;
%plot(time, powerOutBESS);

%% determine energy output

for i = 1:length(const.time)
    
    %adjust power output to try and reduce ramping in the load (i.e. reduce
    %duck curve)
    if i > 1
        %calculate the slope in the net-load with solar, minus the BESS
        %power output
        loadSlope = (runSolarBESS.netLoadSolar(i)-runSolarBESS.powerOutBESS(i)) - (runSolarBESS.netLoadSolar(i-1)-runSolarBESS.powerOutBESS(i-1));
    else
        loadSlope = 0;
    end
    if loadSlope > const.posLoadChangeLim %positive slope, ramping up too much
        %increase power output to decrease slope
        runSolarBESS.powerOutBESS(i) = runSolarBESS.powerOutBESS(i) + (loadSlope-const.posLoadChangeLim);
    elseif loadSlope < const.negLoadChangeLim %negative slope, ramping down too much
        %decrease power output to increase slope
        runSolarBESS.powerOutBESS(i) = runSolarBESS.powerOutBESS(i) - (const.negLoadChangeLim-loadSlope);
    end
    %check to make sure that the net-load will not go negative
    if runSolarBESS.netLoadSolar(i) - runSolarBESS.powerOutBESS(i) < 0
        runSolarBESS.powerOutBESS(i) = runSolarBESS.netLoadSolar(i); %set power output equal to load
    end
    %check to make sure power output does not exceed maximum system specs
    if runSolarBESS.powerOutBESS(i) > dischargePowerCap
        runSolarBESS.powerOutBESS(i) = dischargePowerCap;
    end
    if runSolarBESS.powerOutBESS(i) < -chargePowerCap
        runSolarBESS.powerOutBESS(i) = -chargePowerCap;
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
    %disp("got to here");
end

% find the amount of cycles. A cycle is defined as a local minimum in the
%      energy stored in the ESS when at least 50% of the maximum daily
%      depth of discharge is used
localMinArr = islocalmin(runSolarBESS.energyBESS);
localMinArr(runSolarBESS.energyBESS(localMinArr) > (1 - (const.percDoDCap/100)/2) * runSolarBESS.sizeBESS);
runSolarBESS.cyclesPerYear = sum(sum(localMinArr));

%determine net load with solar+BESS
runSolarBESS.netLoadBESS = runSolarBESS.netLoadSolar - runSolarBESS.powerOutBESS;

%determine total year-one gains from BESS operation (from load shifting,
%reducing cost of generation from peak hours)
hourGainsOfBESS = runSolarBESS.powerOutBESS .* const.hourCostOfGen;
runSolarBESS.yrOneGainsBESS = sum(hourGainsOfBESS,'omitnan');

end