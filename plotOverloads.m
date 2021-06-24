function plotOverloads(figNum,load,npCapacity,overloads,adjustedOverloads, isYearView, titleText)
%Plot net load, npCapacity, overloads/adjusted overloads
%   can select year view or month view, if isYearView = 0, sets bounds of
%   x-axis to be 2 weeks, or 336 hrs (centered on hour 4020, mid-year)

figure(figNum);
figure('Name','Overload Data')
npCapacity = ones(length(load),1).*npCapacity; %convert to constant vector

hold on;
if isYearView == 1
    axis([0 8040 0 130]);
else
    axis([3852 4188 0 130]);
end
plot(load,'b');
plot(npCapacity,':m');
plot(overloads, 'k');
plot(adjustedOverloads,'--r');

xlabel('Time in hours after 12 am 1/1/20');
ylabel('MW');
legend('Load','Nameplate Rating', 'Overloads', 'Overloads that may Cause Damage');
title(titleText);
xticks([0 744 1440 2184 2904 3648 4368 5112 5856 6576 7320 8040]);
xticklabels({'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'});
end

