function plotCosts(figNum,costsCO2BESS,costsCO2Upgrade,costsUSDBESS,costsUSDUpgrade)
%Plot costs in CO2 and USD over years

figure(figNum);
figure('Name','Cost Data')
colororder({'k','g'});
hold on;

yyaxis left;
plot(costsCO2BESS, 'b--o');
plot(costsCO2Upgrade, 'r--o');
ylabel('Tons CO2');

yyaxis right;
plot(costsUSDBESS, 'c:*');
plot(costsUSDUpgrade, 'm:*');
ylabel('US Dollars')
xlabel('Years');

legend('CO2 emissions BESS','CO2 emissions subst. upgrade','USD costs BESS','USD costs subst. upgrade');
%title('Costs in CO2 Emissions and USD');
end

