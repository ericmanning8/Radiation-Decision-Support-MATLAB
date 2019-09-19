clear all;

%% database init
conn = mysql('open','localhost','root');
mysql('use rt_hn_v4');

dose_ids = mysql(horzcat('SELECT id FROM dose'));

%for i=1:length(dose_ids) %Cycle through every dose record
%for i=5:5
    i=5;
    patient_id=5;
    stdROIName = 'mandible';
    %Select the sop id, series id, study id and patient id associated with each dose record
    [sop, series, study, patient]=mysql(horzcat('SELECT fk_sop_id, fk_series_id, fk_study_id, fk_patient_id FROM dose WHERE id="',num2str(dose_ids(i)),'"')); 
    %Retrieve the dose grid by reading the appropriate file
    dose_grid = dicomread(horzcat('/Users/ruchi/Documents/python/rt/test/dicom/',num2str(patient),'/',num2str(study),'/',num2str(series),'/',num2str(sop),'.dcm'));
    
    %Assumption: dose_grid is rows x columns x 1 x slices
    
    [numDoseRows, numDoseColumns, temp, numDoseSlices] = size(dose_grid);
    [imgOrPatDoseCell, pixelSpacingDoseCell, imgPosPatDoseCell, gridFrameOffsetCell, doseGridScalingCell]=mysql(horzcat('SELECT ImageOrientationPatient, PixelSpacing, ImagePositionPatient, GridFrameOffsetVector, DoseGridScaling FROM dose WHERE id="',num2str(dose_ids(i)),'"'));
    
    imgOrPatDose = regexp(imgOrPatDoseCell{1},',','split');%Split the first set of contour data points at the commas
    if imgOrPatDose{1}(1)=='['
        imgOrPatDose{1}=imgOrPatDose{1}(2:length(imgOrPatDose{1}));%Trim the '[' character off 
        imgOrPatDose{length(imgOrPatDose)}=imgOrPatDose{length(imgOrPatDose)}(1:length(imgOrPatDose{length(imgOrPatDose)})-1);%Trim the ']' character off 
    end;
    
    imgPosPatDose = regexp(imgPosPatDoseCell{1},',','split');%Split the first set of contour data points at the commas
    if imgPosPatDose{1}(1)=='['
        imgPosPatDose{1}=imgPosPatDose{1}(2:length(imgPosPatDose{1}));%Trim the '[' character off 
        imgPosPatDose{length(imgPosPatDose)}=imgPosPatDose{length(imgPosPatDose)}(1:length(imgPosPatDose{length(imgPosPatDose)})-1);%Trim the ']' character off 
    end;
    
    pixelSpacingDose = regexp(pixelSpacingDoseCell{1},',','split');%Split the first set of contour data points at the commas
    if pixelSpacingDose{1}(1)=='['
        pixelSpacingDose{1}=pixelSpacingDose{1}(2:length(pixelSpacingDose{1}));%Trim the '[' character off 
        pixelSpacingDose{length(pixelSpacingDose)}=pixelSpacingDose{length(pixelSpacingDose)}(1:length(pixelSpacingDose{length(pixelSpacingDose)})-1);%Trim the ']' character off 
    end;
    
    gridFrameOffset = regexp(gridFrameOffsetCell{1},',','split');%Split the first set of contour data points at the commas
    if gridFrameOffset{1}(1)=='['
        gridFrameOffset{1}=gridFrameOffset{1}(2:length(gridFrameOffset{1}));%Trim the '[' character off 
        gridFrameOffset{length(gridFrameOffset)}=gridFrameOffset{length(gridFrameOffset)}(1:length(gridFrameOffset{length(gridFrameOffset)})-1);%Trim the ']' character off 
    end;

    
    [doseCoordsI, doseCoordsJ]=ndgrid(1:numDoseColumns,1:numDoseRows);
    numDosePlanePoints = numDoseRows*numDoseColumns;
    numDosePoints = numDoseRows*numDoseColumns*numDoseSlices;
    doseCoordsI=reshape(doseCoordsI,numDosePlanePoints,1)-ones(numDosePlanePoints,1);%Subtract 1 because the row and col index should start from 0
    doseCoordsJ=reshape(doseCoordsJ,numDosePlanePoints,1)-ones(numDosePlanePoints,1);
    doseValues = str2double(doseGridScalingCell{1})*dose_grid;
    
    patientDoseCoordsX=str2double(imgOrPatDose{1})*str2double(pixelSpacingDose{2})*doseCoordsJ+str2double(imgOrPatDose{4})*str2double(pixelSpacingDose{1})*doseCoordsI+str2double(imgPosPatDose{1})*ones(numDosePlanePoints,1);
    patientDoseCoordsY=str2double(imgOrPatDose{2})*str2double(pixelSpacingDose{2})*doseCoordsJ+str2double(imgOrPatDose{5})*str2double(pixelSpacingDose{1})*doseCoordsI+str2double(imgPosPatDose{2})*ones(numDosePlanePoints,1);
    
    patientDoseCoordsX=repmat(patientDoseCoordsX,[numDoseSlices,1]);
    patientDoseCoordsY=repmat(patientDoseCoordsY,[numDoseSlices,1]);
    gridFrameOffsetVector = str2double(gridFrameOffset);
    gridFrameOffsetVector = gridFrameOffsetVector + str2double(imgPosPatDose{3})*ones(size(gridFrameOffsetVector));
    gridFrameOffsetVector = repmat(gridFrameOffsetVector,[numDosePlanePoints,1]);
    patientDoseCoordsZ = reshape(gridFrameOffsetVector,numDosePoints,1);
    
    
    clear gridFrameOffsetVector;
    clear gridFrameOffset;
    
    patientDoseCoordsXGrid = reshape(patientDoseCoordsX,numDoseRows,numDoseColumns,numDoseSlices);
    patientDoseCoordsYGrid = reshape(patientDoseCoordsY,numDoseRows,numDoseColumns,numDoseSlices);
    patientDoseCoordsZGrid = reshape(patientDoseCoordsZ,numDoseRows,numDoseColumns,numDoseSlices);
    
    
    
    %% ******************************** CT Conversion to Patient Coordinate System ******************************************
    % ***********************************************************************************************************************
    
    [imgOrPatCTCell, pixelSpacingCTCell, imgPosPatCTCell, numCTRows, numCTColumns]=mysql(horzcat('SELECT ImageOrientationPatient, PixelSpacing, ImagePositionPatient, Rows, Columns FROM image_plane_pixel WHERE fk_patient_id="',num2str(patient),'" LIMIT 1'));
    ctSliceLocations=str2double(mysql(horzcat('SELECT imgPosPatZ FROM image_plane_pixel WHERE fk_patient_id="',num2str(patient),'"')));
    ctSliceLocations = sort(ctSliceLocations,1);
    numCTSlices = mysql(horzcat('SELECT numCTifCT FROM series WHERE fk_patient_id="',num2str(patient),'" LIMIT 1'));
    
    imgOrPatCT = regexp(imgOrPatCTCell{1},',','split');%Split the first set of contour data points at the commas
    if imgOrPatCT{1}(1)=='['
        imgOrPatCT{1}=imgOrPatCT{1}(2:length(imgOrPatCT{1}));%Trim the '[' character off 
        imgOrPatCT{length(imgOrPatCT)}=imgOrPatCT{length(imgOrPatCT)}(1:length(imgOrPatCT{length(imgOrPatCT)})-1);%Trim the ']' character off 
    end;
    
    imgPosPatCT = regexp(imgPosPatCTCell{1},',','split');%Split the first set of contour data points at the commas
    if imgPosPatCT{1}(1)=='['
        imgPosPatCT{1}=imgPosPatCT{1}(2:length(imgPosPatCT{1}));%Trim the '[' character off 
        imgPosPatCT{length(imgPosPatCT)}=imgPosPatCT{length(imgPosPatCT)}(1:length(imgPosPatCT{length(imgPosPatCT)})-1);%Trim the ']' character off 
    end;
    
    pixelSpacingCT = regexp(pixelSpacingCTCell{1},',','split');%Split the first set of contour data points at the commas
    if pixelSpacingCT{1}(1)=='['
        pixelSpacingCT{1}=pixelSpacingCT{1}(2:length(pixelSpacingCT{1}));%Trim the '[' character off 
        pixelSpacingCT{length(pixelSpacingCT)}=pixelSpacingCT{length(pixelSpacingCT)}(1:length(pixelSpacingCT{length(pixelSpacingCT)})-1);%Trim the ']' character off 
    end;
    
    [CTCoordsI, CTCoordsJ]=ndgrid(1:numCTColumns,1:numCTRows);
    numCTPlanePoints = numCTRows*numCTColumns;
    numCTPoints = numCTRows*numCTColumns*numCTSlices;
    CTCoordsI=reshape(CTCoordsI,numCTPlanePoints,1)-ones(numCTPlanePoints,1);%Subtract 1 because the row and col index should start from 0
    CTCoordsJ=reshape(CTCoordsJ,numCTPlanePoints,1)-ones(numCTPlanePoints,1);
    
    patientCTCoordsX=str2double(imgOrPatCT{1})*str2double(pixelSpacingCT{2})*CTCoordsJ+str2double(imgOrPatCT{4})*str2double(pixelSpacingCT{1})*CTCoordsI+str2double(imgPosPatCT{1})*ones(numCTPlanePoints,1);
    patientCTCoordsY=str2double(imgOrPatCT{2})*str2double(pixelSpacingCT{2})*CTCoordsJ+str2double(imgOrPatCT{5})*str2double(pixelSpacingCT{1})*CTCoordsI+str2double(imgPosPatCT{2})*ones(numCTPlanePoints,1);
    
    patientCTCoordsX=repmat(patientCTCoordsX,[numCTSlices,1]);
    patientCTCoordsY=repmat(patientCTCoordsY,[numCTSlices,1]);
    ctSliceLocations = repmat(ctSliceLocations,[numCTPlanePoints,1]);
    patientCTCoordsZ = reshape(ctSliceLocations,numCTPoints,1);
    
    patientCTCoordsXGrid = reshape(patientCTCoordsX,numCTRows,numCTColumns,numCTSlices);
    patientCTCoordsYGrid = reshape(patientCTCoordsY,numCTRows,numCTColumns,numCTSlices);
    patientCTCoordsZGrid = reshape(patientCTCoordsZ,numCTRows,numCTColumns,numCTSlices);
    
    doseValues = flipdim(double(reshape(doseValues,numDoseRows,numDoseColumns,numDoseSlices)),3);
    
    clear doseCoordsI;
    clear doseCoordsJ;
    clear CTCoordsI;
    clear CTCoordsJ;
    clear ctSliceLocations;
    clear dose_grid;
    clear patientDoseCoordsX;
    clear patientDoseCoordsY;
    clear patientDoseCoordsZ;
    clear patientCTCoordsX;
    clear patientCTCoordsY;
    clear patientCTCoordsZ;
    
    newDose = interpn(patientDoseCoordsXGrid,patientDoseCoordsYGrid,patientDoseCoordsZGrid,doseValues,patientCTCoordsXGrid,patientCTCoordsYGrid,patientCTCoordsZGrid);
    
    roiBlock=HN_getContoursFull(patient_id, stdROIName); 
    intersect = doseValues.*roiBlock;
    
    clear roiBlock;
    [r,c,v]=find(intersect);
    
    
    
    %doseValues = zeros(numRows*numColumns*numSlices, 1); %List of all the dose values
    %doseCoords = zeros(numRows*numColumns*numSlices, 3); %List of dose coordinates (row,column,slice)
    %patientCoords = zeros(numRows*numColumns*numSlices, 3); %List of patient coordinates after conversion (x,y,z)
    %ctCoords = zeros(numRows*numColumns*numSlices, 3); %List of coordinates in the CT Coordinate system (row,column,slice)
     
