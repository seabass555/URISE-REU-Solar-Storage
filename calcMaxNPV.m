function [opt] = calcMaxNPV(opt)
%Calculates the values to maximize NPV for solar/BESS capacity and
%substation upgeade.
%Solar and BESS capacity are in 2x2 maxtrix, along with Pv-BESS NPV
%Subst. upgrade and NPV are single dimension arrays

solar = opt.solarCapacity;
BESS = opt.BESSCapacity;
NPVBESS = opt.NPVSolarAndBESS;
upgrade = opt.substUpgrade;
NPVUpgrade = opt.NPVSubstUpgrade;
%assume solar is x-axis, BESS is y-axis

%[data.x,data.y] = meshgrid(-10:10,-10:10);
%data.z = -((data.x-2).^2 - (data.y-3).^2);
%mesh(data.x,data.y,data.z); %corner case, single data point or 1d vector will give error here
% [maxes,y_ar] = max(data.z);
% [max,x_i] = max(maxes);
% y_i = y_ar(x_i);

%determine maximum NPV for solar and BESS, along with optimal solar/BESS
%capacity
[maxvals_NPVBESS, optBESS_inds] = max(NPVBESS);
[max_NPVBESS, optSolar_i] = max(maxvals_NPVBESS);
optBESS_i = optBESS_inds(optSolar_i);
optSolarCapacity = solar(optBESS_i, optSolar_i);
optBESSCapacity = BESS(optBESS_i, optSolar_i);

%determine max NPV for upgrade and optimal upgrade
[max_NPVUpgrade, optUpgrade_i] = max(NPVUpgrade);
optUpgrade = upgrade(optUpgrade_i);


%save in struct
opt.optSolar_i = optSolar_i;
opt.optBESS_i = optBESS_i;
opt.optUpgrade_i = optUpgrade_i;
opt.optSolar = optSolarCapacity;
opt.optBESS = optBESSCapacity;
opt.maxNPVBESS = max_NPVBESS;
opt.optUpgrade = optUpgrade;
opt.maxNPVUpgrade = max_NPVUpgrade;
end

