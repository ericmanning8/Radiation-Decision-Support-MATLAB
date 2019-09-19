%assumes that one plane has only one contour

clear all;

%*********************************
% SET INITIAL PARAMETERS
% for patient 4, ptv is 9, bladder is 2, rectum is 5
ptvID = 9;
bladderID = 2;
rectumID = 5;

ROI_num=3;
patient_number = 4;

containing_folder = strcat('UCLA_PR_',num2str(patient_number));%create folder path from patient number
structureset_file_path = strcat('UCLA_PR_',num2str(patient_number),'/structureset.dcm');%create pathname for structure set file

structureSetInfo=dicominfo(structureset_file_path);%structure set file metadata
numStructures=length(fieldnames(structureSetInfo.StructureSetROISequence));%total number of structures in the structure set
% ********************************

% ********************************
% To CREATE MAPPING OF ROI NUMBER AND NAMES
roiList=cell(numStructures,2);
for j = 1:numStructures
    item_number_string=strcat('Item_',num2str(j));% to generate strings 'Item_1','Item_2', etc.
    roiID=structureSetInfo.StructureSetROISequence.(item_number_string).ROINumber;
    roiList{roiID,1}=structureSetInfo.StructureSetROISequence.(item_number_string).ROIName;%column 1 contains names
    roiList{roiID,2}=roiID;%column 2 contains ROI Numbers
end
% ********************************

% *********************************
% To DETERMINE ITEM NUMBER CORRESPONDING TO ROI NUMBER in ROI Contour
% Sequence object

numContourSeqs = length(fieldnames(structureSetInfo.ROIContourSequence));
for k = 1:numContourSeqs
    item_number_string=strcat('Item_',num2str(k));
    current_roi_number=structureSetInfo.ROIContourSequence.(item_number_string).ReferencedROINumber;
    if current_roi_number==ROI_num
        ROI_Item_no=strcat('Item_',num2str(k));
    end
end
% **********************************

%*********************************
% DETERMINE ROW SPACING AND COLUMN SPACING
ImageSOP = structureSetInfo.ROIContourSequence.(ROI_Item_no).ContourSequence.Item_1.ContourImageSequence.Item_1.ReferencedSOPInstanceUID;
imagei = dicominfo(strcat(containing_folder,'/CT.',ImageSOP,'.dcm'));
rowSpacing = imagei.PixelSpacing(1);
columnSpacing = imagei.PixelSpacing(2);
sliceSpacing = imagei.SliceThickness;%assume slice thickness is always set and that there is no gap b/w slices
% **********************************


% **********************************
% DETERMINE NUMBER OF CONTOUR PLANES for selected ROI
%numROIs = length(fieldnames(structureSetInfo.ROIContourSequence));%num of ROIs for which contours are available
roiNumPlanes=length(fieldnames(structureSetInfo.ROIContourSequence.(ROI_Item_no).ContourSequence));%number of planes for which contour data is available for this ROI

roiBlock=zeros(512,512,roiNumPlanes);%use functions to determine image size
imageBlock=zeros(512,512,roiNumPlanes);
contourBlock=zeros(512,512,roiNumPlanes);
% **********************************


for planeIndex = 1:roiNumPlanes % for each contour plane of the selected ROI
    
    item_number_string=strcat('Item_',num2str(planeIndex));%generate sequence of items  - Item_1, Item_2, etc.
    planeContourData=structureSetInfo.ROIContourSequence.(ROI_Item_no).ContourSequence.(item_number_string).ContourData;%get contour data points for a particular ROI, in a particular plane
    z=planeContourData(3);%get z coordinate for the plane
    ImageSOP = structureSetInfo.ROIContourSequence.(ROI_Item_no).ContourSequence.(item_number_string).ContourImageSequence.Item_1.ReferencedSOPInstanceUID;% get SOP UID of associated image
    %roiNum=structureSetInfo.ROIContourSequence.(ROI_Item_no).ReferencedROINumber;%retrieve the ROI ID
    %selectedStructure=roiList(roiNum,1);%give name of selected structure using the roi ID
    imagei = dicominfo(strcat(containing_folder,'/CT.',ImageSOP,'.dcm'));% get dicom metadata of assoc image
    image = im2double(dicomread(strcat(containing_folder,'/CT.',ImageSOP,'.dcm')));%get assoc. image
    %correspondingZ = imagei.ImagePositionPatient(3);%to check if slice location of contour plane and image plane match; corrZ is z of the image plane

    [x y] =size(planeContourData);%get number of elements in planeContourData, which is a 1d array (is number of contour points)

    % **********************************
    % extracting information for converting to pixel coordinates
    xx=imagei.ImageOrientationPatient(1);
    xy=imagei.ImageOrientationPatient(2);
    xz=imagei.ImageOrientationPatient(3);
    yx=imagei.ImageOrientationPatient(4);
    yy=imagei.ImageOrientationPatient(5);
    yz=imagei.ImageOrientationPatient(6);
    sx=imagei.ImagePositionPatient(1);
    sy=imagei.ImagePositionPatient(2);
    sz=imagei.ImagePositionPatient(3);
    delJ=imagei.PixelSpacing(1);
    delI=imagei.PixelSpacing(2);
    % **********************************
    
    temp=length(planeContourData)/3;%number of x points, and therefor also the number of y points and number of z points
    rowCoords=zeros(temp,1);%an array of all the row coordinates initialized
    colCoords=zeros(temp,1);%an array of all the column coordinates initialized
    correction = zeros(temp,1);
    correction(:,1) = 0.5;%all coordinates must be changed from (x,y) to ((x-1).5, (y-1).5) to make sure that contour boundary pixels are also included in the object in poly2mask
    count=1;
    for i=1:3:x 
        px=planeContourData(i);%x coordinate from planeContourData, which contains the x,y and z coordinates in a single 1D array
        py=planeContourData(i+1);%y coordinate from planeContourData
        pz=planeContourData(i+2);%z coordinate form planeContourData

        A=[xx*delI yx*delJ; xy*delI yy*delJ];
        b=[px-sx; py-sy];
        v=A\b; %backward slash not forward slash

        colCoords(count)=round(v(1));%j - pixel coordinate for the column
        rowCoords(count)=round(v(2));%i - pixel coordinate for the row
        contourBlock(rowCoords(count),colCoords(count),planeIndex)=1;
        count=count+1;
    end

    polyMask=poly2mask(colCoords-correction,rowCoords-correction,512,512);%1s (ones) represent the structure; is an ROI mask
    imageMod=image+0.01*polyMask;%a way to visualize the mask
    roiBlock(:,:,planeIndex)=polyMask;
    imageBlock(:,:,planeIndex)=image;
    
end

%disp(selectedStructure);
%output = roiBlock.*roiBlock_rowEdge.*roiBlock_columnEdge;
%volume=sum(sum(sum(output)))/1000;
%disp(volume);

contour = contourBlock(:,:,50);
filledStructure = roiBlock(:,:,50);
smoothContour = bwperim(filledStructure);
imshow(contour);
figure, imshow(smoothContour);
figure, imshow(filledStructure);
