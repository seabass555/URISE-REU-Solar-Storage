function [runSolarBESS] = calcLoadWithSolar_opt(const, runSolarBESS)
%calculates the load with solar generation applied
%also returns the solar pennetration and year 1 energy for baseline load and solar gen.
%inputs: const.load, const.solarGen1MW, runSolarBESS.sizeSolar
%outputs: runSolarBESS.netLoadSolar,runSolarBESS.solarGen,runSolarBESS.energySolar,runSolarBESS.percSolarPen

runSolarBESS.solarGen = const.solarGen1MW .* runSolarBESS.sizeSolar;
runSolarBESS.netLoadSolar = const.load-runSolarBESS.solarGen;
runSolarBESS.netLoadSolar(runSolarBESS.netLoadSolar<0) = 0;

%determine the percent solar penetration into the grid
%const.energyLoad = sum(const.load,'omitnan')*1; -- this line moved to main
runSolarBESS.energySolar = sum(runSolarBESS.solarGen,'omitnan')*1;
runSolarBESS.percSolarPen = (runSolarBESS.energySolar/const.energyLoad)*100;

%Debug
% disp("solar pennetration: ")
% disp(percSolarPen);

end

