
function emdValue = PR_emdCalculator(patient1, patient2, roiName)

[queryDistance1 queryVolume1] = mysql(horzcat('SELECT ovhDistance, ovhVolume FROM structure_set_roi_sequence WHERE fk_PatientID=',num2str(patient1),' AND ROIName LIKE "',roiName,'%"'));
[queryDistance2 queryVolume2] = mysql(horzcat('SELECT ovhDistance, ovhVolume FROM structure_set_roi_sequence WHERE fk_PatientID=',num2str(patient2),' AND ROIName LIKE "',roiName,'%"'));

distance1 = regexp(queryDistance1{1},',','split');
distance1{1}=distance1{1}(2:length(distance1{1}));
distance1{length(distance1)}=distance1{length(distance1)}(1:length(distance1{length(distance1)})-1);
distance1=str2double(distance1);
volume1 = regexp(queryVolume1{1},',','split');
volume1{1}=volume1{1}(2:length(volume1{1}));
volume1{length(volume1)}=volume1{length(volume1)}(1:length(volume1{length(volume1)})-1);
volume1=str2double(volume1);
ovh1 = [distance1' volume1'];

distance2 = regexp(queryDistance2{1},',','split');
distance2{1}=distance2{1}(2:length(distance2{1}));
distance2{length(distance2)}=distance2{length(distance2)}(1:length(distance2{length(distance2)})-1);
distance2=str2double(distance2);
volume2 = regexp(queryVolume2{1},',','split');
volume2{1}=volume2{1}(2:length(volume2{1}));
volume2{length(volume2)}=volume2{length(volume2)}(1:length(volume2{length(volume2)})-1);
volume2=str2double(volume2);
ovh2 = [distance2' volume2'];           

%********************************* CALCULATE EMD ********************************
w1=ones(length(ovh1),1);
w2=ones(length(ovh2),1);
[x emdValue] = emd(ovh1, ovh2, w1, w2, @gdf);
%**********************************************************************************

end