clear all;
conn = mysql('open','localhost','root');
mysql('use pttest');


%[bladderMeanDistance bladderV50Distance bladderV75Distance bladderMedianDistance bladderModeDistance bladderD25 bladderD50 bladderD75 bladderD90 bladderMaxDose] = mysql('SELECT meanDistance, V50Distance, V75Distance, medianDistance, modeDistance, D25, D50, D75, D90, maxDose FROM volume_distance WHERE ROIName="Bladder"');
%[rectumMeanDistance rectumV50Distance rectumV75Distance rectumMedianDistance rectumModeDistance rectumD25 rectumD50 rectumD75 rectumD90 rectumMaxDose] = mysql('SELECT meanDistance, V50Distance, V75Distance, medianDistance, modeDistance, D25, D50, D75, D90, maxDose FROM volume_distance WHERE ROIName="Rectum"');

bladderAnatomicalFeatures = {'Mean of Bladder-PTV Distance (mm)' 'Bladder-PTV Mean Distance' 0; 'Distance b/w 50% of the Bladder and the PTV (mm)' 'Bladder R50' 0; 'Distance b/w 75% of the Bladder and the PTV (mm)' 'Bladder R75' 0; 'Median of Bladder-PTV Distance (mm)' 'Bladder-PTV Median Distance' 0; 'Mode of Bladder-PTV Distance (mm)' 'Bladder-PTV Mode Distance' 0};
bladderDoseFeatures = {'Dose to 25% of the Bladder (Gy)' 'Bladder D25' 0; 'Dose to 50% of the Bladder (Gy)' 'Bladder D50' 0; 'Dose to 75% of the Bladder (Gy)' 'Bladder D75' 0; 'Dose to 90% of the Bladder (Gy)' 'Bladder D90' 0; 'Maximum Dose to the Bladder (Gy)' 'Bladder MaxDose' 0};

rectumAnatomicalFeatures = {'Mean of Rectum-PTV Distance (mm)' 'Rectum-PTV Mean Distance' 0; 'Distance b/w 50% of the Rectum and the PTV (mm)' 'Rectum R50' 0; 'Distance b/w 75% of the Rectum and the PTV (mm)' 'Rectum R75' 0; 'Median of Rectum-PTV Distance (mm)' 'Rectum-PTV Median Distance' 0; 'Mode of Rectum-PTV Distance (mm)' 'Rectum-PTV Mode Distance' 0};
rectumDoseFeatures = {'Dose to 25% of the Rectum (Gy)' 'Rectum D25' 0; 'Dose to 50% of the Rectum (Gy)' 'Rectum D50' 0; 'Dose to 75% of the Rectum (Gy)' 'Rectum D75' 0; 'Dose to 90% of the Rectum (Gy)' 'Rectum D90' 0; 'Maximum Dose to the Rectum (Gy)' 'Rectum MaxDose' 0};

[bladderAnatomicalFeatures{1,3} bladderAnatomicalFeatures{2,3} bladderAnatomicalFeatures{3,3} bladderAnatomicalFeatures{4,3} bladderAnatomicalFeatures{5,3} bladderDoseFeatures{1,3} bladderDoseFeatures{2,3} bladderDoseFeatures{3,3} bladderDoseFeatures{4,3} bladderDoseFeatures{5,3}] = mysql('SELECT meanDistance, V50Distance, V75Distance, medianDistance, modeDistance, D25, D50, D75, D90, maxDose FROM volume_distance WHERE ROIName="Bladder"');
[rectumAnatomicalFeatures{1,3} rectumAnatomicalFeatures{2,3} rectumAnatomicalFeatures{3,3} rectumAnatomicalFeatures{4,3} rectumAnatomicalFeatures{5,3} rectumDoseFeatures{1,3} rectumDoseFeatures{2,3} rectumDoseFeatures{3,3} rectumDoseFeatures{4,3} rectumDoseFeatures{5,3}] = mysql('SELECT meanDistance, V50Distance, V75Distance, medianDistance, modeDistance, D25, D50, D75, D90, maxDose FROM volume_distance WHERE ROIName="Rectum"');

for i = 1:5
    for j=1:5
        figure1 = figure;
        scatter(bladderAnatomicalFeatures{i,3}, bladderDoseFeatures{j,3});
        xlabel(bladderAnatomicalFeatures{i,1});
        ylabel(bladderDoseFeatures{j,1});
        title(horzcat(bladderDoseFeatures{j,2},' vs ',bladderAnatomicalFeatures{i,2}));
        titleHandle = get(gca, 'title');
        set(titleHandle, 'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');
        xlabelHandle = get(gca, 'xlabel');
        set(xlabelHandle, 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold');
        ylabelHandle = get(gca, 'ylabel');
        set(ylabelHandle, 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold');
        saveas(figure1,horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/Results/ptAnalysis/',bladderDoseFeatures{j,2},' vs ',bladderAnatomicalFeatures{i,2}));
       
        figure2 = figure;
        scatter(rectumAnatomicalFeatures{i,3}, rectumDoseFeatures{j,3});
        xlabel(rectumAnatomicalFeatures{i,1});
        ylabel(rectumDoseFeatures{j,1});
        title(horzcat(rectumDoseFeatures{j,2},' vs ',rectumAnatomicalFeatures{i,2}));
        set(titleHandle, 'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold');
        xlabelHandle = get(gca, 'xlabel');
        set(xlabelHandle, 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold');
        ylabelHandle = get(gca, 'ylabel');
        set(ylabelHandle, 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold');
        saveas(figure2,horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/Results/ptAnalysis/',rectumDoseFeatures{j,2},' vs ',rectumAnatomicalFeatures{i,2}));
              
    end;
end

mysql('close');