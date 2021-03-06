function [runSolarBESS] = calcLoadWithSolar_opt(const, runSolarBESS)
%calculates the load with solar generation applied
%also returns the solar pennetration and year 1 energy for baseline load and solar gen.
%inputs: const.load, const.solarGen1MW, runSolarBESS.sizeSolar
%outputs: runSolarBESS.netLoadSolar,runSolarBESS.solarGen,runSolarBESS.energySolar,runSolarBESS.percSolarPen

runSolarBESS.solarGen = const.solarGen1MW .* runSolarBESS.sizeSolar;
runSolarBESS.netLoadSolar = const.load-runSolarBESS.solarGen;
%correct if net load would end up becoming negative
runSolarBESS.netLoadSolar(runSolarBESS.netLoadSolar<0) = 0;
runSolarBESS.solarGen(runSolarBESS.solarGen > const.load) = const.load(runSolarBESS.solarGen > const.load);

% %correct if the load would surpass the max rate of change in load
% posDiff = 0;
% negDiff = 0;
% for i = 2:length(const.load)
%     %check if rate of change is above pos limit
%     posDiff = runSolarBESS.netLoadSolar(i) - runSolarBESS.netLoadSolar(i-1);
%     if posDiff > const.posLoadChangeLim
%         %correct net-load
%         runSolarBESS.netLoadSolar(i) = runSolarBESS.netLoadSolar(i-1) + const.posLoadChangeLim;
%     end
%     
%     %check if rate of change is below neg limit
%     negDiff = runSolarBESS.netLoadSolar(i) - runSolarBESS.netLoadSolar(i-1);
%     if negDiff < const.negLoadChangeLim
%         %correct net-load
%         runSolarBESS.netLoadSolar(i) = runSolarBESS.netLoadSolar(i-1) - const.negLoadChangeLim;
%     end
% end




%determine the percent solar penetration into the grid
%const.energyLoad = sum(const.load,'omitnan')*1; -- this line moved to main
runSolarBESS.energySolar = sum(runSolarBESS.solarGen,'omitnan')*1;

%need to correct the energy output in case the total energy generated is
%above the annual energy consumption (i.e. cannot have negative net energy)
if runSolarBESS.energySolar > const.energyLoad
    runSolarBESS.energySolar = const.energyLoad;
end
    
runSolarBESS.percSolarPen = (runSolarBESS.energySolar/const.energyLoad)*100; %maximum of 100%

%determine total year 1 gains from solar generation, i.e. from offsetting
%cost of generation from power plant
hourGainsOfSolar = runSolarBESS.solarGen .* const.hourCostOfGen;
runSolarBESS.yrOneGainsSolar = sum(hourGainsOfSolar, 'omitnan');

%Debug
% disp("solar pennetration: ")
% disp(percSolarPen);

end

