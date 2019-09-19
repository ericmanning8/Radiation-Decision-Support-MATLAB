%% assumes that one plane has only one contour

clear all;
patientID = '06191090';
%SOP Class UID for RT Structure Set is 1.2.840.10008.5.1.4.1.1.481.3

%% database init
conn = mysql('open','localhost','root');
mysql('use pttest');
structureSetSOPInstanceUID_cell=mysql(horzcat('SELECT fk_SOPInstanceUID FROM iod_structure_set WHERE fk_PatientID="',num2str(patientID),'" AND fk_SOPClassUID="1.2.840.10008.5.1.4.1.1.481.3"'));
structureSetSOPInstanceUID = structureSetSOPInstanceUID_cell{1,1};
clear structureSetSOPInstanceUID_cell;
bladderROINumber = mysql(horzcat('SELECT ROINumber FROM seq_structuresetroi WHERE ROIName="Bladder" AND fk_SOPInstanceUID="',num2str(structureSetSOPInstanceUID),'"'));
rectumROINumber = mysql(horzcat('SELECT ROINumber FROM seq_structuresetroi WHERE ROIName="Rectum" AND fk_SOPInstanceUID="',num2str(structureSetSOPInstanceUID),'"'));
ptvROINumber = mysql(horzcat('SELECT ROINumber FROM seq_structuresetroi WHERE ROIName="Prostate" AND fk_SOPInstanceUID="',num2str(structureSetSOPInstanceUID),'"'));
studyInstanceUID_cell=mysql(horzcat('SELECT fk_StudyInstanceUID from iod_structure_set WHERE fk_SOPInstanceUID="',num2str(structureSetSOPInstanceUID),'"'));
studyInstanceUID = studyInstanceUID_cell{1,1};
clear studyInstanceUID_cell;
seriesInstanceUID_cell=mysql(horzcat('SELECT fk_seriesInstanceUID from iod_structure_set WHERE fk_SOPInstanceUID="',num2str(structureSetSOPInstanceUID),'"'));
seriesInstanceUID=seriesInstanceUID_cell{1,1};
clear seriesInstanceUID_cell;
firstCTSOPInstanceUID_cell = mysql(horzcat('SELECT ReferencedSOPInstanceUID FROM seq_contourimage WHERE fk_SOPInstanceUID = "',num2str(structureSetSOPInstanceUID),'" LIMIT 1'));
firstCTSOPInstanceUID = firstCTSOPInstanceUID_cell{1,1};
CTStudyInstanceUID_cell = mysql(horzcat('SELECT fk_StudyInstanceUID FROM iod_ct_image WHERE SOPInstanceUID = "', num2str(firstCTSOPInstanceUID), '"'));
CTSeriesInstanceUID_cell = mysql(horzcat('SELECT fk_SeriesInstanceUID FROM iod_ct_image WHERE SOPInstanceUID = "', num2str(firstCTSOPInstanceUID), '"'));
CTStudyInstanceUID = CTStudyInstanceUID_cell{1,1};
CTSeriesInstanceUID = CTSeriesInstanceUID_cell{1,1};
clear firstCTSOPInstanceUID_cell;
clear CTStudyInstanceUID_cell;
clear CTSeriesInstanceUID_cell;

%% SET INITIAL PARAMETERS
% for patient 4, ptv is 9, bladder is 2, rectum is 5
ptvID = ptvROINumber;
bladderID = bladderROINumber;
rectumID = rectumROINumber;

structureset_file_path = strcat('PT/',num2str(patientID),'/',num2str(studyInstanceUID),'/',num2str(seriesInstanceUID),'/',num2str(structureSetSOPInstanceUID),'.dcm');%create pathname for structure set file

structureSetInfo=dicominfo(structureset_file_path);%structure set file metadata
numStructures=length(fieldnames(structureSetInfo.StructureSetROISequence));%total number of structures in the structure set

%% To CREATE MAPPING OF ROI NUMBER AND NAMES
roiList=cell(numStructures,2);
for j = 1:numStructures
    item_number_string=strcat('Item_',num2str(j));% to generate strings 'Item_1','Item_2', etc.
    roiID=structureSetInfo.StructureSetROISequence.(item_number_string).ROINumber;
    roiList{roiID,1}=structureSetInfo.StructureSetROISequence.(item_number_string).ROIName;%column 1 contains names
    roiList{roiID,2}=roiID;%column 2 contains ROI Numbers
end

%% To DETERMINE ITEM NUMBER CORRESPONDING TO ROI NUMBER in ROI Contour
% Sequence object

numContourSeqs = length(fieldnames(structureSetInfo.ROIContourSequence));
for k = 1:numContourSeqs
    item_number_string=strcat('Item_',num2str(k));
    current_roi_number=structureSetInfo.ROIContourSequence.(item_number_string).ReferencedROINumber;
    if current_roi_number==ptvID
        ptv_Item_no=strcat('Item_',num2str(k));
    end
    if current_roi_number==bladderID
        bladder_Item_no=strcat('Item_',num2str(k));
    end
    if current_roi_number==rectumID
        rectum_Item_no=strcat('Item_',num2str(k));
    end
end

%% DETERMINE ROW SPACING AND COLUMN SPACING

