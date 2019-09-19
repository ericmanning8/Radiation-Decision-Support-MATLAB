clear all;
conn = mysql('open','localhost','root');
mysql('use rt_hn_v6');

patient_ids=[67,68,69,70,71];

%for idx = 1:length(patient_ids)
for idx = 1:length(patient_ids)
    disp(horzcat('Processing Patient ',num2str(idx),' of ',num2str(length(patient_ids))));
    fk_patient_id=patient_ids(idx);
    %Since every contour has an associated CT Slice, extract the first ct image
    %for the first roi
    [sampleCTSOP, ct_series_id] = mysql(horzcat('SELECT fk_sop_id, fk_series_id FROM ct_image WHERE fk_patient_id = "1" LIMIT 1'));
    numCTs = mysql(horzcat('SELECT numCTifCT FROM series WHERE id = "',num2str(ct_series_id),'"'));%Get number of CT Images

    %Get row spacing, slice spacing etc based on the sample ct image
    [rowSpacing, columnSpacing, sliceSpacing, width, height]=mysql(horzcat('SELECT pixelSpacingRow, pixelSpacingColumn, sliceThickness, columns, rows FROM image_plane_pixel WHERE fk_sop_id="',num2str(sampleCTSOP),'"'));
    rowSpacing=str2double(rowSpacing{1,1});columnSpacing=str2double(columnSpacing{1,1});sliceSpacing=str2double(sliceSpacing{1,1});
    imageBlock=zeros(height, width, numCTs);

    %imgPosPatZ gives the z indices of all CT images. This is useful in
    %assembling the CT Block
    imgPosPatZ = sort(str2double(mysql(horzcat('SELECT imgPosPatZ FROM image_plane_pixel WHERE fk_series_id="',num2str(ct_series_id),'"'))));
    allCTs = mysql(horzcat('SELECT id FROM sop WHERE fk_series_id="',num2str(ct_series_id),'"'));
    for vv=1:length(allCTs)
            [ser,st,pat]=mysql(horzcat('SELECT fk_series_id,fk_study_id,fk_patient_id FROM sop WHERE id="',num2str(allCTs(vv)),'"'));
            ct_z=str2double(mysql(horzcat('SELECT imgPosPatZ FROM image_plane_pixel WHERE fk_sop_id="',num2str(allCTs(vv)),'"')));
            imageBlock(:,:,imgPosPatZ==ct_z)=im2double(dicomread(horzcat('/Users/ruchi/Documents/python/rt/test/dicom/',num2str(pat),'/',num2str(st),'/',num2str(ser),'/',num2str(allCTs(vv)),'.dcm')));

    end;

    [dose_sop_id, dose_series_id, dose_study_id, doseGridScaling, gridFrameOffsetVector, ImagePositionPatientCell]=mysql(horzcat('SELECT fk_sop_id, fk_series_id, fk_study_id, doseGridScaling, GridFrameOffsetVector, ImagePositionPatient FROM dose WHERE fk_patient_id="',num2str(fk_patient_id),'"'));
    
    ImagePositionPatient = regexp(ImagePositionPatientCell{1},',','split');%Split the first set of contour data points at the commas
    if ImagePositionPatient{1}(1)=='['
        ImagePositionPatient{1}=ImagePositionPatient{1}(2:length(ImagePositionPatient{1}));%Trim the '[' character off 
        ImagePositionPatient{length(ImagePositionPatient)}=ImagePositionPatient{length(ImagePositionPatient)}(1:length(ImagePositionPatient{length(ImagePositionPatient)})-1);%Trim the ']' character off 
    end;
    
    gridFrameOffset = regexp(gridFrameOffsetVector{1},',','split');%Split the first set of contour data points at the commas
    if gridFrameOffset{1}(1)=='['
        gridFrameOffset{1}=gridFrameOffset{1}(2:length(gridFrameOffset{1}));%Trim the '[' character off 
        gridFrameOffset{length(gridFrameOffset)}=gridFrameOffset{length(gridFrameOffset)}(1:length(gridFrameOffset{length(gridFrameOffset)})-1);%Trim the ']' character off 
    end;
    gridFrameOffsetVector=str2double(gridFrameOffset);
    zIndexDose = str2double(ImagePositionPatient{3});
    zArrayDose = gridFrameOffsetVector + ones(size(gridFrameOffsetVector)).*zIndexDose;
    
    doseGrid = dicomread(horzcat('/Users/ruchi/Documents/python/rt/test/dicom/',num2str(fk_patient_id),'/',num2str(dose_study_id),'/',num2str(dose_series_id),'/',num2str(dose_sop_id),'.dcm'));
    doseGrid=doseGrid.*str2double(doseGridScaling{1,1});
    doseGrid=reshape(doseGrid,size(doseGrid,1),size(doseGrid,2),size(doseGrid,4));
    maxDose=max(max(max(doseGrid)));

    isodoseValues=[40;50;60;70;80;90;95];
    isodoseRows = cell(7,1);
    isodoseColumns = cell(7,1);

    [ct_fk_sop_ids, ct_fk_study_ids, ct_fk_series_ids, zIndex] = mysql(horzcat('SELECT fk_sop_id, fk_study_id, fk_series_id, zIndex FROM ct_image WHERE fk_patient_id="',num2str(fk_patient_id),'"'));
    
    for i=1:length(ct_fk_sop_ids)
        ct_fk_sop_id=ct_fk_sop_ids(i);
        ct_fk_study_id=ct_fk_study_ids(i);
        ct_fk_series_id=ct_fk_series_ids(i);
        zIndexCT=zIndex(i);
        
        for j=1:length(isodoseValues)
            tempDoseMask = zeros(size(doseGrid));
            doseOutline = zeros(size(doseGrid));
            tempDoseMask(doseGrid>(isodoseValues(j)*0.01*maxDose))=1;
            for m=1:size(doseGrid,3)
                doseOutline(:,:,m) = bwperim(tempDoseMask(:,:,m));
            end
            [r,c]=find(doseOutline(:,:,zArrayDose==zIndexCT));
            if ~(isempty(r))
                isodoseRows{j} = strrep(mat2str(r),';',',');
                isodoseColumns{j} = strrep(mat2str(c),';',',');
                mysql(horzcat('INSERT INTO isodose (fk_patient_id, dose_fk_sop_id, dose_fk_series_id, dose_fk_study_id, ct_fk_sop_id, ct_fk_series_id, ct_fk_study_id, isodoseNumber, rowValues, columnValues) VALUES ("',num2str(fk_patient_id),'" ,"',num2str(dose_sop_id), '" ,"', num2str(dose_series_id), '" ,"', num2str(dose_study_id), '" ,"', num2str(ct_fk_sop_id),'", "',num2str(ct_fk_series_id),'", "',num2str(ct_fk_study_id),'", "',num2str(isodoseValues(j)),'", "',isodoseRows{j},'", "',isodoseColumns{j},'")'));
        
            end
            
        end;
        
