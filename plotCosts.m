function plotCosts(figNum,costsCO2BESS,costsCO2Upgrade,costsUSDBESS,costsUSDUpgrade,title1Text,title2Text)
%Plot costs in CO2 and USD over years

figure(figNum);
figure('Name','Cost Data')
%colororder({'k','b'});

%yyaxis left;
subplot(2,1,1);
hold on;
%axis([0 30 -50000 50000])
plot(costsCO2BESS, 'g--o');
plot(costsCO2Upgrade, 'r--o');
plot(zeros(30,1),'k--'); %add horizontal line on zero

ax = gca;
ax.FontSize = 13;
ylabel('kg CO2');
xlabel('Years');
legend('CO2 emissions BESS','CO2 emissions subst. upgrade','Location','northwest');
title(title1Text);

%yyaxis right;
subplot(2,1,2);
hold on;
%axis([0 30 0 5E8])
plot(costsUSDBESS./1000000, 'g:*');
plot(costsUSDUpgrade./1000000, 'r:*');
plot(zeros(30,1),'k--'); %add horizontal line on zero

ax = gca;
ax.FontSize = 13;
ylabel('Million USD');
xlabel('Years');
legend('USD costs BESS','USD costs subst. upgrade','Location','northwest');
title(title2Text);

end

