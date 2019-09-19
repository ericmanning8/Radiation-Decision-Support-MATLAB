function [roiBlock, contourBlock] = getContours(structureSetInfo, ROI_Item_no, width, height, patient_number)

roiNumPlanes=length(fieldnames(structureSetInfo.ROIContourSequence.(ROI_Item_no).ContourSequence));%number of planes for which contour data is available for this ROI
roiBlock=zeros(width,height,roiNumPlanes);%use functions to determine image size
contourBlock=zeros(width,height,roiNumPlanes);
containing_folder = strcat('UCLA_PR_',num2str(patient_number));

for planeIndex = 1:roiNumPlanes % for each contour plane of the selected ROI
    
    item_number_string=strcat('Item_',num2str(planeIndex));%generate sequence of items  - Item_1, Item_2, etc.
    planeContourData=structureSetInfo.ROIContourSequence.(ROI_Item_no).ContourSequence.(item_number_string).ContourData;%get contour data points for a particular ROI, in a particular plane
    %z=planeContourData(3);%get z coordinate for the plane
    ImageSOP = structureSetInfo.ROIContourSequence.(ROI_Item_no).ContourSequence.(item_number_string).ContourImageSequence.Item_1.ReferencedSOPInstanceUID;% get SOP UID of associated image
    %roiNum=structureSetInfo.ROIContourSequence.(ROI_Item_no).ReferencedROINumber;%retrieve the ROI ID
    %selectedStructure=roiList(roiNum,1);%give name of selected structure using the roi ID
    imagei = dicominfo(strcat(containing_folder,'/CT.',ImageSOP,'.dcm'));% get dicom metadata of assoc image
    %image = im2double(dicomread(strcat(containing_folder,'/CT.',ImageSOP,'.dcm')));%get assoc. image
    %correspondingZ = imagei.ImagePositionPatient(3);%to check if slice location of contour plane and image plane match; corrZ is z of the image plane

    [x y] =size(planeContourData);%get number of elements in planeContourData, which is a 1d array (is number of contour points)

    % **********************************
    % extracting information for converting to pixel coordinates
    xx=imagei.ImageOrientationPatient(1);
    xy=imagei.ImageOrientationPatient(2);
    %xz=imagei.ImageOrientationPatient(3);
    yx=imagei.ImageOrientationPatient(4);
    yy=imagei.ImageOrientationPatient(5);
    %yz=imagei.ImageOrientationPatient(6);
    sx=imagei.ImagePositionPatient(1);
    sy=imagei.ImagePositionPatient(2);
    %sz=imagei.ImagePositionPatient(3);
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
        %pz=planeContourData(i+2);%z coordinate form planeContourData

        A=[xx*delI yx*delJ; xy*delI yy*delJ];
        b=[px-sx; py-sy];
        v=A\b; %backward slash not forward slash

        colCoords(count)=round(v(1));%j - pixel coordinate for the column
        rowCoords(count)=round(v(2));%i - pixel coordinate for the row
        contourBlock(rowCoords(count),colCoords(count),planeIndex)=1;
        count=count+1;
    end
    
    polyMask=poly2mask(colCoords-correction,rowCoords-correction,double(height),double(width));%1s (ones) represent the structure; is an ROI mask
    roiBlock(:,:,planeIndex)=polyMask;
    
end