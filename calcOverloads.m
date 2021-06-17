function [npOverloads,adjustedOverloads] = calcOverloads(load, npCapacity, time, adjustmentFactorMax, adjustmentFactor)
    %This code is designed to work only with time in hour increments
    %first, calculate overloads above nameplate capacity = npoverloads
    %adjustmentFactor and adjustmentFactorMax must be in units of percent
    npOverloads = load - npCapacity;
    npOverloads(npOverloads<=0) = 0;
    meanCapacityFactor = 0;
    adjustedOverloads = zeros(length(time),1);
    
    %iterate through overload data
    for i = 1:length(load)
        if npOverloads(i) > 0 %check if overload = true
            
            if i < 24 %within first 24 hours
                meanCapacityFactor = 100 * mean(load(i:i+23))/(npCapacity); % calculate the capacity factor over 24 hour period in percent
            else
                meanCapacityFactor = 100 * mean(load(i-23:i))/(npCapacity); % calculate the capacity factor over 24 hour period in percent
            end
            
            %calculate the amount in Megawatts by which the nameplate capacity can be exceeded, as determined by the adjustment factor
            Adjustment = ((100 - meanCapacityFactor) * (adjustmentFactor/100)) * npCapacity;
            
            %determine adjusted overloads
            %an adjusted overload occurs when the load is greater than the adjusted nameplate capacity OR when the necessary adjustment exceeds the maximum allowable adjustment
            if (load(i) > Adjustment + npCapacity) || (Adjustment >= (adjustmentFactorMax/100)*npCapacity)
                adjustedOverloads(i) = load(i) - npCapacity; %identify unacceptable overload above nameplate capacity
            end
        end
    end
end