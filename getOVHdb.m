function [ovhDose, ovhVolume] = getOVHdb(patient_id,roiName)

%conn_getDVH = mysql('open','localhost','root');
mysql('use rt_hn_v6');

[ovhDose ovhVolume] = mysql(horzcat('SELECT ovhDistance_ptv1, ovhVolume_ptv1 FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(patient_id),' AND stdROIName="',roiName,'"'));
ovhDose = regexp(ovhDose{1,1},',','split');
ovhDose{1}=ovhDose{1}(2:length(ovhDose{1}));
ovhDose{length(ovhDose)}=ovhDose{length(ovhDose)}(1:length(ovhDose{length(ovhDose)})-1);
ovhDose=str2double(ovhDose);
ovhVolume = regexp(ovhVolume{1,1},',','split');
ovhVolume{1}=ovhVolume{1}(2:length(ovhVolume{1}));
ovhVolume{length(ovhVolume)}=ovhVolume{length(ovhVolume)}(1:length(ovhVolume{length(ovhVolume)})-1);
ovhVolume=str2double(ovhVolume);

%clear conn_getDVH;

end