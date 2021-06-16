%get data for solar generation
solarGen = HomesteadFL1MWData.ACSystemOutputW;

%select month of july and scale for 20MW
solarGen = 20.*solarGen(4345:5088)/1000000;

%import load data
load = July2020GridDemandHomesteadFL.DemandMWh;
load = load(1:(end-1));

%make array for time in hours
t = 1:length(solarGen);

%test: plot solarGen and load (Y axis is MW)
plot(t, solarGen)
hold on
plot(t, load)
plot(t, load-solarGen)
