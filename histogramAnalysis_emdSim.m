clear all;

conn = mysql('open','localhost','root');
mysql('use pt_pr_v3');
roiName='rectum';
roiProperName = 'Rectum';

[emd sim] = mysql(horzcat('SELECT emd, sim FROM ',roiName,'Pairwise'));

figure(1)
xvalues=2.5:2.5:160;
hist(emd,xvalues);
title(roiProperName);
h = findobj(gca,'Type','patch');
set(h,'FaceColor',[0 .5 .5],'EdgeColor','w');
xlim([0 165]);
xlabel('Earth Mover''s Distance');
ylabel('Number of Pairs');
saveas(figure(1),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/pairwiseDistributions/emd/',roiName,'.png'));
disp(horzcat(num2str(mean(emd)),' ',num2str(std(emd)),' ',num2str(prctile(emd,5))));

figure(2);
xvalues=0.025:0.025:1;
hist(sim,xvalues);
title(roiProperName);
h = findobj(gca,'Type','patch');
set(h,'FaceColor',[0 .5 .5],'EdgeColor','w');
xlim([0 1]);
xlabel('Orientation Similarity');
ylabel('Number of Pairs');
saveas(figure(2),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/pairwiseDistributions/sim/',roiName,'.png'));
disp(horzcat(num2str(mean(sim)),' ',num2str(std(sim)),' ',num2str(prctile(sim,95))));
