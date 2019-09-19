function [ovh] = getOvh(patient_number, oar)

%% SET INITIAL PARAMETERS

containing_folder = strcat('UCLA_PR_',num2str(patient_number));%create folder path from patient number
structureset_file_path = strcat('UCLA_PR_',num2str(patient_number),'/structureset.dcm');%create pathname for structure set file

structureSetInfo=dicominfo(structureset_file_path);%structure set file metadata
numStructures=length(fieldnames(structureSetInfo.StructureSetROISequence));%total number of structures in the structure set

%% To CREATE MAPPING OF ROI NUMBER AND NAMES
roiList=cell(numStructures,2);
for j = 1:numStructures
    item_number_string=strcat('Item_',num2str(j));% to generate strings 'Item_1','Item_2', etc.
    roiID=structureSetInfo.StructureSetROISequence.(item_number_string).ROINumber;
    roiName=structureSetInfo.StructureSetROISequence.(item_number_string).ROIName;%column 1 contains names
    roiList{roiID,1}=roiName;
    roiList{roiID,2}=roiID;%column 2 contains ROI Numbers
    if strcmpi(roiName,'ptv')
        ptvID = roiID;
    end
    if strcmpi(roiName,oar)
        oarID = roiID;
    end
        
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
    if current_roi_number==oarID
        oar_Item_no=strcat('Item_',num2str(k));
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
 
ptvBlock=getContoursFull(structureSetInfo, ptv_Item_no, width, height, patient_number);
oarBlock=getContoursFull(structureSetInfo, oar_Item_no, width, height, patient_number);

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

oarIntersecting = oarBlock&ptvBlock;
oarNonIntersecting = oarBlock - oarIntersecting;

%% Get positions of all ON pixels in the organ masks and the smooth ptv contour object
% oarSub contains pixel positions of all ON pixels in the solid oar
% mask, and rectumSub for the rectum. ptvSub has pixel positions of all ON
% pixels in the smoothened outline mask of the ptv

%INITIALIZE
numIntersectingOarVoxels = nnz(oarIntersecting);
numNonIntersectingOarVoxels = nnz(oarNonIntersecting);
numPtvVoxels = nnz(ptvOutline3D);
oarIntersectingSub = zeros(numIntersectingOarVoxels,4);
oarNonIntersectingSub = zeros(numNonIntersectingOarVoxels,4);
ptvSub = zeros(numPtvVoxels,3);

%FIND LINEAR INDICES OF ALL NON ZERO VOXELS
oarIntersectingLin = find(oarIntersecting);
oarNonIntersectingLin = find(oarNonIntersecting);
ptvLin = find(ptvOutline3D);

%CONVERT LINEAR INDICES TO SUBSCRIPTS
[oarIntersectingSub(:,1), oarIntersectingSub(:,2), oarIntersectingSub(:,3)] = ind2sub(size(oarIntersecting),oarIntersectingLin);
[oarNonIntersectingSub(:,1), oarNonIntersectingSub(:,2), oarNonIntersectingSub(:,3)] = ind2sub(size(oarNonIntersecting),oarNonIntersectingLin); 
[ptvSub(:,1), ptvSub(:,2), ptvSub(:,3)] = ind2sub(size(ptvOutline3D),ptvLin);

%% WEIGHTED EUCLIDEAN DISTANCE
% d((i,j,k),(a,b,c))=sqrt[1(i-a)^2+alpha(j-b)^2+beta(k-c)^2], where the
% ratio of the sampling intervals in the three axes is 1:alpha:beta for
% row:column:plane viz 1:columnSpacing/rowSpacing:heightSpacing/rowSpacing
alpha = columnSpacing/rowSpacing;
beta = sliceSpacing/rowSpacing;

%% CALCULATE MINIMUM DISTANCE FROM EACH OAR POINT TO THE PTV OUTLINE (currently for oarIntersecting

for oarVoxel = 1:numIntersectingOarVoxels
    minimumDistance=1000000;
    for ptvVoxel = 1:numPtvVoxels
        distance = sqrt((ptvSub(ptvVoxel,1)-oarIntersectingSub(oarVoxel,1))^2+(alpha*(ptvSub(ptvVoxel,2)-oarIntersectingSub(oarVoxel,2)))^2+(beta*(ptvSub(ptvVoxel,3)-oarIntersectingSub(oarVoxel,3)))^2);
        minimumDistance = min(minimumDistance, distance);
    end
    oarIntersectingSub(oarVoxel,4) = -1*minimumDistance;
end
[v_oarIntersecting, r_oarIntersecting] = hist(oarIntersectingSub(:,4));

%% do for Non Intersecting part of the Oar

for oarVoxel = 1:numNonIntersectingOarVoxels
    minimumDistance=1000000;
    for ptvVoxel = 1:numPtvVoxels
        distance = sqrt((ptvSub(ptvVoxel,1)-oarNonIntersectingSub(oarVoxel,1))^2+(alpha*(ptvSub(ptvVoxel,2)-oarNonIntersectingSub(oarVoxel,2)))^2+(beta*(ptvSub(ptvVoxel,3)-oarNonIntersectingSub(oarVoxel,3)))^2);
        minimumDistance = min(minimumDistance, distance);
    end
    oarNonIntersectingSub(oarVoxel,4) = minimumDistance;
end
[v_oarNonIntersecting, r_oarNonIntersecting] = hist(oarNonIntersectingSub(:,4));

%%

r_oar = horzcat(r_oarIntersecting, r_oarNonIntersecting);
v_oar = horzcat(v_oarIntersecting, v_oarNonIntersecting);
cum_v_oar = cumsum(v_oar);
figure, plot(r_oar, cum_v_oar);
ovh(:,1)=r_oar;
ovh(:,2)=v_oar;

% Two points to consider - 1) Units 2) Bin width of the histograms


