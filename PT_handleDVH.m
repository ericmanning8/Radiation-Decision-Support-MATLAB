clear all;
patientID = '06248720';
conn = mysql('open','localhost','root');
mysql('use pttest');

StructureSetSOPInstanceUID_cell=mysql(horzcat('SELECT fk_SOPInstanceUID from iod_structure_set WHERE fk_PatientID = "',patientID,'" AND fk_SOPClassUID = "1.2.840.10008.5.1.4.1.1.481.3"'));
StructureSetSOPInstanceUID=StructureSetSOPInstanceUID_cell{1,1};

BladderROINumber = mysql(horzcat('SELECT ROINumber FROM seq_structuresetroi WHERE fk_SOPInstanceUID = "',StructureSetSOPInstanceUID,'" AND ROIName="Bladder"'));
RectumROINumber = mysql(horzcat('SELECT ROINumber FROM seq_structuresetroi WHERE fk_SOPInstanceUID = "',StructureSetSOPInstanceUID,'" AND ROIName="Rectum"'));
ptvROINumber = mysql(horzcat('SELECT ROINumber FROM seq_structuresetroi WHERE fk_SOPInstanceUID = "',StructureSetSOPInstanceUID,'" AND ROIName="Prostate"'));

bladder_dvh_id = mysql(horzcat('SELECT fk_dvh_id FROM seq_dvhreferencedroi WHERE fk_PatientID = "',patientID,'" AND ReferencedROINumber = "', num2str(BladderROINumber), '"'));
rectum_dvh_id = mysql(horzcat('SELECT fk_dvh_id FROM seq_dvhreferencedroi WHERE fk_PatientID = "',patientID,'" AND ReferencedROINumber = "', num2str(RectumROINumber), '"'));
ptv_dvh_id = mysql(horzcat('SELECT fk_dvh_id FROM seq_dvhreferencedroi WHERE fk_PatientID = "',patientID,'" AND ReferencedROINumber = "', num2str(ptvROINumber), '"'));

Bladder_DVHData_cell = mysql(horzcat('SELECT DVHData FROM seq_dvh WHERE fk_PatientID = "',patientID,'" AND dvh_id = "', num2str(bladder_dvh_id), '"'));
Rectum_DVHData_cell = mysql(horzcat('SELECT DVHData FROM seq_dvh WHERE fk_PatientID = "',patientID,'" AND dvh_id = "', num2str(rectum_dvh_id), '"'));
PTV_DVHData_cell = mysql(horzcat('SELECT DVHData FROM seq_dvh WHERE fk_PatientID = "',patientID,'" AND dvh_id = "', num2str(ptv_dvh_id), '"'));

Bladder_DVHData=regexp(Bladder_DVHData_cell{1,1},'/','split');
Rectum_DVHData=regexp(Rectum_DVHData_cell{1,1},'/','split');
PTV_DVHData=regexp(PTV_DVHData_cell{1,1},'/','split');

bladder_d_cell = Bladder_DVHData(1:2:length(Bladder_DVHData));
bladder_v_cell = Bladder_DVHData(2:2:length(Bladder_DVHData));

rectum_d_cell = Rectum_DVHData(1:2:length(Rectum_DVHData));
rectum_v_cell = Rectum_DVHData(2:2:length(Rectum_DVHData));

ptv_d_cell = PTV_DVHData(1:2:length(PTV_DVHData));
ptv_v_cell = PTV_DVHData(2:2:length(PTV_DVHData));

bladder_d = zeros(length(Bladder_DVHData)/2,1);
bladder_v = zeros(length(Bladder_DVHData)/2,1);
rectum_d = zeros(length(Rectum_DVHData)/2,1);
rectum_v = zeros(length(Rectum_DVHData)/2,1);
ptv_d = zeros(length(PTV_DVHData)/2,1);
ptv_v = zeros(length(PTV_DVHData)/2,1);

for i = 1:length(Bladder_DVHData)/2
    bladder_d(i)=str2double(bladder_d_cell{1,i});
    bladder_v(i)=str2double(bladder_v_cell{1,i})*100;
end;

for i = 1:length(Rectum_DVHData)/2
    rectum_d(i)=str2double(rectum_d_cell{1,i});
    rectum_v(i)=str2double(rectum_v_cell{1,i})*100;
end;

for i = 1:length(PTV_DVHData)/2
    ptv_d(i)=str2double(ptv_d_cell{1,i});
    ptv_v(i)=str2double(ptv_v_cell{1,i})*100;
end;

bladderD25 = findX(bladder_d,bladder_v,25);
bladderD50 = findX(bladder_d,bladder_v,50);
bladderD60 = findX(bladder_d,bladder_v,60);
bladderD75 = findX(bladder_d,bladder_v,75);
bladderD90 = findX(bladder_d,bladder_v,90);
bladderD95 = findX(bladder_d,bladder_v,95);

rectumD25 = findX(rectum_d,rectum_v,25);
rectumD50 = findX(rectum_d,rectum_v,50);
rectumD60 = findX(rectum_d,rectum_v,60);
rectumD75 = findX(rectum_d,rectum_v,75);
rectumD90 = findX(rectum_d,rectum_v,90);
rectumD95 = findX(rectum_d,rectum_v,95);

ptvD25 = findX(ptv_d,ptv_v,25);
ptvD50 = findX(ptv_d,ptv_v,50);
ptvD60 = findX(ptv_d,ptv_v,60);
ptvD75 = findX(ptv_d,ptv_v,75);
ptvD90 = findX(ptv_d,ptv_v,90);
ptvD95 = findX(ptv_d,ptv_v,95);

bladder_d_str = strrep(mat2str(bladder_d),';',',');
bladder_v_str = strrep(mat2str(bladder_v),';',',');

rectum_d_str = strrep(mat2str(rectum_d),';',',');
rectum_v_str = strrep(mat2str(rectum_v),';',',');

ptv_d_str = strrep(mat2str(ptv_d),';',',');
ptv_v_str = strrep(mat2str(ptv_v),';',',');

mysql(horzcat('UPDATE volume_distance SET D25 = "',num2str(bladderD25),'", D50 = "',num2str(bladderD50),'", D60 = "',num2str(bladderD60),'", D75 = "',num2str(bladderD75),'", D90 = "',num2str(bladderD90),'", D95 = "',num2str(bladderD95),'", DVH_d = "',bladder_d_str,'", DVH_v = "',bladder_v_str, '" WHERE fk_PatientID = "',patientID,'" AND ROIName="Bladder"'));
mysql(horzcat('UPDATE volume_distance SET D25 = "',num2str(rectumD25),'", D50 = "',num2str(rectumD50),'", D60 = "',num2str(rectumD60),'", D75 = "',num2str(rectumD75),'", D90 = "',num2str(rectumD90),'", D95 = "',num2str(rectumD95),'", DVH_d = "',rectum_d_str,'", DVH_v = "',rectum_v_str, '" WHERE fk_PatientID = "',patientID,'" AND ROIName="Rectum"'));

% Bladder_DVH_d = Bladder_DVHData{1:2:length(Bladder_DVHData)};
% Bladder_DVH_v = Bladder_DVHData{2:2:length(Bladder_DVHData)};
% 
% Rectum_DVH_d = Rectum_DVHData{1:2:length(Rectum_DVHData)};
% Rectum_DVH_v = Rectum_DVHData{2:2:length(Rectum_DVHData)};
% 
% PTV_DVH_d = PTV_DVHData{1:2:length(PTV_DVHData)};
% PTV_DVH_v = PTV_DVHData{2:2:length(PTV_DVHData)};

mysql('close');