function plotBESSData(figNum,netLoadBESS,powerOutBESS,energyBESS,isYearView)
%Plot data pertaining to BESS operation
%   can select year view or month view, if isYearView = 0, sets bounds of
%   x-axis to be 2 weeks, or 336 hrs (centered on hour 4020, mid-year)

figure(figNum);
figure('Name','BESS Data')

colororder({'k','b'});
hold on;
if isYearView == 1
    yyaxis left
    axis([0 8040 -15 130]);
    plot(netLoadBESS,'g');
    plot(powerOutBESS,'-k');
    ylabel('MW');
    
    yyaxis right
    axis([0 8040 0 200]);
    plot(energyBESS,'b','LineWidth',1.25);
    ylabel('MWh');
    
else
    yyaxis left
    axis([3852 4188 -15 130]);
    plot(netLoadBESS,'g');
    plot(powerOutBESS,'-k');
    ylabel('MW');
    
    yyaxis right
    axis([3852 4188 0 200]);
    plot(energyBESS,'b','LineWidth',1.25);
    ylabel('MWh');
end

xlabel('Time in hours after 12 am 1/1/20');
legend('Load w/ Solar and BESS','BESS Power Output', 'Energy Stored in BESS');
%title('BESS Power, Energy, and Net Load');
xticks([0 744 1440 2184 2904 3648 4368 5112 5856 6576 7320 8040]);
xticklabels({'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'});
end

