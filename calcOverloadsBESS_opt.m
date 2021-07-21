function [runSolarBESS] = calcOverloadsBESS_opt(const, runSolarBESS)
%This code is designed to work only with time in hour increments
    %INPUTS: runSolarBESS.netLoadBESS, const.npCapacity, const.time
    %OUTPUTS: runSolarBESS.npOverloadsBESS,runSolarBESS.durationOverloadBESS,runSolarBESS.intensityOverloadBESS,runSolarBESS.timeOverloadBESS,runSolarBESS.isDamagingBESS
    
    %first, calculate overloads above nameplate capacity = npoverloads
    runSolarBESS.npOverloadsBESS = runSolarBESS.netLoadBESS - const.npCapacity;
    runSolarBESS.npOverloadsBESS(runSolarBESS.npOverloadsBESS<=0) = 0;  
    
    %determine number of overloads to initalize duration/intensity arrays later
    numOverloads = 0;
    for i = 1:length(runSolarBESS.netLoadBESS)
        if (runSolarBESS.npOverloadsBESS(i) > 0)&&(i == 1 || runSolarBESS.npOverloadsBESS(i-1) == 0) %if overload, and last index is 1 or no overload in previous index
            numOverloads = numOverloads + 1;
        end
    end
    
    %initalize
    runSolarBESS.durationOverloadBESS = zeros(numOverloads,1);
    runSolarBESS.intensityOverloadBESS = zeros(numOverloads,1);
    runSolarBESS.timeOverloadBESS = zeros(numOverloads,1);
    
    nOverload = 0; %this will be the index for durationOverloads/intensityOverloads
    
    %iterate through overload data
    for i = 1:length(runSolarBESS.netLoadBESS)
        if runSolarBESS.npOverloadsBESS(i) > 0 %check if overload = true
            
            %determine which overload this is and update hours for this
            %overload
            if (i == 1 || runSolarBESS.npOverloadsBESS(i-1) == 0) %i.e. first hour of this overload
                nOverload = nOverload + 1; %increment overload index (for first overload, this will set to index 1)
            end
           
            if nOverload > 0
                %update hours for this overload
                runSolarBESS.durationOverloadBESS(nOverload) = runSolarBESS.durationOverloadBESS(nOverload) + 1;
                
                %update intensity of this overload (assuming load is higher)
                %--will convert from load to capacity factor after loop
                %also set timestamp
                if runSolarBESS.netLoadBESS(i) > runSolarBESS.intensityOverloadBESS(nOverload)
                    runSolarBESS.intensityOverloadBESS(nOverload) = runSolarBESS.netLoadBESS(i);
                    runSolarBESS.timeOverloadBESS(nOverload) = i; %index of loop is the hour
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
    runSolarBESS.intensityOverloadBESS = (runSolarBESS.intensityOverloadBESS./const.npCapacity).*100; %as percent
    
    %determine if the overloads cause damage according to DTE specs.
    runSolarBESS.isDamagingBESS = zeros(numOverloads,1);
    for i = 1:numOverloads
        if runSolarBESS.intensityOverloadBESS(i) > 235
            runSolarBESS.isDamagingBESS(i) = 1;
        elseif runSolarBESS.intensityOverloadBESS(i) > 160 && runSolarBESS.durationOverloadBESS(i) > 1
            runSolarBESS.isDamagingBESS(i) = 1;
        elseif runSolarBESS.intensityOverloadBESS(i) > 140 && runSolarBESS.durationOverloadBESS(i) > 2
            runSolarBESS.isDamagingBESS(i) = 1;
        elseif runSolarBESS.intensityOverloadBESS(i) > 130 && runSolarBESS.durationOverloadBESS(i) > 4
            runSolarBESS.isDamagingBESS(i) = 1;
        elseif runSolarBESS.intensityOverloadBESS(i) > 110 && runSolarBESS.durationOverloadBESS(i) > 10
            runSolarBESS.isDamagingBESS(i) = 1;
        elseif runSolarBESS.intensityOverloadBESS(i) > 100 && runSolarBESS.durationOverloadBESS(i) > 16
            runSolarBESS.isDamagingBESS(i) = 1;
        end
    end
    
    %determine the total energy of overloads and damaging overloads
    runSolarBESS.energyNPOverload = sum(runSolarBESS.npOverloadsBESS,'omitnan');
    runSolarBESS.energyDamagingOverload = 0;
    nOverload = 0;
    
    for i = 1:length(runSolarBESS.npOverloadsBESS)
        %count which overload this is
        if i > 1 && (runSolarBESS.npOverloadsBESS(i) > 0 && runSolarBESS.npOverloadsBESS(i-1) == 0)
            nOverload = nOverload + 1;
        elseif i == 1 && runSolarBESS.npOverloadsBESS(i) > 0 %corner case-overload at first index
            nOverload = 1;
        end
        
        %check to see if this overload is damaging, and if so, add to the
        %energy of damaging overloads, also check to make sure it's ~NaN
        if nOverload > 0
            if (runSolarBESS.npOverloadsBESS(i) > 0 && runSolarBESS.isDamagingBESS(nOverload) == 1) && ~isnan(runSolarBESS.npOverloadsBESS(i))
                %add to the energy
                runSolarBESS.energyDamagingOverload = runSolarBESS.energyDamagingOverload + runSolarBESS.npOverloadsBESS(i)*1;
            end
        end
    end
    
    %debug
%     disp("total number of overloads found to be: ");
%     disp(numOverloads);
%     disp("duration of overloads:");
%     disp(durationOverloads);
%     disp("intensity of overloads:");
%     disp(intensityOverloads);
%     disp("energy of overloads, np/damaging");
%     disp(runSolarBESS.energyNPOverload);
%     disp(runSolarBESS.energyDamagingOverload);
    
end