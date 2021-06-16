function netLoad = calcLoadWithSolar(load,solarGen)
%calculates the load with solar generation applied
netLoad = load-solarGen;
netLoad(netLoad<0) = 0;
end

