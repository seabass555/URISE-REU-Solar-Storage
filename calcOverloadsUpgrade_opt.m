function [runUpgrade] = calcOverloadsUpgrade_opt(const, runUpgrade)
%This code is designed to work only with time in hour increments
    %INPUTS: const.load, const.npCapacity, runUpgrade.sizeUpgrade, const.time
    %OUTPUTS: runUpgrade.npOverloadsUpgrade,runUpgrade.durationOverloadUpgrade,runUpgrade.intensityOverloadUpgrade,runUpgrade.timeOverloadUpgrade,runUpgrade.isDamagingUpgrade
    
    %first, calculate overloads above nameplate capacity = npoverloads
    runUpgrade.npOverloadsUpgrade = const.load - (const.npCapacity+runUpgrade.sizeUpgrade);
    runUpgrade.npOverloadsUpgrade(runUpgrade.npOverloadsUpgrade<=0) = 0;  
    
    %determine number of overloads to initalize duration/intensity arrays later
    numOverloads = 0;
    for i = 1:length(const.load)
        if (runUpgrade.npOverloadsUpgrade(i) > 0)&&(i == 1 || runUpgrade.npOverloadsUpgrade(i-1) == 0) %if overload, and last index is 1 or no overload in previous index
            numOverloads = numOverloads + 1;
        end
    end
    
    %initalize
    runUpgrade.durationOverloadUpgrade = zeros(numOverloads,1);
    runUpgrade.intensityOverloadUpgrade = zeros(numOverloads,1);
    runUpgrade.timeOverloadUpgrade = zeros(numOverloads,1);
    
    nOverload = 0; %this will be the index for durationOverloads/intensityOverloads
    
    %iterate through overload data
    for i = 1:length(const.load)
        if runUpgrade.npOverloadsUpgrade(i) > 0 %check if overload = true
            
            %determine which overload this is and update hours for this
            %overload
            if (i == 1 || runUpgrade.npOverloadsUpgrade(i-1) == 0) %i.e. first hour of this overload
                nOverload = nOverload + 1; %increment overload index (for first overload, this will set to index 1)
            end
           
            if nOverload > 0
                %update hours for this overload
                runUpgrade.durationOverloadUpgrade(nOverload) = runUpgrade.durationOverloadUpgrade(nOverload) + 1;
                
                %update intensity of this overload (assuming load is higher)
                %--will convert from load to capacity factor after loop
                %also set timestamp
                if const.load(i) > runUpgrade.intensityOverloadUpgrade(nOverload)
                    runUpgrade.intensityOverloadUpgrade(nOverload) = const.load(i);
                    runUpgrade.timeOverloadUpgrade(nOverload) = i; %index of loop is the hour
                end
            end
            
            
%             %calculate adjusted overloads
%             if i < 24 %within first 24 hours
%                 meanCapacityFactor = 100 * mean(netLoadBESS(i:i+23))/(npCapacity); % calculate the capacity factor over 24 hour period in percent
%             else
%                 meanCapacityFactor = 100 * mean(netLoadBESS(i-23:i))/(npCapacity); % calculate the capacity factor over 24 hour period in percent
%             end
%             
%             %calculate the amount in Megawatts by which the nameplate capacity can be exceeded, as determined by the adjustment factor
%             Adjustment = ((100 - meanCapacityFactor) * (adjustmentFactor/100)) * npCapacity;
%             
%             %determine adjusted overloads
%             %an adjusted overload occurs when the load is greater than the adjusted nameplate capacity OR when the necessary adjustment exceeds the maximum allowable adjustment
%             if (netLoadBESS(i) > Adjustment + npCapacity) || (Adjustment >= (adjustmentFactorMax/100)*npCapacity)
%                 adjustedOverloads(i) = netLoadBESS(i) - npCapacity; %identify unacceptable overload above nameplate capacity
%             end
        end
    end
    
    %convert from load to capacity factor for intensityOverloads
    runUpgrade.intensityOverloadUpgrade = (runUpgrade.intensityOverloadUpgrade./(const.npCapacity+runUpgrade.sizeUpgrade)).*100; %as percent
    
    %determine if the overloads cause damage according to DTE specs.
    runUpgrade.isDamagingUpgrade = zeros(numOverloads,1);
    for i = 1:numOverloads
        if runUpgrade.intensityOverloadUpgrade(i) > 235
            runUpgrade.isDamagingUpgrade(i) = 1;
        elseif runUpgrade.intensityOverloadUpgrade(i) > 160 && runUpgrade.durationOverloadUpgrade(i) > 1
            runUpgrade.isDamagingUpgrade(i) = 1;
        elseif runUpgrade.intensityOverloadUpgrade(i) > 140 && runUpgrade.durationOverloadUpgrade(i) > 2
            runUpgrade.isDamagingUpgrade(i) = 1;
        elseif runUpgrade.intensityOverloadUpgrade(i) > 130 && runUpgrade.durationOverloadUpgrade(i) > 4
            runUpgrade.isDamagingUpgrade(i) = 1;
        elseif runUpgrade.intensityOverloadUpgrade(i) > 110 && runUpgrade.durationOverloadUpgrade(i) > 10
            runUpgrade.isDamagingUpgrade(i) = 1;
        elseif runUpgrade.intensityOverloadUpgrade(i) > 100 && runUpgrade.durationOverloadUpgrade(i) > 16
            runUpgrade.isDamagingUpgrade(i) = 1;
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