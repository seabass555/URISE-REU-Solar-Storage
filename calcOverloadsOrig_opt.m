function [const] = calcOverloadsOrig_opt(const)
%This code is designed to work only with time in hour increments
    %INPUTS: const.load, const.npCapacity, const.time
    %OUTPUTS: const.npOverloadsOrig,const.durationOverloadOrig,const.intensityOverloadOrig,const.timeOverloadOrig,const.isDamagingOrig
    
    %first, calculate overloads above nameplate capacity = npoverloads
    const.npOverloadsOrig = const.load - const.npCapacity;
    const.npOverloadsOrig(const.npOverloadsOrig<=0) = 0;  
    
    %determine number of overloads to initalize duration/intensity arrays later
    numOverloads = 0;
    for i = 1:length(const.load)
        if (const.npOverloadsOrig(i) > 0)&&(i == 1 || const.npOverloadsOrig(i-1) == 0) %if overload, and last index is 1 or no overload in previous index
            numOverloads = numOverloads + 1;
        end
    end
    
    %initalize
    const.durationOverloadOrig = zeros(numOverloads,1);
    const.intensityOverloadOrig = zeros(numOverloads,1);
    const.timeOverloadOrig = zeros(numOverloads,1);
    
    nOverload = 0; %this will be the index for durationOverloads/intensityOverloads
    
    %iterate through overload data
    for i = 1:length(const.load)
        if const.npOverloadsOrig(i) > 0 %check if overload = true
            
            %determine which overload this is and update hours for this
            %overload
            if (i == 1 || const.npOverloadsOrig(i-1) == 0) %i.e. first hour of this overload
                nOverload = nOverload + 1; %increment overload index (for first overload, this will set to index 1)
            end
           
            if nOverload > 0
                %update hours for this overload
                const.durationOverloadOrig(nOverload) = const.durationOverloadOrig(nOverload) + 1;
                
                %update intensity of this overload (assuming load is higher)
                %--will convert from load to capacity factor after loop
                %also set timestamp
                if const.load(i) > const.intensityOverloadOrig(nOverload)
                    const.intensityOverloadOrig(nOverload) = const.load(i);
                    const.timeOverloadOrig(nOverload) = i; %index of loop is the hour
                end
            end
            
            
%             %calculate adjusted overloads
%             if i < 24 %within first 24 hours
%                 meanCapacityFactor = 100 * mean(load(i:i+23))/(npCapacity); % calculate the capacity factor over 24 hour period in percent
%             else
%                 meanCapacityFactor = 100 * mean(load(i-23:i))/(npCapacity); % calculate the capacity factor over 24 hour period in percent
%             end
%             
%             %calculate the amount in Megawatts by which the nameplate capacity can be exceeded, as determined by the adjustment factor
%             Adjustment = ((100 - meanCapacityFactor) * (adjustmentFactor/100)) * npCapacity;
%             
%             %determine adjusted overloads
%             %an adjusted overload occurs when the load is greater than the adjusted nameplate capacity OR when the necessary adjustment exceeds the maximum allowable adjustment
%             if (load(i) > Adjustment + npCapacity) || (Adjustment >= (adjustmentFactorMax/100)*npCapacity)
%                 adjustedOverloads(i) = load(i) - npCapacity; %identify unacceptable overload above nameplate capacity
%             end
        end
    end
    
    %convert from load to capacity factor for intensityOverloads
    const.intensityOverloadOrig = (const.intensityOverloadOrig./const.npCapacity).*100; %as percent
    
    %determine if the overloads cause damage according to DTE specs.
    const.isDamagingOrig = zeros(numOverloads,1);
    for i = 1:numOverloads
        if const.intensityOverloadOrig(i) > 235
            const.isDamagingOrig(i) = 1;
        elseif const.intensityOverloadOrig(i) > 160 && const.durationOverloadOrig(i) > 1
            const.isDamagingOrig(i) = 1;
        elseif const.intensityOverloadOrig(i) > 140 && const.durationOverloadOrig(i) > 2
            const.isDamagingOrig(i) = 1;
        elseif const.intensityOverloadOrig(i) > 130 && const.durationOverloadOrig(i) > 4
            const.isDamagingOrig(i) = 1;
        elseif const.intensityOverloadOrig(i) > 110 && const.durationOverloadOrig(i) > 10
            const.isDamagingOrig(i) = 1;
        elseif const.intensityOverloadOrig(i) > 100 && const.durationOverloadOrig(i) > 16
            const.isDamagingOrig(i) = 1;
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