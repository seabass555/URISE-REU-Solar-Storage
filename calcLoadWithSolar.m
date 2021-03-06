function [netLoadSolar,solarGen,energyLoad,energySolar,percSolarPen] = calcLoadWithSolar(load, solarGen1MW, powerCap)
%calculates the load with solar generation applied
%also returns the solar pennetration and year 1 energy for baseline load and solar gen.
solarGen = solarGen1MW.*powerCap;
netLoadSolar = load-solarGen;
netLoadSolar(netLoadSolar<0) = 0;

%determine the percent solar penetration into the grid
energyLoad = sum(load,'omitnan')*1;
energySolar = sum(solarGen,'omitnan')*1;
percSolarPen = (energySolar/energyLoad)*100;

%Debug
% disp("solar pennetration: ")
% disp(percSolarPen);

end

