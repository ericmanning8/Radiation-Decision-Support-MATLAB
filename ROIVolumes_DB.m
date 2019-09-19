%% assumes that one plane has only one contour

clear;
% patient_number=1;

%% database init
conn = mysql('open','localhost','root');
mysql('use rt_test');
PatientID = horzcat('UCLA_PR_',num2str(patient_number));
patient_id = mysql(horzcat('SELECT id FROM patient WHERE PatientID="',PatientID,'"'));
ptv_structure_set_roi_sequence_id=mysql(horzcat('SELECT id FROM structure_set_roi_sequence WHERE ROIName="PTV" AND fk_patient_id="',num2str(patient_id),'"'));
bladder_structure_set_roi_sequence_id=mysql(horzcat('SELECT id FROM structure_set_roi_sequence WHERE ROIName="Bladder" AND fk_patient_id="',num2str(patient_id),'"'));
rectum_structure_set_roi_sequence_id=mysql(horzcat('SELECT id FROM structure_set_roi_sequence WHERE ROIName="Rectum" AND fk_patient_id="',num2str(patient_id),'"'));
bladderROINumber = mysql(horzcat('SELECT ROINumber FROM structure_set_roi_sequence WHERE ROIName="Bladder" AND fk_patient_id="',num2str(patient_id),'"'));
rectumROINumber = mysql(horzcat('SELECT ROINumber FROM structure_set_roi_sequence WHERE ROIName="Rectum" AND fk_patient_id="',num2str(patient_id),'"'));
ptvROINumber = mysql(horzcat('SELECT ROINumber FROM structure_set_roi_sequence WHERE ROIName="PTV" AND fk_patient_id="',num2str(patient_id),'"'));
study_id=mysql(horzcat('SELECT fk_study_id from structure_set_roi_sequence WHERE id="',num2str(ptv_structure_set_roi_sequence_id),'"'));
series_id=mysql(horzcat('SELECT fk_series_id from structure_set_roi_sequence WHERE id="',num2str(ptv_structure_set_roi_sequence_id),'"'));
sop_common_id=mysql(horzcat('SELECT fk_sop_common_id from structure_set_roi_sequence WHERE id="',num2str(ptv_structure_set_roi_sequence_id),'"'));
%% SET INITIAL PARAMETERS
% for patient 4, ptv is 9, bladder is 2, rectum is 5
ptvID = ptvROINumber;
bladderID = bladderROINumber;
rectumID = rectumROINumber;

containing_folder = strcat('UCLA_PR_',num2str(patient_number));%create folder path from patient number
structureset_file_path = strcat('UCLA_PR_',num2str(patient_number),'/structureset.dcm');%create pathname for structure set file

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
ImageSOP = structureSetInfo.ROIContourSequence.(ptv_Item_no).ContourSequence.Item_1.ContourImageSequence.Item_1.ReferencedSOPInstanceUID;
imagei = dicominfo(strcat(containing_folder,'/CT.',ImageSOP,'.dcm'));
rowSpacing = imagei.PixelSpacing(1);
columnSpacing = imagei.PixelSpacing(2);
sliceSpacing = imagei.SliceThickness;%assume slice thickness is always set and that there is no gap b/w slices
width = imagei.Width;
height = imagei.Height;

%% GET PTV, BLADDER AND RECTUM CONTOURS AND MASKS
% ptvBlock is the entire solid ptv - an object contour
% ptvContourBlock contains contour slices derived from the patient
% coordinate system translated to pixel coordinate system
 
[ptvBlock, ptvContourBlock]=getContoursFull(structureSetInfo, ptv_Item_no, width, height, patient_number);
[bladderBlock, bladderContourBlock]=getContoursFull(structureSetInfo, bladder_Item_no, width, height, patient_number);
[rectumBlock, rectumContourBlock]=getContoursFull(structureSetInfo, rectum_Item_no, width, height, patient_number);

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
% mysql(horzcat('INSERT INTO volume_distance (fk_ROI, fk_CompareWithROI, IntersectingVolume, fk_sop_common_id, fk_series_id, fk_study_id, fk_patient_id, ROIName, PercentageOverlap) VALUES ("',num2str(bladder_structure_set_roi_sequence_id),'","',num2str(ptv_structure_set_roi_sequence_id),'","',num2str(bladderIntersectingVolume),'","',num2str(sop_common_id),'","',num2str(series_id),'","',num2str(study_id),'","',num2str(patient_id),'","Bladder","',num2str(bladderPercentageOverlap),'")'));
% mysql(horzcat('INSERT INTO volume_distance (fk_ROI, fk_CompareWithROI, IntersectingVolume, fk_sop_common_id, fk_series_id, fk_study_id, fk_patient_id, ROIName, PercentageOverlap) VALUES ("',num2str(rectum_structure_set_roi_sequence_id),'","',num2str(ptv_structure_set_roi_sequence_id),'","',num2str(rectumIntersectingVolume),'","',num2str(sop_common_id),'","',num2str(series_id),'","',num2str(study_id),'","',num2str(patient_id),'","Rectum","',num2str(rectumPercentageOverlap),'")'));
% mysql(horzcat('UPDATE structure_set_roi_sequence SET ROIVolume="',num2str(rectumVolume),'" WHERE id="',num2str(rectum_structure_set_roi_sequence_id),'"'));
% mysql(horzcat('UPDATE structure_set_roi_sequence SET ROIVolume="',num2str(bladderVolume),'" WHERE id="',num2str(bladder_structure_set_roi_sequence_id),'"'));
% mysql(horzcat('UPDATE structure_set_roi_sequence SET ROIVolume="',num2str(ptvVolume),'" WHERE id="',num2str(ptv_structure_set_roi_sequence_id),'"'));
% mysql('close');