imagei = dicominfo(strcat('PT/',num2str(patientID),'/', num2str(CTStudyInstanceUID),'/',num2str(CTSeriesInstanceUID),'/',num2str(firstCTSOPInstanceUID),'.dcm'));
rowSpacing = imagei.PixelSpacing(1);
columnSpacing = imagei.PixelSpacing(2);
sliceSpacing = imagei.SliceThickness;%assume slice thickness is always set and that there is no gap b/w slices
width = imagei.Width;
height = imagei.Height;

%% GET PTV, BLADDER AND RECTUM CONTOURS AND MASKS
% ptvBlock is the entire solid ptv - an object contour
% ptvContourBlock contains contour slices derived from the patient
% coordinate system translated to pixel coordinate system
 
[ptvBlock, ptvContourBlock]=PT_getContoursFull(structureSetInfo, ptv_Item_no, width, height, patientID, CTStudyInstanceUID, CTSeriesInstanceUID);
[bladderBlock, bladderContourBlock]=PT_getContoursFull(structureSetInfo, bladder_Item_no, width, height, patientID, CTStudyInstanceUID, CTSeriesInstanceUID);
[rectumBlock, rectumContourBlock]=PT_getContoursFull(structureSetInfo, rectum_Item_no, width, height, patientID, CTStudyInstanceUID, CTSeriesInstanceUID);

%% show contours and object slices
% ptvContour = ptvContourBlock(:,:,15);
% ptvFilled = ptvBlock(:,:,15);
% ptvSmoothContour = bwperim(ptvFilled);
% imshow(ptvContour); title('PTV Contour');
% figure, imshow(ptvSmoothContour); title('PTV Smoothened Contour');
% figure, imshow(ptvFilled); title('PTV Filled');
% ***********************************

%% Convert rough, slightly unconnected contours to smooth contours. Since
% the objects are 3D, the first and last slice should be filled to give a
% true outline; only ptv countours are smoothened since only ptv contours
% are needed. for OARs, solid masks are needed
ptvOutline3D = zeros(size(ptvBlock));
for i = 2:(size(ptvBlock,3)-1)
    ptvOutline3D(:,:,i) = bwperim(ptvBlock(:,:,i));
end 
ptvOutline3D(:,:,1) = ptvBlock(:,:,1);
ptvOutline3D(:,:,size(ptvBlock,3)) = ptvBlock(:,:,size(ptvBlock,3));

%% SEPARATION OF OARs into intersecting and non-intersecting parts

rectumIntersecting = rectumBlock&ptvBlock;
rectumNonIntersecting = rectumBlock - rectumIntersecting;
bladderIntersecting = bladderBlock&ptvBlock;
bladderNonIntersecting = bladderBlock - bladderIntersecting;

ptvVolume = sum(sum(sum(ptvBlock*rowSpacing*columnSpacing*sliceSpacing)))/1000;
rectumVolume = sum(sum(sum(rectumBlock*rowSpacing*columnSpacing*sliceSpacing)))/1000;
bladderVolume = sum(sum(sum(bladderBlock*rowSpacing*columnSpacing*sliceSpacing)))/1000;
rectumIntersectingVolume = sum(sum(sum(rectumIntersecting*rowSpacing*columnSpacing*sliceSpacing)))/1000;
bladderIntersectingVolume = sum(sum(sum(bladderIntersecting*rowSpacing*columnSpacing*sliceSpacing)))/1000;
bladderPercentageOverlap = bladderIntersectingVolume/bladderVolume*100;
rectumPercentageOverlap = rectumIntersectingVolume/rectumVolume*100;
%%Insert new data into DB
mysql(horzcat('INSERT INTO volume_distance (PercentageOverlap, IntersectingVolume, fk_PatientID, fk_StudyInstanceUID, fk_SeriesInstanceUID, fk_SOPInstanceUID, ROIName) VALUES ("',num2str(bladderPercentageOverlap),'","',num2str(bladderIntersectingVolume),'","',num2str(patientID),'","',num2str(studyInstanceUID),'","',num2str(seriesInstanceUID),'","',num2str(structureSetSOPInstanceUID),'","Bladder")'));
mysql(horzcat('INSERT INTO volume_distance (PercentageOverlap, IntersectingVolume, fk_PatientID, fk_StudyInstanceUID, fk_SeriesInstanceUID, fk_SOPInstanceUID, ROIName) VALUES ("',num2str(rectumPercentageOverlap),'","',num2str(rectumIntersectingVolume),'","',num2str(patientID),'","',num2str(studyInstanceUID),'","',num2str(seriesInstanceUID),'","',num2str(structureSetSOPInstanceUID),'","Rectum")'));
% mysql(horzcat('UPDATE structure_set_roi_sequence SET ROIVolume="',num2str(rectumVolume),'" WHERE id="',num2str(rectum_structure_set_roi_sequence_id),'"'));
% mysql(horzcat('UPDATE structure_set_roi_sequence SET ROIVolume="',num2str(bladderVolume),'" WHERE id="',num2str(bladder_structure_set_roi_sequence_id),'"'));
% mysql(horzcat('UPDATE structure_set_roi_sequence SET ROIVolume="',num2str(ptvVolume),'" WHERE id="',num2str(ptv_structure_set_roi_sequence_id),'"'));
mysql('close');



