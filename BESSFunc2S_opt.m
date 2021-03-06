function [runSolarBESS] = BESSFunc2S_opt(const, runSolarBESS)
%This is a modified version of the BESSFunc to implement thresholds that
%change over time based on a percentage of mean load (chargePerc, dischargePerc). Also uses a
%"dischargeFactor" which allows the load to go above the discharge
%threshold but stay under the overloadThreshold.
%Time increments must be in HOURS
%INPUTS: const.time,const.deltaTime,runSolarBESS.netLoadSolar,const.initialEnergyBESS,runSolarBESS.sizeBESS,const.hourPowerCapBESS,const.chargePerc,const.dischargePerc,const.dischargeFactor, const.npCapacity
%OUTPUTS: runSolarBESS.powerOutBESS,runSolarBESS.energyBESS,runSolarBESS.netLoadBESS

%determine power caps from hour capacity
%const.chargePowerCap = 15; %MW BESS charge Power Cap
%const.dischargePowerCap = 15; %MW BESS discharge Power Cap
if const.isSpecPower == 0
chargePowerCap = runSolarBESS.sizeBESS / const.hourPowerCapBESS; %MW BESS charge Power Cap, based on hour duration of max operation
dischargePowerCap = chargePowerCap; %MW BESS discharge Power Cap
else
    chargePowerCap = const.chargePowerCap;
    dischargePowerCap = const.dischargePowerCap;
end

%initialize energy, power output, threshold arrays
runSolarBESS.energyBESS = zeros(length(const.time),1); %energy stored in the ESS over time
runSolarBESS.energyTotBESS = 0; %total energy discharged by the BESS in one year
runSolarBESS.powerOutBESS = zeros(length(const.time),1);
dischargeThreshold = zeros(length(const.time),1);
chargeThreshold = zeros(length(const.time),1);

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
runSolarBESS.powerOutBESS(runSolarBESS.powerOutBESS > chargePowerCap) = chargePowerCap;
runSolarBESS.powerOutBESS(runSolarBESS.powerOutBESS < -dischargePowerCap) = -dischargePowerCap;
%plot(time, powerOutBESS);
%disp(runSolarBESS.powerOutBESS);

%% determine energy output

for i = 1:length(const.time)
    %calculate change in energy at index
    %implement charge/disch. efficiency here (line 56) <----- (could add
    %conditions to see if charging/discharging/charged by solar/etc.)
    deltaEnergyBESS = -runSolarBESS.powerOutBESS(i) * const.deltaTime; %Sebastian will kick you if you don't convert to energy
    %determine energy at each index from change in energy due to power
    if i == 1 %if first index
        runSolarBESS.energyBESS(i) = const.initialEnergyBESS + deltaEnergyBESS;
    else
        runSolarBESS.energyBESS(i) = runSolarBESS.energyBESS(i-1) + deltaEnergyBESS;
    end
    
    %Charge loss to go here <-----
    
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
    
    %energy below zero
    %implement depth of charge limit here (line 81) <-----
    if runSolarBESS.energyBESS(i) < 0 %replace 0s with minimum depth of charge
        runSolarBESS.energyBESS(i) = 0;
        
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

%determine net load with solar+BESS
runSolarBESS.netLoadBESS = runSolarBESS.netLoadSolar - runSolarBESS.powerOutBESS;

%determine total year-one gains from BESS operation (from load shifting,
%reducing cost of generation from peak hours)
hourGainsOfBESS = runSolarBESS.powerOutBESS .* const.hourCostOfGen;
runSolarBESS.yrOneGainsBESS = sum(hourGainsOfBESS,'omitnan');

end