%         mysql(horzcat('INSERT INTO isodose (fk_patient_id, dose_fk_sop_id, dose_fk_series_id, dose_fk_study_id, ct_fk_sop_id, ct_fk_series_id, ct_fk_study_id, isodoseNumber, rowValues, columnValues) VALUES ("',num2str(fk_patient_id),'" ,"',num2str(dose_sop_id), '" ,"', num2str(dose_series_id), '" ,"', num2str(dose_study_id), '" ,"', num2str(ct_fk_sop_id),'", "',num2str(ct_fk_series_id),'", "',num2str(ct_fk_study_id),'", "40", ',isodoseRows{1},', ',isodoseColumns{1},')'));
%         mysql(horzcat('INSERT INTO isodose (fk_patient_id, dose_fk_sop_id, dose_fk_series_id, dose_fk_study_id, ct_fk_sop_id, ct_fk_series_id, ct_fk_study_id, isodoseNumber, rowValues, columnValues) VALUES ("',num2str(fk_patient_id),'" ,"',num2str(dose_sop_id), '" ,"', num2str(dose_series_id), '" ,"', num2str(dose_study_id), '" ,"', num2str(ct_fk_sop_id),'", "',num2str(ct_fk_series_id),'", "',num2str(ct_fk_study_id),'", "50", ',isodoseRows{2},', ',isodoseColumns{2},''));
%         mysql(horzcat('INSERT INTO isodose (fk_patient_id, dose_fk_sop_id, dose_fk_series_id, dose_fk_study_id, ct_fk_sop_id, ct_fk_series_id, ct_fk_study_id, isodoseNumber, rowValues, columnValues) VALUES ("',num2str(fk_patient_id),'" ,"',num2str(dose_sop_id), '" ,"', num2str(dose_series_id), '" ,"', num2str(dose_study_id), '" ,"', num2str(ct_fk_sop_id),'", "',num2str(ct_fk_series_id),'", "',num2str(ct_fk_study_id),'", "60", "',isodoseRows{3},'", "',isodoseColumns{3},'"'));
%         mysql(horzcat('INSERT INTO isodose (fk_patient_id, dose_fk_sop_id, dose_fk_series_id, dose_fk_study_id, ct_fk_sop_id, ct_fk_series_id, ct_fk_study_id, isodoseNumber, rowValues, columnValues) VALUES ("',num2str(fk_patient_id),'" ,"',num2str(dose_sop_id), '" ,"', num2str(dose_series_id), '" ,"', num2str(dose_study_id), '" ,"', num2str(ct_fk_sop_id),'", "',num2str(ct_fk_series_id),'", "',num2str(ct_fk_study_id),'", "70", "',isodoseRows{4},'", "',isodoseColumns{4},'"'));
%         mysql(horzcat('INSERT INTO isodose (fk_patient_id, dose_fk_sop_id, dose_fk_series_id, dose_fk_study_id, ct_fk_sop_id, ct_fk_series_id, ct_fk_study_id, isodoseNumber, rowValues, columnValues) VALUES ("',num2str(fk_patient_id),'" ,"',num2str(dose_sop_id), '" ,"', num2str(dose_series_id), '" ,"', num2str(dose_study_id), '" ,"', num2str(ct_fk_sop_id),'", "',num2str(ct_fk_series_id),'", "',num2str(ct_fk_study_id),'", "80", "',isodoseRows{5},'", "',isodoseColumns{5},'"'));
%         mysql(horzcat('INSERT INTO isodose (fk_patient_id, dose_fk_sop_id, dose_fk_series_id, dose_fk_study_id, ct_fk_sop_id, ct_fk_series_id, ct_fk_study_id, isodoseNumber, rowValues, columnValues) VALUES ("',num2str(fk_patient_id),'" ,"',num2str(dose_sop_id), '" ,"', num2str(dose_series_id), '" ,"', num2str(dose_study_id), '" ,"', num2str(ct_fk_sop_id),'", "',num2str(ct_fk_series_id),'", "',num2str(ct_fk_study_id),'", "90", "',isodoseRows{6},'", "',isodoseColumns{6},'"'));
%         mysql(horzcat('INSERT INTO isodose (fk_patient_id, dose_fk_sop_id, dose_fk_series_id, dose_fk_study_id, ct_fk_sop_id, ct_fk_series_id, ct_fk_study_id, isodoseNumber, rowValues, columnValues) VALUES ("',num2str(fk_patient_id),'" ,"',num2str(dose_sop_id), '" ,"', num2str(dose_series_id), '" ,"', num2str(dose_study_id), '" ,"', num2str(ct_fk_sop_id),'", "',num2str(ct_fk_series_id),'", "',num2str(ct_fk_study_id),'", "95", "',isodoseRows{7},'", "',isodoseColumns{7},'"'));
   
%     mysql(horzcat('UPDATE ct_image SET isodose40_rows=',isodoseRows{1},', isodose50_rows=',isodoseRows{2},', isodose60_rows=',isodoseRows{3},', isodose70_rows=',isodoseRows{4},', isodose80_rows=',isodoseRows{5},', isodose90_rows=',isodoseRows{6},', isodose95_rows=',isodoseRows{7},' WHERE fk_sop_id="',num2str(ct_fk_sop_id),'"'));
%     mysql(horzcat('UPDATE ct_image SET isodose40_columns=',isodoseColumns{1},', isodose50_columns=',isodoseColumns{2},', isodose60_columns=',isodoseColumns{3},', isodose70_columns=',isodoseColumns{4},', isodose80_columns=',isodoseColumns{5},', isodose90_columns=',isodoseColumns{6},', isodose95_columns=',isodoseColumns{7},' WHERE fk_sop_id="',num2str(ct_fk_sop_id),'"'));
    disp(horzcat('Processed sop ',num2str(ct_fk_sop_id),num2str(fk_patient_id)));
    
    end

    disp(horzcat('Processed Patient ',num2str(idx),' of ',num2str(length(patient_ids))));
end
clear conn;

