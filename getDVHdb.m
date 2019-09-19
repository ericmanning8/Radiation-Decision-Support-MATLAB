function [dvhDose, dvhVolume] = getDVHdb(patient_id,roiName)

%conn_getDVH = mysql('open','localhost','root');
mysql('use rt_hn_v6');

[dvhDose dvhVolume] = mysql(horzcat('SELECT dvhDose, dvhVolume FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(patient_id),' AND stdROIName="',roiName,'"'));
dvhDose = regexp(dvhDose{1,1},',','split');
dvhDose{1}=dvhDose{1}(2:length(dvhDose{1}));
dvhDose{length(dvhDose)}=dvhDose{length(dvhDose)}(1:length(dvhDose{length(dvhDose)})-1);
dvhDose=str2double(dvhDose);
dvhVolume = regexp(dvhVolume{1,1},',','split');
dvhVolume{1}=dvhVolume{1}(2:length(dvhVolume{1}));
dvhVolume{length(dvhVolume)}=dvhVolume{length(dvhVolume)}(1:length(dvhVolume{length(dvhVolume)})-1);
dvhVolume=str2double(dvhVolume);

%clear conn_getDVH;

end