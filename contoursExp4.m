%assumes that one plane has only one contour

clear all;

%set parameters
ROI_num=7;
patient_number =1;

folder = strcat('UCLA_PR_',num2str(patient_number));
dose_file = strcat('UCLA_PR_',num2str(patient_number),'/structureset.dcm');

si=dicominfo(dose_file);
numStructures=length(fieldnames(si.StructureSetROISequence));%total number of structures in the structure set

% ********************************
% To create mapping of ROI number and names
% (double check logic)
roi=cell(numStructures,1);
for j = 1:numStructures
    temp=strcat('Item_',num2str(j));% to generate strings 'Item_1','Item_2', etc.
    id=si.StructureSetROISequence.(temp).ROINumber;
    roi{id,1}=si.StructureSetROISequence.(temp).ROIName;
end
% ********************************

% *********************************
% To determine Item number corresponding to the ROI number in ROI Contour
% Sequence object
%ROI_Item_no='';
numContourSeqs = length(fieldnames(si.ROIContourSequence));
for k = 1:numContourSeqs
    temp=strcat('Item_',num2str(k));
    current_roi_number=si.ROIContourSequence.(temp).ReferencedROINumber;
    if current_roi_number==ROI_num
        ROI_Item_no=strcat('Item_',num2str(k));
    end
end
% **********************************


numROIs = length(fieldnames(si.ROIContourSequence));%num of ROIs for which contours are available
numPlanes=length(fieldnames(si.ROIContourSequence.(ROI_Item_no).ContourSequence));%number of planes for which contour data is available for this ROI

roiBlock=zeros(512,512,numPlanes);
imageBlock=zeros(512,512,numPlanes);

for plane = 1:numPlanes
    
    item=strcat('Item_',num2str(plane));
    %Item 4 - Bladder; Item 7 - Rectum
    cdata=si.ROIContourSequence.(ROI_Item_no).ContourSequence.(item).ContourData;%get contour data points for a particular ROI, in a particular plane
    z=cdata(3);%get z coordinate for the plane
    ImageSOP = si.ROIContourSequence.(ROI_Item_no).ContourSequence.(item).ContourImageSequence.Item_1.ReferencedSOPInstanceUID;% get SOP UID of associated image
    roiNum=si.ROIContourSequence.(ROI_Item_no).ReferencedROINumber;%retrieve the ROI ID
    selectedStructure=roi(roiNum);%give name of selected structure using the roi ID
    imagei = dicominfo(strcat(folder,'/CT.',ImageSOP,'.dcm'));% get dicom metadata of assoc image
    image = im2double(dicomread(strcat(folder,'/CT.',ImageSOP,'.dcm')));%get assoc. image
    
    correspondingZ = imagei.ImagePositionPatient(3);%to check if slice location of contour plane and image plane match; corrZ is z of the image plane

    [x y] =size(cdata);%get number of elements in cdata, which is a 1d array (is number of contour points)

    %for coverting to pixel coordinates:
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
    %title(z);
    roiBlock(:,:,plane)=polyMask;
    imageBlock(:,:,plane)=image;
    
end

disp(selectedStructure);
vol=(nnz(roiBlock)*1.5*1.26*1.26)/1000;
disp(vol);
