clear all;
conn = mysql('open','localhost','root');
mysql('use pttest');

PatientIDs = mysql('SELECT DISTINCT fk_PatientID FROM volume_distance');

for i = 1: length(PatientIDs)

    patientID = PatientIDs{i,1};
    StructureSetSOPInstanceUID_cell=mysql(horzcat('SELECT fk_SOPInstanceUID from iod_structure_set WHERE fk_PatientID = "',patientID,'" AND fk_SOPClassUID = "1.2.840.10008.5.1.4.1.1.481.3"'));
    StructureSetSOPInstanceUID=StructureSetSOPInstanceUID_cell{1,1};

    ptvROINumber = mysql(horzcat('SELECT ROINumber FROM seq_structuresetroi WHERE fk_SOPInstanceUID = "',StructureSetSOPInstanceUID,'" AND ROIName="Prostate"'));
    ptv_dvh_id = mysql(horzcat('SELECT fk_dvh_id FROM seq_dvhreferencedroi WHERE fk_PatientID = "',patientID,'" AND ReferencedROINumber = "', num2str(ptvROINumber), '"'));
    PTV_DVHData_cell = mysql(horzcat('SELECT DVHData FROM seq_dvh WHERE fk_PatientID = "',patientID,'" AND dvh_id = "', num2str(ptv_dvh_id), '"'));
    PTV_DVHData=regexp(PTV_DVHData_cell{1,1},'/','split');

    ptv_d_cell = PTV_DVHData(1:2:length(PTV_DVHData));
    ptv_v_cell = PTV_DVHData(2:2:length(PTV_DVHData));

    ptv_d = zeros(length(PTV_DVHData)/2,1);
    ptv_v = zeros(length(PTV_DVHData)/2,1);

    for i = 1:length(PTV_DVHData)/2
        ptv_d(i)=str2double(ptv_d_cell{1,i});
        ptv_v(i)=str2double(ptv_v_cell{1,i})*100;
    end;

    ptvD25 = findX(ptv_d,ptv_v,25);
    ptvD50 = findX(ptv_d,ptv_v,50);
    ptvD60 = findX(ptv_d,ptv_v,60);
    ptvD75 = findX(ptv_d,ptv_v,75);
    ptvD90 = findX(ptv_d,ptv_v,90);
    ptvD95 = findX(ptv_d,ptv_v,95);

    ptv_d_str = strrep(mat2str(ptv_d),';',',');
    ptv_v_str = strrep(mat2str(ptv_v),';',',');

    mysql(horzcat('UPDATE volume_distance SET PTV_D25 = "',num2str(ptvD25),'", PTV_D50 = "',num2str(ptvD50),'", PTV_D60 = "',num2str(ptvD60),'", PTV_D75 = "',num2str(ptvD75),'", PTV_D90 = "',num2str(ptvD90),'", PTV_D95 = "',num2str(ptvD95),'", PTV_DVH_d = "',ptv_d_str,'", PTV_DVH_v = "',ptv_v_str, '" WHERE fk_PatientID = "',patientID,'" AND ROIName="Bladder"'));
    mysql(horzcat('UPDATE volume_distance SET PTV_D25 = "',num2str(ptvD25),'", PTV_D50 = "',num2str(ptvD50),'", PTV_D60 = "',num2str(ptvD60),'", PTV_D75 = "',num2str(ptvD75),'", PTV_D90 = "',num2str(ptvD90),'", PTV_D95 = "',num2str(ptvD95),'", PTV_DVH_d = "',ptv_d_str,'", PTV_DVH_v = "',ptv_v_str, '" WHERE fk_PatientID = "',patientID,'" AND ROIName="Rectum"'));

    % Bladder_DVH_d = Bladder_DVHData{1:2:length(Bladder_DVHData)};
    % Bladder_DVH_v = Bladder_DVHData{2:2:length(Bladder_DVHData)};
    % 
    % Rectum_DVH_d = Rectum_DVHData{1:2:length(Rectum_DVHData)};
    % Rectum_DVH_v = Rectum_DVHData{2:2:length(Rectum_DVHData)};
    % 
    % PTV_DVH_d = PTV_DVHData{1:2:length(PTV_DVHData)};
    % PTV_DVH_v = PTV_DVHData{2:2:length(PTV_DVHData)};
    
end

mysql('close');