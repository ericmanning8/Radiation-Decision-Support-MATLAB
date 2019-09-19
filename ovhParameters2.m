%% assumes that one plane has only one contour

clear all;
patient_number = 1;

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

%% Get positions of all ON pixels in the organ masks and the smooth ptv contour object
% bladderSub contains pixel positions of all ON pixels in the solid bladder
% mask, and rectumSub for the rectum. ptvSub has pixel positions of all ON
% pixels in the smoothened outline mask of the ptv

%INITIALIZE
numIntersectingBladderVoxels = nnz(bladderIntersecting);
numNonIntersectingBladderVoxels = nnz(bladderNonIntersecting);
%numBladderVoxels=numIntersectingBladderVoxels+numNonIntersectingBladderVoxels;
numIntersectingRectumVoxels = nnz(rectumIntersecting);
numNonIntersectingRectumVoxels = nnz(rectumNonIntersecting);
%numRectumVoxels=numIntersectingRectumVoxels+numNonIntersectingRectumVoxels;
numPtvVoxels = nnz(ptvOutline3D);
bladderIntersectingSub = zeros(numIntersectingBladderVoxels,4);
bladderNonIntersectingSub = zeros(numNonIntersectingBladderVoxels,4);
rectumIntersectingSub = zeros(numIntersectingRectumVoxels,4);
rectumNonIntersectingSub = zeros(numNonIntersectingRectumVoxels,4);
ptvSub = zeros(numPtvVoxels,3);

%FIND LINEAR INDICES OF ALL NON ZERO VOXELS
bladderIntersectingLin = find(bladderIntersecting);
bladderNonIntersectingLin = find(bladderNonIntersecting);
rectumIntersectingLin = find(rectumIntersecting);
rectumNonIntersectingLin = find(rectumNonIntersecting);
ptvLin = find(ptvOutline3D);

%CONVERT LINEAR INDICES TO SUBSCRIPTS
%bladderIntersectingSub is an nx4 array, where n is the number of bladder
%voxels, and each row of the array contains the pixel coordinates of a
%voxel and the minimum distance to the PTV surface of that voxel
[bladderIntersectingSub(:,1), bladderIntersectingSub(:,2), bladderIntersectingSub(:,3)] = ind2sub(size(bladderIntersecting),bladderIntersectingLin);
[bladderNonIntersectingSub(:,1), bladderNonIntersectingSub(:,2), bladderNonIntersectingSub(:,3)] = ind2sub(size(bladderNonIntersecting),bladderNonIntersectingLin); 
[rectumIntersectingSub(:,1), rectumIntersectingSub(:,2), rectumIntersectingSub(:,3)] = ind2sub(size(rectumIntersecting),rectumIntersectingLin);
[rectumNonIntersectingSub(:,1), rectumNonIntersectingSub(:,2), rectumNonIntersectingSub(:,3)] = ind2sub(size(rectumNonIntersecting),rectumNonIntersectingLin);
[ptvSub(:,1), ptvSub(:,2), ptvSub(:,3)] = ind2sub(size(ptvOutline3D),ptvLin);

%% WEIGHTED EUCLIDEAN DISTANCE
% d((i,j,k),(a,b,c))=sqrt[1(i-a)^2+alpha(j-b)^2+beta(k-c)^2], where the
% ratio of the sampling intervals in the three axes is 1:alpha:beta for
% row:column:plane viz 1:columnSpacing/rowSpacing:heightSpacing/rowSpacing
alpha = columnSpacing/rowSpacing;
beta = sliceSpacing/rowSpacing;

%% CALCULATE MINIMUM DISTANCE FROM EACH OAR POINT TO THE PTV OUTLINE 

