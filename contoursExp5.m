%assumes that one plane has only one contour

clear all;

%*********************************
% SET INITIAL PARAMETERS
ROI_num=3;
patient_number = 4;
rowSpacing = 0.9765;
columnSpacing = 0.9765;
sliceSpacing = 1.5;

folder = strcat('UCLA_PR_',num2str(patient_number));
dose_file = strcat('UCLA_PR_',num2str(patient_number),'/structureset.dcm');

si=dicominfo(dose_file);
numStructures=length(fieldnames(si.StructureSetROISequence));%total number of structures in the structure set
% ********************************

% ********************************
% To CREATE MAPPING OF ROI NUMBER AND NAMES
% (double check logic)
roi=cell(numStructures,1);
for j = 1:numStructures
    temp=strcat('Item_',num2str(j));% to generate strings 'Item_1','Item_2', etc.
    id=si.StructureSetROISequence.(temp).ROINumber;
    roi{id,1}=si.StructureSetROISequence.(temp).ROIName;
end
% ********************************

% *********************************
% To DETERMINE ITEM NUMBER CORRESPONDING TO ROI NUMBER in ROI Contour
% Sequence object

numContourSeqs = length(fieldnames(si.ROIContourSequence));
for k = 1:numContourSeqs
    temp=strcat('Item_',num2str(k));
    current_roi_number=si.ROIContourSequence.(temp).ReferencedROINumber;
    if current_roi_number==ROI_num
        ROI_Item_no=strcat('Item_',num2str(k));
    end
end
% **********************************


% **********************************
% DETERMINE NUMBER OF CONTOUR PLANES for selected ROI
%numROIs = length(fieldnames(si.ROIContourSequence));%num of ROIs for which contours are available
numPlanes=length(fieldnames(si.ROIContourSequence.(ROI_Item_no).ContourSequence));%number of planes 
% for which contour data is available for this ROI

roiBlock=zeros(512,512,numPlanes);
imageBlock=zeros(512,512,numPlanes);
% **********************************


for plane = 1:numPlanes % for each contour plane of the selected ROI
    
    item=strcat('Item_',num2str(plane));%generate sequence of items  - Item_1, Item_2, etc.
    cdata=si.ROIContourSequence.(ROI_Item_no).ContourSequence.(item).ContourData;%get contour data points for a particular ROI, in a particular plane
    z=cdata(3);%get z coordinate for the plane
    ImageSOP = si.ROIContourSequence.(ROI_Item_no).ContourSequence.(item).ContourImageSequence.Item_1.ReferencedSOPInstanceUID;% get SOP UID of associated image
    roiNum=si.ROIContourSequence.(ROI_Item_no).ReferencedROINumber;%retrieve the ROI ID
    selectedStructure=roi(roiNum);%give name of selected structure using the roi ID
    imagei = dicominfo(strcat(folder,'/CT.',ImageSOP,'.dcm'));% get dicom metadata of assoc image
    image = im2double(dicomread(strcat(folder,'/CT.',ImageSOP,'.dcm')));%get assoc. image
    rowSpacing = imagei.PixelSpacing(1);
    columnSpacing = imagei.PixelSpacing(2);
    sliceSpacing = imagei.SliceThickness;%assume slice thickness is always set and that there is no gap b/w slices
    
    %correspondingZ = imagei.ImagePositionPatient(3);%to check if slice location of contour plane and image plane match; corrZ is z of the image plane

    [x y] =size(cdata);%get number of elements in cdata, which is a 1d array (is number of contour points)

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
    
    temp=length(cdata)/3;%number of x points, and therefor also the number of y points and number of z points
    rowCoords=zeros(temp,1);%an array of all the row coordinates initialized
    colCoords=zeros(temp,1);%an array of all the column coordinates initialized

    count=1;
    for i=1:3:x 
        px=cdata(i);%x coordinate from cdata, which contains the x,y and z coordinates in a single 1D array
        py=cdata(i+1);%y coordinate from cdata
        pz=cdata(i+2);%z coordinate form cdata

        A=[xx*delI yx*delJ; xy*delI yy*delJ];
        b=[px-sx; py-sy];
        v=A\b; %backward slash not forward slash

        colCoords(count)=round(v(1));%j - pixel coordinate for the column
        rowCoords(count)=round(v(2));%i - pixel coordinate for the row
        count=count+1;
    end

    polyMask=poly2mask(colCoords,rowCoords,512,512);%1s (ones) represent the structure; is an ROI mask
    imageMod=image+0.01*polyMask;%a way to visualize the mask
    %figure, imshow(image,[]);
    %figure,imshow(imageMod,[]);
    %figure, imshow(polyMask);
    roiBlock(:,:,plane)=polyMask;
    imageBlock(:,:,plane)=image;
    
end

% **********************************
% DIVIDE THE FIRST AND LAST PLANES BY 2 (first and last planes must be
% multiplied by only half the slice spacing)
roiBlock(:,:,:)=roiBlock(:,:,:)*sliceSpacing*rowSpacing*columnSpacing;
roiBlock(:,:,1)=roiBlock(:,:,1)/2;
roiBlock(:,:,numPlanes)=roiBlock(:,:,numPlanes)/2;
% **********************************

row_fcn = @(x) (x(2,2) ~= 0) && ~((x(2,1)==0)&&(x(2,3)==0)) && ~((x(2,1)==1)&&(x(2,3)==1));
column_fcn = @(y) (y(2,2) ~= 0) && ~((y(1,2)==0)&&(y(3,2)==0)) && ~((y(1,2)==1)&&(y(3,2)==1));
row_lut = makelut(row_fcn, 3);
column_lut = makelut(column_fcn, 3);

roiBlock_rowEdge = zeros(512,512,numPlanes);
roiBlock_columnEdge = zeros(512,512,numPlanes);

for l = 1:numPlanes
    roiBlock_rowEdge(:,:,l) = applylut(roiBlock(:,:,l),row_lut);
    roiBlock_columnEdge(:,:,l) = applylut(roiBlock(:,:,l), column_lut);
end

roiBlock_rowEdge(roiBlock_rowEdge==1)=0.5;
roiBlock_rowEdge(roiBlock_rowEdge==0)=1;
roiBlock_columnEdge(roiBlock_columnEdge==1)=0.5;
roiBlock_columnEdge(roiBlock_columnEdge==0)=1;

disp(selectedStructure);
output = roiBlock.*roiBlock_rowEdge.*roiBlock_columnEdge;
volume=sum(sum(sum(output)))/1000;
disp(volume);

