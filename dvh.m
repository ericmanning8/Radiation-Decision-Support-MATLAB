clear all;
patient_id=8;

conn = mysql('open','localhost','root');
mysql('use rt_test');

bladderROINumber=mysql(horzcat('SELECT ROINumber from structure_set_roi_sequence WHERE ROIName="Bladder" AND fk_patient_id="',num2str(patient_id),'"'));
rectumROINumber=mysql(horzcat('SELECT ROINumber from structure_set_roi_sequence WHERE ROIName="Rectum" AND fk_patient_id="',num2str(patient_id),'"'));
ptvROINumber=mysql(horzcat('SELECT ROINumber from structure_set_roi_sequence WHERE ROIName="PTV" AND fk_patient_id="',num2str(patient_id),'"'));

bladderDVH_id = mysql(horzcat('SELECT fk_dvh_sequence_id from dvh_referenced_roi_sequence WHERE ReferencedROINumber="',num2str(bladderROINumber),'" AND fk_patient_id="',num2str(patient_id),'"'));
rectumDVH_id = mysql(horzcat('SELECT fk_dvh_sequence_id from dvh_referenced_roi_sequence WHERE ReferencedROINumber="',num2str(rectumROINumber),'" AND fk_patient_id="',num2str(patient_id),'"'));
ptvDVH_id = mysql(horzcat('SELECT fk_dvh_sequence_id from dvh_referenced_roi_sequence WHERE ReferencedROINumber="',num2str(ptvROINumber),'" AND fk_patient_id="',num2str(patient_id),'"'));

bladderDVH = mysql(horzcat('SELECT DVHData from dvh_sequence WHERE id="',num2str(bladderDVH_id),'"'));
rectumDVH = mysql(horzcat('SELECT DVHData from dvh_sequence WHERE id="',num2str(rectumDVH_id),'"'));
ptvDVH = mysql(horzcat('SELECT DVHData from dvh_sequence WHERE id="',num2str(ptvDVH_id),'"'));

bladderDVHArray = bladderDVH{1,1};
rectumDVHArray  = rectumDVH{1,1};
ptvDVHArray = ptvDVH{1,1};

bladderDVHStripped = bladderDVHArray(2:(length(bladderDVHArray)-1));
rectumDVHStripped = rectumDVHArray(2:(length(rectumDVHArray)-1));
ptvDVHStripped = ptvDVHArray(2:(length(ptvDVHArray)-1));

bladderDVHCell = textscan(bladderDVHStripped,'%f','delimiter',',');
rectumDVHCell = textscan(rectumDVHStripped,'%f','delimiter',',');
ptvDVHCell = textscan(ptvDVHStripped,'%f','delimiter',',');

clear bladderDVH;
clear rectumDVH;
clear ptvDVH;

bladderDVH = bladderDVHCell{1,1};
rectumDVH = rectumDVHCell{1,1};
ptvDVH = ptvDVHCell{1,1};

bladderNumBins=length(bladderDVH)/2;
rectumNumBins=length(rectumDVH)/2;
ptvNumBins=length(ptvDVH)/2;

bladderVolume = zeros(bladderNumBins,1);
bladderDose = zeros(bladderNumBins,1);
rectumVolume = zeros(rectumNumBins,1);
rectumDose = zeros(rectumNumBins,1);
ptvVolume = zeros(ptvNumBins,1);
ptvDose = zeros(ptvNumBins,1);

for i=2:2:(bladderNumBins*2)
    bladderVolume(i/2)=bladderDVH(i);
    bladderDose(i/2)=bladderDVH(i-1);
end;

for i=2:2:(rectumNumBins*2)
    rectumVolume(i/2)=rectumDVH(i);
    rectumDose(i/2)=rectumDVH(i-1);
end;

for i=2:2:(ptvNumBins*2)
    ptvVolume(i/2)=ptvDVH(i);
    ptvDose(i/2)=ptvDVH(i-1);
end;

bladderCumDose = cumsum(bladderDose);
bladderCumVolume = ((flipdim(cumsum(flipdim(bladderVolume,1)),1))/(sum(bladderVolume)))*100;
rectumCumDose = cumsum(rectumDose);
rectumCumVolume = ((flipdim(cumsum(flipdim(rectumVolume,1)),1))/(sum(rectumVolume)))*100;
ptvCumDose = cumsum(ptvDose);
ptvCumVolume = ((flipdim(cumsum(flipdim(ptvVolume,1)),1))/(sum(ptvVolume)))*100;

figure;
bladderPlot = plot(bladderCumDose, bladderCumVolume, '-r');
ylim([1 105])
set(bladderPlot,'LineWidth',1.5)
hold on;
rectumPlot = plot(rectumCumDose, rectumCumVolume, '-g');
ylim([1 105])
set(rectumPlot,'LineWidth',1.5)
hold on;
ptvPlot = plot(ptvCumDose, ptvCumVolume,'-b');
ylim([1 105])
set(ptvPlot,'LineWidth',1.5)
legend('Bladder','Rectum','PTV','Location','BestOutside');

bladderD50 = findX(bladderCumDose,bladderCumVolume,50);
bladderD75 = findX(bladderCumDose,bladderCumVolume,75);
bladderD90 = findX(bladderCumDose,bladderCumVolume,90);

rectumD50 = findX(rectumCumDose,rectumCumVolume,50);
rectumD75 = findX(rectumCumDose,rectumCumVolume,75);
rectumD90 = findX(rectumCumDose,rectumCumVolume,90);

ptvD50 = findX(ptvCumDose,ptvCumVolume,50);
ptvD75 = findX(ptvCumDose,ptvCumVolume,75);
ptvD90 = findX(ptvCumDose,ptvCumVolume,90);

% mysql(horzcat('UPDATE volume_distance SET D50="',num2str(bladderD50),'", D75="',num2str(bladderD75),'", D90="',num2str(bladderD90),'" WHERE fk_patient_id="',num2str(patient_id),'" AND ROIName="Bladder"'));
% mysql(horzcat('UPDATE volume_distance SET D50="',num2str(rectumD50),'", D75="',num2str(rectumD75),'", D90="',num2str(rectumD90),'" WHERE fk_patient_id="',num2str(patient_id),'" AND ROIName="rectum"'));
% %mysql(horzcat('UPDATE volume_distance SET D50="',num2str(ptvD50),'", D75="',num2str(ptvD75),'", D90="',num2str(ptvD90),'" WHERE fk_patient_id="',num2str(patient_id),'" AND ROIName="ptv"'));

mysql('close');