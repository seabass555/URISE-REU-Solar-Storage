function plotSolarBESSLoad(figNum,load,netLoadSolar,netLoadBESS,solarGen,powerOutBESS, isYearView, titleText)
%Plot solar gen, net loads, BESS power out
%   can select year view or month view, if isYearView = 0, sets bounds of
%   x-axis to be 2 weeks, or 336 hrs (centered on hour 4020, mid-year)

figure(figNum);
figure('Name','Solar, BESS, and Load Data')
hold on;

if isYearView == 1
    axis([0 8040 -15 130]);
else
    axis([3852 4188 -15 130]);
end
plot(load,'b');
plot(netLoadSolar, ':r','LineWidth',1.5);
plot(netLoadBESS, 'g');
plot(powerOutBESS,'k');
if isYearView == 1
    plot(solarGen,'y');
else
    plot(solarGen,'y','LineWidth',2);
end

ax = gca;
ax.FontSize = 20;
xlabel('Time in hours after 12 am 1/1/20');
ylabel('MW');
legend('Baseline Load', 'Load w/ Solar','Load w/ Solar and Storage','BESS Power Output','Solar Generation');
title(titleText);
xticks([0 744 1440 2184 2904 3648 4368 5112 5856 6576 7320 8040]);
xticklabels({'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'});
end