%     %fill doseCoords with dose coordinates :)
%     counter=1;
%     for row=1:numRows
%         for column=1:numColumns
%             for slice=1:numSlices
%                 doseValues(counter)=dose_grid(row,column,1,slice);
%                 doseCoords(counter,1)=row;
%                 doseCoords(counter,2)=column;
%                 doseCoords(counter,3)=slice;
%                 counter=counter+1;
%             end;
%             counter=counter+1;
%         end;
%         counter=counter+1;
%     end;
%     
%     for j=1:length(doseCoords)
%         patientCoords(j,1)=str2double(imgOrPat{1})*str2double(pixelSpacing{2})*doseCoords(j,2)+str2double(imgOrPat{4})*str2double(pixelSpacing{1})*doseCoords(j,1)+str2double(imgPosPat{1});
%         patientCoords(j,2)=str2double(imgOrPat{2})*str2double(pixelSpacing{2})*doseCoords(j,2)+str2double(imgOrPat{5})*str2double(pixelSpacing{1})*doseCoords(j,1)+str2double(imgPosPat{2});
%         patientCoords(j,3)=str2double(imgOrPat{3})*str2double(pixelSpacing{2})*doseCoords(j,2)+str2double(imgOrPat{6})*str2double(pixelSpacing{1})*doseCoords(j,1)+str2double(imgPosPat{3});     
%     end;
%    

% doseValues = reshape(dose_grid,numRows*numColumns*numSlices,1);
% %reshape picks up elements along columns first and then rows
% doseCoordsX=transpose(0:255);
% doseCoordsX=repmat(doseCoordsX,numColumns,1);
% doseCoordsY=0:255;
% doseCoordsY=repmat(doseCoordsY,numRows,1);
% doseCoordsY=reshape(doseCoordsY,numRows*numColumns,1);
    
%end
mysql('close');