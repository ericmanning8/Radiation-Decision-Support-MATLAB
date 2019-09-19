close all;
clear all;
roiName = 'parotidRt';
load parotidRt.mat

e = result(:,3);

[height emdValues]=hist(e,100);
pdf=cumsum(height/sum(height));
threshold = findX(emdValues,pdf,0.95);
numBelowThreshold = length(e)-length(e)*0.95;
figure;
plot(emdValues,pdf);
xlabel('EMD');
ylabel('Probability');
saveas(figure(1),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/pairwiseDistributions/',roiName,'_emd_pdf.png'));

figure;
hist(e,100);
xlabel('EMD');
ylabel('Number of pairs');
saveas(figure(2),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/pairwiseDistributions/',roiName,'_emd_histogram.png'));

%close all;
