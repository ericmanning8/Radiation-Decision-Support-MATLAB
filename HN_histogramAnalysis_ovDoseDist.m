clear all;

conn = mysql('open','localhost','root');
mysql('use rt_hn_v6');
roiName='parotidLt';
roiProperName = 'Left Parotid';

[overlap distanceMean doseMean] = mysql(horzcat('SELECT PercentageOverlap_ROI_Fraction_ptv1, DistanceMean_ptv1, doseMean FROM structure_set_roi_sequence_copy WHERE stdROIName = "',roiName,'" AND fk_patient_id NOT LIKE "2" AND fk_patient_id NOT LIKE "9" AND fk_patient_id NOT LIKE "21" AND fk_patient_id NOT LIKE "39"'));

% Overlap
figure(1)
xvalues=2.5:5:100;
hist(overlap,xvalues);
title(roiProperName);
h = findobj(gca,'Type','patch');
set(h,'FaceColor',[0 .5 .5],'EdgeColor','w');
xlim([0 100]);
xlabel('Overlap with the PTV');
ylabel('Number of Pairs');
saveas(figure(1),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/pairwiseDistributions/overlap/',roiName,'.png'));
disp(horzcat(num2str(round(mean(overlap)*1000)/1000),';   ',num2str(round(std(overlap)*1000)/1000)));

% Mean Distance
figure(2);
xvalues=5:10:168;
hist(distanceMean,xvalues);
title(roiProperName);
h = findobj(gca,'Type','patch');
set(h,'FaceColor',[0 .5 .5],'EdgeColor','w');
xlim([0 168]);
xlabel('Mean Distance to the PTV');
ylabel('Number of Pairs');
saveas(figure(2),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/pairwiseDistributions/distance/',roiName,'.png'));
disp(horzcat(num2str(round(mean(distanceMean)*100)/100),';   ',num2str(round(std(distanceMean)*100)/100)));

% Mean Dose
figure(3);
xvalues=2.5:5:72;
hist(doseMean,xvalues);
title(roiProperName);
h = findobj(gca,'Type','patch');
set(h,'FaceColor',[0 .5 .5],'EdgeColor','w');
xlim([0 72]);
xlabel('Mean Dose to the ROI');
ylabel('Number of Pairs');
saveas(figure(3),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/pairwiseDistributions/dose/',roiName,'.png'));
disp(horzcat(num2str(round(mean(doseMean)*100)/100),';   ',num2str(round(std(doseMean)*100)/100)));
