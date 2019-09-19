%assumes that one plane has only one contour

clear all;

Item_Number='8';

str_info=dicominfo('UCLA_PR_3/structureset.dcm');
numStructures=length(fieldnames(str_info.StructureSetROISequence));%total number of structures in the structure set
roi=cell(numStructures,1);

for i = 1:numStructures
    temp=strcat('Item_',num2str(i));
    id=str_info.StructureSetROISequence.(temp).ROINumber;
    roi{id,1}=str_info.StructureSetROISequence.(temp).ROIName;
end

numROIs = length(fieldnames(str_info.ROIContourSequence));%num of ROIs for which contours are available

numPlanes=length(fieldnames(str_info.ROIContourSequence.Item_8.ContourSequence));%number of planes for which contour data is available for this ROI

roiBlock=zeros(512,512,numPlanes);
imageBlock=zeros(512,512,numPlanes);

for plane = 1:numPlanes
    
    item=strcat('Item_',num2str(plane));
    %Item 4 - Bladder; Item 7 - Rectum
    cdata=str_info.ROIContourSequence.Item_8.ContourSequence.(item).ContourData;%get contour data points for a particular ROI, in a particular plane
    z=cdata(3);%get z coordinate for the plane
    ImageSOP = str_info.ROIContourSequence.Item_8.ContourSequence.Item_23.ContourImageSequence.Item_1.ReferencedSOPInstanceUID;% get SOP UID of associated image
    roiNum=str_info.ROIContourSequence.Item_8.ReferencedROINumber;%retrieve the ROI ID
    selectedStructure=roi(roiNum);%give name of selected structure using the roi ID
    imagei = dicominfo(strcat('UCLA_PR_3/CT.',ImageSOP,'.dcm'));% get dicom metadata of assoc image
    image = im2double(dicomread(strcat('UCLA_PR_3/CT.',ImageSOP,'.dcm')));%get assoc. image
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

    polyMask=poly2mask(colCoords,rowCoords,512,512);%1s are represent the structure; is an ROI mask
    imageMod=image+0.01*polyMask;%a way to visualize the mask
    %figure, imshow(image,[]);
    %figure,imshow(imageMod,[]);
    %figure, imshow(polyMask);
    %title(z);
    roiBlock(:,:,plane)=polyMask;
    imageBlock(:,:,plane)=image;
    
end

disp(selectedStructure);
