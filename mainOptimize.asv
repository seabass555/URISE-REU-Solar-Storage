clc;
close all;
clear;
%%%general main function for the optimization

%list of variables, save as a struct format
% -"const."* "opt."** "runSolarBESS."*** "runUpgrade."****
    % (other option instead of "results.", have two structs, one for running simulation for solar+BESS, another for running
    % it with rhe substation upgrade.)
% -all constants and input data arrays (remain unchaged)*
% Calculated once initially:*
% -overload costs for status quo
% -...
% Generated prior to optimizing:**
% -2d matrix for solar capacity
% -2d matrix for BESS capacity
% -2d matrix for solar-BESS NPV results (via running simulation)
% -1d array for substation upgrade
% -1d array for substation upgrade NPV results (via running simulation)
% Changed between each run: (can omit some when doing substation
% upgrade)***/****
% -solar generation
% -all net loads
% -BESS outputs
% -...
% Generated after optimization:***/****
% -Solar+BESS data from best run
% -Substation upgrade data from best run

%load input data

%check for errors, display input data as load and 1MW solar
%potential errors: data entered wrong, or as NaN, constants set to wrong
%values that may cause errors.

%% initalize "opt." from inputs

%demo input data
solarCapMin = 0;
solarCapMax = 100;
BESSCapMin = 10;
BESSCapMax = 300;
upgradeMin = 0;
upgradeMax = 20;

deltaSolarCap = 10; %10MW difference
deltaBESSCap = 10; %10MWh difference between cases
deltaUpgrade = 1; %difference of 1MW between subst. upgrade cases

%compute arrays: (alternatively, could replace with linspace, and have a
%total number of test cases specified)
%will also need to add a condition in the case that the user manually
%enteres the cases
solarCapacity = solarCapMin:deltaSolarCap:solarCapMax;
BESSCapacity = BESSCapMin:deltaBESSCap:BESSCapMax;
solar_maxi = length(solarCapacity);
BESS_maxi = length(BESSCapacity);

opt.substUpgrade = upgradeMin:deltaUpgrade:upgradeMax;
upgrade_maxi = length(opt.substUpgrade);

%compute matricies for solar and BESS
%assume solar as x-axis, BESS and y-axis
[opt.solarCapacity, opt.BESSCapacity] = meshgrid(solarCapacity, BESSCapacity);

%display estimated runtime...


%% run simulation
%pre-calculate anything that only needs to run once
    %




% -calculate 30 year NPV for each run, store in opt. , use for loop

for solar_i = 1:solar_maxi
    for BESS_i = 1:BESS_maxi
        %run simulation for solar+BESS, store variables in runSolarBESS.
        runSolarBESS.sizeSolar = 
        runSolarBESS.sizeBESS = 
        
    end
end

for upgrade_i = 1:upgrade_maxi
    %run simulation for substation upgrade, store vars in runUpgrade.
    %omit BESS+Solar calculations for these
end

    %note: may be able to improve program in a few ways
    %omit BESS+Solar function from substation upgrade calculations
    %calculate all status-quo costs prior to for loop (e.g. in calcCosts,
    %overloads, total energy, etc.)
    %remove calculation of any unused variables, such as adjustedOverloads
% -identify maximum NPV
% -idenfity the best case substation upgrade, solar & BESS capacity


%DEMO run - arbitrary NPV
opt.NPVSolarAndBESS = -((opt.solarCapacity-60).^2 + opt.BESSCapacity.^2);
opt.NPVSubstUpgrade = 10 - opt.substUpgrade.^2;

%calculate maximum NPV
[opt] = calcMaxNPV(opt);

%graph data and return results
subplot(2,1,1);
mesh(opt.solarCapacity, opt.BESSCapacity, opt.NPVSolarAndBESS); %will need to add condition for corner cases here
xlabel("solar capacity (MW)");
ylabel("BESS capacity (MWh)");
zlabel("NPV");
subplot(2,1,2);
plot(opt.substUpgrade, opt.NPVSubstUpgrade);
xlabel("substation upgrade (MW)");
ylabel("NPV");

disp("optimal BESS capacity and Solar Capacity:");
disp(opt.optBESS);
disp(opt.optSolar);
disp("optimal substation upgrade:");
disp(opt.optUpgrade);

%DEMO finding maximum value and point
% [data.x,data.y] = meshgrid(-10:10,-10:10);
%disp(data.x);
%disp(data.y);
% data.z = -((data.x-2).^2 + (data.y-3).^2);
% mesh(data.x,data.y,data.z); %corner case, single data point or 1d vector will give error here
% [maxes,y_ar] = max(data.z);
% disp("y max index");
% disp(y_ar);
% [max,x_i] = max(maxes);
% disp("max");
% disp(max);
% disp("x max index");
% disp(x_i);
% disp("y max index");
% y_i = y_ar(x_i);
% disp(y_i);
% disp("max from indeces");
% disp(data.z(y_i,x_i));
% disp("x, y from indeces");
% disp(data.x(y_i,x_i));
% disp(data.y(y_i,x_i));
% xlabel("x axis");
% ylabel("y axis");


%run simulation for best 2 cases, popluate data in results.
%display results from best 2 runs, display NPV optimization graphs




