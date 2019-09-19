
function d = chiforOVH(patient1, patient2, roiName)

[queryDose1, queryVolume1] = mysql(horzcat('SELECT ovhDistance_ptv1, ovhVolume_ptv1 FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(patient1),' AND stdROIName="',roiName,'"'));
[queryDose2, queryVolume2] = mysql(horzcat('SELECT ovhDistance_ptv1, ovhVolume_ptv1 FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(patient2),' AND stdROIName="',roiName,'"'));

distance1 = regexp(queryDose1{1},',','split');
distance1{1}=distance1{1}(2:length(distance1{1}));
distance1{length(distance1)}=distance1{length(distance1)}(1:length(distance1{length(distance1)})-1);
distance1=str2double(distance1);
volume1 = regexp(queryVolume1{1},',','split');
volume1{1}=volume1{1}(2:length(volume1{1}));
volume1{length(volume1)}=volume1{length(volume1)}(1:length(volume1{length(volume1)})-1);
volume1=str2double(volume1);

distance2 = regexp(queryDose2{1},',','split');
distance2{1}=distance2{1}(2:length(distance2{1}));
distance2{length(distance2)}=distance2{length(distance2)}(1:length(distance2{length(distance2)})-1);
distance2=str2double(distance2);
volume2 = regexp(queryVolume2{1},',','split');
volume2{1}=volume2{1}(2:length(volume2{1}));
volume2{length(volume2)}=volume2{length(volume2)}(1:length(volume2{length(volume2)})-1);
volume2=str2double(volume2);
       
%********************************* UNIQUE ********************************

if length(distance1)~=length(unique(distance1))
    [distance1_unique,uniqueIndices,temp]=unique(distance1);
    volume1=volume1(uniqueIndices);
    distance1=distance1_unique;
end

if length(distance2)~=length(unique(distance2))
    [distance2_unique,uniqueIndices,temp]=unique(distance2);
    volume2=volume2(uniqueIndices);
   distance2=distance2_unique;
end

%**********************************************************************************

%********************************* CALCULATE CHI SQUARED DISTANCE ********************************

regVolume = interp1(distance2,volume2,distance1,'linear','extrap');
num=(volume1-regVolume).^2;
den=abs(volume1+regVolume);
d=sum(num./den)/2;

%**********************************************************************************

end