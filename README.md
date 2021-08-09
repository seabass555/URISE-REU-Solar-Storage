# URISE-REU-Solar-Storage
In this repository you will find the matlab files and data used for the solar-storage group's 2021 URISE project.

Data Files:
* 2020DemandandSolar-Sheet1.csv contains data used in Case Study 1. Column 5 = load, Column 9 = solar gen. data.
* MT2020SolarandDemand.csv contains data used in Case Study 2. Column 6 = load, Column 9 = solar gen. data.
* note: Additional spreadsheets exist for unused data-sets and data prior to formating in the later two mentioned .csv files

MATLAB Files (used in backend/optimization code):
* mainOptimize.m is the "main" file for running a single optimization. It contains all code neccesary to run an optimization outside of the GUI,
  including assignment of default values. Data files mentioned above can be   loaded into mainOptimize.m by assigning arrays to the columns in the .csv   file. This file also generates all graphs as pop-up windows.
  * runOptimization.m is a function called within mainOptimize.m which runs the optimization process.
    * calcOverloadsOrig_opt.m is a function to determine original grid overloads prior to optimization.
    * calcLoadWithSolar_opt.m is a function to determine net-load with solar applied and energy generated by solar.
    * BESSFunc3N_opt.m is the load based ESS control algorithm
    * RealBESStFunc_opt.m is the time based ESS control algorithm
    * calcOverloadsBESS_opt.m is a function to determine grid overloads for PV-ESS simulations
    * calcCosts2BESS_opt.m is the cost-benefit analysis function for PV-ESS simulations
    * calcOverloadsUpgrade_opt.m is the function to determine overloads for substation upgrade simulations
    * calcCosts2Upgrade_opt.m is the cost-benefit analysis function used for substation upgrade simulations
    * calcMaxNPV.m is a function to determine the maximum NPV values for PV-ESS and substation upgrade and identify the optimal sized installations for each based on generated data.
  * runOptSimulation.m is a function that runs a PV-ESS and substation upgrade simulation after determining optimal parameters.
  * plotSolarBESSLoad.m is a function to graph solar data, ESS discharge, and net-load(s)
  * plotOverloads2.m is a function to graph net-load and overloads
  * plotBESSData.m is a function to graph ESS power output, energy over time, and net-load
  * plotCosts.m is a function to graph CO2-eq emissions and finanical returns/NPV on a subplot
  * Note: additional functions/files exist in the repository which correspond to outdated files we used in the inital stages of our research.

Files used for the GUI:
  * CurrentGUI.mlapp contains the current version of the GUI without a formatted 'Home' tab
  * CurrentGUIHomeTab.mlapp contains the current version of the 'Home' tab. All other content is antiquated. CurrentGUI.mlapp and CurrentGUIHomeTab.mlapp will be combined in the near future


Acknowledgement and Disclaimer:
* The REU students would like to thank the University of Michigan-Dearborn faculty who guided us in our project, namely Profs. Samir Rawadesh, Wencong Su, Lin Van Nieuwstadt, and Antonios Koumpias and UM-Dearborn graduate student Danial Farrugia. We would also like to thank our contacts at DTE, who provided us with industry insight: Michael Witkowski, Vielka Hernandez, Eric Klug, and Christopher Gorman.
* The work was in part supported by the U.S. National Science Foundation under Award #1757522. Any opinions, findings and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.
