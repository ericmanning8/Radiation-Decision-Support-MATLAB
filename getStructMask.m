function [mask] = getStructMask(ROI_num, patient_number)

%assumes that one plane has only one contour

%*********************************
folder = strcat('UCLA_PR_',num2str(patient_number));
dose_file = strcat('UCLA_PR_',num2str(patient_number),'/structureset.dcm');

si=dicominfo(dose_file);
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

mask=zeros(512,512,numPlanes);%use functions to determine image size
% **********************************


for plane = 1:numPlanes % for each contour plane of the selected ROI
    
    item=strcat('Item_',num2str(plane));%generate sequence of items  - Item_1, Item_2, etc.
    cdata=si.ROIContourSequence.(ROI_Item_no).ContourSequence.(item).ContourData;%get contour data points for a particular ROI, in a particular plane
    z=cdata(3);%get z coordinate for the plane
    ImageSOP = si.ROIContourSequence.(ROI_Item_no).ContourSequence.(item).ContourImageSequence.Item_1.ReferencedSOPInstanceUID;% get SOP UID of associated image
    roiNum=si.ROIContourSequence.(ROI_Item_no).ReferencedROINumber;%retrieve the ROI ID
    %selectedStructure=roi(roiNum);%give name of selected structure using the roi ID
    imagei = dicominfo(strcat(folder,'/CT.',ImageSOP,'.dcm'));% get dicom metadata of assoc image
    
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
    % read help; substitute x with x.5 to ensure that all coordinates are
    % included?
    mask(:,:,plane)=polyMask;
    
end

