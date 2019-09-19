clear all;
conn = mysql('open','localhost','root');
mysql('use pttest');

PatientIDs = mysql('SELECT DISTINCT fk_PatientID FROM volume_distance');

for i = 1: length(PatientIDs)
    StructureSetSOPInstanceUID_cell=mysql(horzcat('SELECT fk_SOPInstanceUID from iod_structure_set WHERE fk_PatientID = "',PatientIDs{i,1},'" AND fk_SOPClassUID = "1.2.840.10008.5.1.4.1.1.481.3"'));
    StructureSetSOPInstanceUID=StructureSetSOPInstanceUID_cell{1,1};
    
    BladderROINumber = mysql(horzcat('SELECT ROINumber FROM seq_structuresetroi WHERE fk_SOPInstanceUID = "',StructureSetSOPInstanceUID,'" AND ROIName="Bladder"'));
    RectumROINumber = mysql(horzcat('SELECT ROINumber FROM seq_structuresetroi WHERE fk_SOPInstanceUID = "',StructureSetSOPInstanceUID,'" AND ROIName="Rectum"'));
   % ptvROINumber = mysql(horzcat('SELECT ROINumber FROM seq_structuresetroi WHERE fk_SOPInstanceUID = "',StructureSetSOPInstanceUID,'" AND ROIName="Prostate"'));

    bladder_dvh_id = mysql(horzcat('SELECT fk_dvh_id FROM seq_dvhreferencedroi WHERE fk_PatientID = "',PatientIDs{i,1},'" AND ReferencedROINumber = "', num2str(BladderROINumber), '"'));
    rectum_dvh_id = mysql(horzcat('SELECT fk_dvh_id FROM seq_dvhreferencedroi WHERE fk_PatientID = "',PatientIDs{i,1},'" AND ReferencedROINumber = "', num2str(RectumROINumber), '"'));
    %ptv_dvh_id = mysql(horzcat('SELECT fk_dvh_id FROM seq_dvhreferencedroi WHERE fk_PatientID = "',PatientIDs{i,1},'" AND ReferencedROINumber = "', num2str(ptvROINumber), '"'));
    
    [bladderMin bladderMax bladderMean] = mysql(horzcat('SELECT DVHMinimumDose, DVHMaximumDose, DVHMeanDose FROM seq_dvh WHERE dvh_id = "',num2str(bladder_dvh_id),'"'));
    [rectumMin rectumMax rectumMean] = mysql(horzcat('SELECT DVHMinimumDose, DVHMaximumDose, DVHMeanDose FROM seq_dvh WHERE dvh_id = "',num2str(rectum_dvh_id),'"'));
    %[ptvMin ptvMax ptvMean] = mysql(horzcat('SELECT DVHMinimumDose, DVHMaximumDose, DVHMeanDose FROM seq_dvh WHERE dvh_id = "',num2str(ptv_dvh_id),'"'));

    mysql(horzcat('UPDATE volume_distance SET meanDose = "',num2str(bladderMean),'", minDose = "',num2str(bladderMin),'", maxDose = "',num2str(bladderMax),'" WHERE fk_PatientID = "',PatientIDs{i,1},'" AND ROIName = "Bladder"'));
    mysql(horzcat('UPDATE volume_distance SET meanDose = "',num2str(rectumMean),'", minDose = "',num2str(rectumMin),'", maxDose = "',num2str(rectumMax),'" WHERE fk_PatientID = "',PatientIDs{i,1},'" AND ROIName = "Rectum"'));
    %mysql(horzcat('UPDATE volume_distance SET meanDose = "',num2str(bladderMean),'", minDose = "',num2str(bladderMin),'", maxDose = "',num2str(bladderMax),'" WHERE fk_PatientID = "',PatientIDs{i,1},'" AND ROIName = ""'));
end;

mysql('close');