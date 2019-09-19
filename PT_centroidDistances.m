%% assumes that one plane has only one contour

clear all;
patientID = '06191090';

%% database init
conn = mysql('open','localhost','root');
mysql('use pttest');
%PatientID = horzcat('UCLA_PR_',num2str(patient_number));
%patient_id = mysql(horzcat('SELECT id FROM patient WHERE PatientID="',PatientID,'"'));
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

%% Get positions of all ON pixels in the organ masks and the smooth ptv contour object
% bladderSub contains pixel positions of all ON pixels in the solid bladder
% mask, and rectumSub for the rectum. ptvSub has pixel positions of all ON
% pixels in the smoothened outline mask of the ptv

%INITIALIZE
numBladderVoxels = nnz(bladderBlock);
numRectumVoxels = nnz(rectumBlock);
numPtvVoxels = nnz(ptvBlock);
bladderSub = zeros(numBladderVoxels,3);
rectumSub = zeros(numRectumVoxels,3);
ptvSub = zeros(numPtvVoxels,3);

%FIND LINEAR INDICES OF ALL NON ZERO VOXELS
bladderLin = find(bladderBlock);
rectumLin = find(rectumBlock);
ptvLin = find(ptvBlock);

%CONVERT LINEAR INDICES TO SUBSCRIPTS
[bladderSub(:,1), bladderSub(:,2), bladderSub(:,3)] = ind2sub(size(bladderBlock),bladderLin);
[rectumSub(:,1), rectumSub(:,2), rectumSub(:,3)] = ind2sub(size(rectumBlock),rectumLin);
[ptvSub(:,1), ptvSub(:,2), ptvSub(:,3)] = ind2sub(size(ptvBlock),ptvLin);

%%CALCULATE CENTROIDS

bladderCentroid=[mean(bladderSub(:,1)); mean(bladderSub(:,2)); mean(bladderSub(:,3))];
rectumCentroid=[mean(rectumSub(:,1)); mean(rectumSub(:,2)); mean(rectumSub(:,3))];
ptvCentroid=[mean(ptvSub(:,1)); mean(ptvSub(:,2)); mean(ptvSub(:,3))];

%% WEIGHTED EUCLIDEAN DISTANCE
% d((i,j,k),(a,b,c))=sqrt[1(i-a)^2+alpha(j-b)^2+beta(k-c)^2], where the
% ratio of the sampling intervals in the three axes is 1:alpha:beta for
% row:column:plane viz 1:columnSpacing/rowSpacing:heightSpacing/rowSpacing

bladderPtv = sqrt((bladderCentroid(1,1)-ptvCentroid(1,1))^2+(bladderCentroid(2,1)-ptvCentroid(2,1))^2+(bladderCentroid(3,1)-ptvCentroid(3,1))^2);
rectumPtv = sqrt((rectumCentroid(1,1)-ptvCentroid(1,1))^2+(rectumCentroid(2,1)-ptvCentroid(2,1))^2+(rectumCentroid(3,1)-ptvCentroid(3,1))^2);

mysql(horzcat('UPDATE volume_distance SET Distance="',num2str(bladderPtv),'" WHERE fk_PatientID="',num2str(patientID),'" AND ROIName="Bladder"'));
mysql(horzcat('UPDATE volume_distance SET Distance="',num2str(rectumPtv),'" WHERE fk_PatientID="',num2str(patientID),'" AND ROIName="Rectum"'));

mysql('close');