function [runSolarBESS, runUpgrade] = runOptSimulation(const, runSolarBESS, runUpgrade)
%Runs the simulation to get all results for the optimal PV-ESS and Subst.
%Upgrade

%% calculations for solar-ESS
%run load with solar function
[runSolarBESS] = calcLoadWithSolar_opt(const, runSolarBESS);
%Run BESS function
if const.isLoadBasedBESS == 1 %determine type of charge-discharge algorithm
    [runSolarBESS] = BESSFunc3N_opt(const, runSolarBESS);
else
    [runSolarBESS] = RealBESStFunc_opt(const, runSolarBESS);
end
%calculate overloads for solar-BESS
[runSolarBESS] = calcOverloadsBESS_opt(const, runSolarBESS);
%run cost calculation for solar-BESS
[runSolarBESS] = calcCosts2BESS_opt(const, runSolarBESS);

%% calculations for substation upgrade
%determine overloads
[runUpgrade] = calcOverloadsUpgrade_opt(const, runUpgrade);
%determine costs
[runUpgrade] = calcCosts2Upgrade_opt(const, runUpgrade);
end

