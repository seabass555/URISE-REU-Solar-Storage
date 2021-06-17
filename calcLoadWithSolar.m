function [netLoadSolar,solarGen] = calcLoadWithSolar(load,solarGen1MW, powerCap)
%calculates the load with solar generation applied
solarGen = solarGen1MW.*powerCap;
netLoadSolar = load-solarGen;
netLoadSolar(netLoadSolar<0) = 0;
end