%BLADDER
for oarVoxel = 1:numIntersectingBladderVoxels
    minimumDistance=1000000;
    for ptvVoxel = 1:numPtvVoxels
        distance = sqrt((ptvSub(ptvVoxel,1)-bladderIntersectingSub(oarVoxel,1))^2+(alpha*(ptvSub(ptvVoxel,2)-bladderIntersectingSub(oarVoxel,2)))^2+(beta*(ptvSub(ptvVoxel,3)-bladderIntersectingSub(oarVoxel,3)))^2);
        minimumDistance = min(minimumDistance, distance);
    end
    bladderIntersectingSub(oarVoxel,4) = -1*minimumDistance;
end
% Ideal histogram bin width (Scott's formula) 
% bin width = 2*IQR(sample values)*N^(-1/3)
% where IQR is Inter Quartile Range
% sample values are all the distance values
% N is the total number of samples i.e. total number of voxels

bladderIntersectingBinWidth = 2*iqr(bladderIntersectingSub(:,4))*(numIntersectingBladderVoxels^(-1/3));
numBins_bladderIntersecting = (max(bladderIntersectingSub(:,4))-min(bladderIntersectingSub(:,4)))/bladderIntersectingBinWidth;

[v_bladderIntersecting, r_bladderIntersecting] = hist(bladderIntersectingSub(:,4),numBins_bladderIntersecting);

%RECTUM
for oarVoxel = 1:numIntersectingRectumVoxels
    minimumDistance=1000000;
    for ptvVoxel = 1:numPtvVoxels
        distance = sqrt((ptvSub(ptvVoxel,1)-rectumIntersectingSub(oarVoxel,1))^2+(alpha*(ptvSub(ptvVoxel,2)-rectumIntersectingSub(oarVoxel,2)))^2+(beta*(ptvSub(ptvVoxel,3)-rectumIntersectingSub(oarVoxel,3)))^2);
        minimumDistance = min(minimumDistance, distance);
    end
    rectumIntersectingSub(oarVoxel,4) = -1*minimumDistance;
end

rectumIntersectingBinWidth = 2*iqr(rectumIntersectingSub(:,4))*(numIntersectingRectumVoxels^(-1/3));
numBins_rectumIntersecting = (max(rectumIntersectingSub(:,4))-min(rectumIntersectingSub(:,4)))/rectumIntersectingBinWidth;

[v_rectumIntersecting, r_rectumIntersecting] = hist(rectumIntersectingSub(:,4),numBins_rectumIntersecting);

%% do for Non Intersecting part of the ROI

%BLADDER
for oarVoxel = 1:numNonIntersectingBladderVoxels
    minimumDistance=1000000;
    for ptvVoxel = 1:numPtvVoxels
        distance = sqrt((ptvSub(ptvVoxel,1)-bladderNonIntersectingSub(oarVoxel,1))^2+(alpha*(ptvSub(ptvVoxel,2)-bladderNonIntersectingSub(oarVoxel,2)))^2+(beta*(ptvSub(ptvVoxel,3)-bladderNonIntersectingSub(oarVoxel,3)))^2);
        minimumDistance = min(minimumDistance, distance);
    end
    bladderNonIntersectingSub(oarVoxel,4) = minimumDistance;
end


bladderNonIntersectingBinWidth = 2*iqr(bladderNonIntersectingSub(:,4))*(numNonIntersectingBladderVoxels^(-1/3));
numBins_bladderNonIntersecting = (max(bladderNonIntersectingSub(:,4))-min(bladderNonIntersectingSub(:,4)))/bladderNonIntersectingBinWidth;

[v_bladderNonIntersecting, r_bladderNonIntersecting] = hist(bladderNonIntersectingSub(:,4),numBins_bladderNonIntersecting);

%RECTUM
for oarVoxel = 1:numNonIntersectingRectumVoxels
    minimumDistance=1000000;
    for ptvVoxel = 1:numPtvVoxels
        distance = sqrt((ptvSub(ptvVoxel,1)-rectumNonIntersectingSub(oarVoxel,1))^2+(alpha*(ptvSub(ptvVoxel,2)-rectumNonIntersectingSub(oarVoxel,2)))^2+(beta*(ptvSub(ptvVoxel,3)-rectumNonIntersectingSub(oarVoxel,3)))^2);
        minimumDistance = min(minimumDistance, distance);
    end
    rectumNonIntersectingSub(oarVoxel,4) = minimumDistance;
end

rectumNonIntersectingBinWidth = 2*iqr(rectumNonIntersectingSub(:,4))*(numNonIntersectingRectumVoxels^(-1/3));
numBins_rectumNonIntersecting = (max(rectumNonIntersectingSub(:,4))-min(rectumNonIntersectingSub(:,4)))/rectumNonIntersectingBinWidth;

[v_rectumNonIntersecting, r_rectumNonIntersecting] = hist(rectumNonIntersectingSub(:,4),numBins_rectumNonIntersecting);

%% CALCULATE OVH PARAMETERS AND PLOT OVH
bladderVolume = sum(sum(sum(bladderBlock)));
r_bladder = horzcat(r_bladderIntersecting, r_bladderNonIntersecting);
v_bladder = (horzcat(v_bladderIntersecting, v_bladderNonIntersecting));
vp_bladder = v_bladder./(bladderVolume/100);
cum_v_bladder = cumsum(vp_bladder);
figure, plot(r_bladder, cum_v_bladder, '-r');
title('Overlap Volume Histogram');
xlabel('Distance in mm');
ylabel('Percentage Volume of ROI');
hold on;

rectumVolume = sum(sum(sum(rectumBlock)));
r_rectum = horzcat(r_rectumIntersecting, r_rectumNonIntersecting);
v_rectum = (horzcat(v_rectumIntersecting, v_rectumNonIntersecting));
vp_rectum = v_rectum./(rectumVolume/100);
cum_v_rectum = cumsum(vp_rectum);
plot(r_rectum, cum_v_rectum, '-k');
legend('Bladder','Rectum','Location','BestOutside');

bladderR50 = findX(r_bladder,cum_v_bladder,50);
bladderR75 = findX(r_bladder,cum_v_bladder,75);
bladderR90 = findX(r_bladder,cum_v_bladder,90);
rectumR50 = findX(r_rectum,cum_v_rectum,50);
rectumR75 = findX(r_rectum,cum_v_rectum,75);
rectumR90 = findX(r_rectum,cum_v_rectum,90);


%%CALCULATE NORMALIZED HISTOGRAM
bladderArea = bladderIntersectingBinWidth*numIntersectingBladderVoxels+bladderNonIntersectingBinWidth*numNonIntersectingBladderVoxels;
rectumArea = rectumIntersectingBinWidth*numIntersectingRectumVoxels+rectumNonIntersectingBinWidth*numNonIntersectingRectumVoxels;
v_bladderNorm = horzcat(((v_bladderIntersecting*bladderIntersectingBinWidth)/bladderArea),((v_bladderNonIntersecting*bladderNonIntersectingBinWidth)/bladderArea));
v_rectumNorm = horzcat(((v_rectumIntersecting*rectumIntersectingBinWidth)/rectumArea),((v_rectumNonIntersecting*rectumNonIntersectingBinWidth)/rectumArea));

figure;
plot(r_bladder,v_bladderNorm);
hold on;
plot(r_rectum,v_rectumNorm);
%% UPDATE THE DATABASE

% mysql(horzcat('UPDATE volume_distance SET V50Distance="',num2str(bladderR50),'", V75Distance="',num2str(bladderR75),'", V90Distance="',num2str(bladderR90),'" WHERE fk_patient_id="',num2str(patient_id),'" AND ROIName="Bladder"'));
% mysql(horzcat('UPDATE volume_distance SET V50Distance="',num2str(rectumR50),'", V75Distance="',num2str(rectumR75),'", V90Distance="',num2str(rectumR90),'" WHERE fk_patient_id="',num2str(patient_id),'" AND ROIName="Rectum"'));
% mysql('close');