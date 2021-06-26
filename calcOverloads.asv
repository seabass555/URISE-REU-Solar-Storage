function [npOverloads,adjustedOverloads,durationOverloads,intensityOverloads,timestampOverloads,isDamaging] = calcOverloads(load, npCapacity, time, adjustmentFactorMax, adjustmentFactor)
    %This code is designed to work only with time in hour increments
    %first, calculate overloads above nameplate capacity = npoverloads
    %adjustmentFactor and adjustmentFactorMax must be in units of percent
    npOverloads = load - npCapacity;
    npOverloads(npOverloads<=0) = 0;
    meanCapacityFactor = 0;
    adjustedOverloads = zeros(length(time),1);    
    
    %determine number of overloads to initalize duration/intensity arrays later
    numOverloads = 0;
    for i = 1:length(load)
        if (npOverloads(i) > 0)&&(i == 1 || npOverloads(i-1) == 0) %if overload, and last index is 1 or no overload in previous index
            numOverloads = numOverloads + 1;
        end
    end
    
    %initalize
    durationOverloads = zeros(numOverloads,1);
    intensityOverloads = zeros(numOverloads,1);
    timestampOverloads = zeros(numOverloads,1);
    
    nOverload = 0; %this will be the index for durationOverloads/intensityOverloads
    
    %iterate through overload data
    for i = 1:length(load)
        if npOverloads(i) > 0 %check if overload = true
            
            %determine which overload this is and update hours for this
            %overload
            if (i == 1 || npOverloads(i-1) == 0) %i.e. first hour of this overload
                nOverload = nOverload + 1; %increment overload index (for first overload, this will set to index 1)
            end
            %update hours for this overload
            durationOverloads(nOverload) = durationOverloads(nOverload) + 1;
            
            %update intensity of this overload (assuming load is higher)
            %--will convert from load to capacity factor after loop
            %also set timestamp
            if load(i) > intensityOverloads(nOverload)
                intensityOverloads(nOverload) = load(i);
                timestampOverloads(nOverload) = i; %index of loop is the hour
            end
            
            %calculate adjusted overloads
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
    
    %convert from load to capacity factor for intensityOverloads
    intensityOverloads = (intensityOverloads./npCapacity).*100; %as percent
    
    %determine if the overloads cause damage according to DTE specs.
    isDamaging = zeros(numOverloads,1);
    for i = 1:numOverloads
        if intensityOverloads(i) > 235
            isDamaging(i) = 1;
        elseif intensityOverloads(i) > 160 && durationOverloads(i) > 1
            isDamaging(i) = 1;
        elseif intensityOverloads(i) > 140 && durationOverloads(i) > 2
            isDamaging(i) = 1;
        elseif intensityOverloads(i) > 130 && durationOverloads(i) > 4
            isDamaging(i) = 1;
        elseif intensityOverloads(i) > 110 && durationOverloads(i) > 10
            isDamaging(i) = 1;
        elseif intensityOverloads(i) > 100 && durationOverloads(i) > 16
            isDamaging(i) = 1;
        end
    end
    
    %debug
%     disp("total number of overloads found to be: ");
%     disp(numOverloads);
%     disp("duration of overloads:");
%     disp(durationOverloads);
%     disp("intensity of overloads:");
%     disp(intensityOverloads);
    
end