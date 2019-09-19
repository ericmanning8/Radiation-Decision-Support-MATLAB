si=dicominfo('UCLA_PR_3/structureset.dcm');
numStructures=length(fieldnames(si.StructureSetROISequence));%total number of structures in the structure set
roi=cell(numStructures,1);

for i = 1:numStructures
    temp=strcat('Item_',num2str(i));
    id=si.StructureSetROISequence.(temp).ROINumber;
    xyz=si.StructureSetROISequence.(temp).ROIName;
    roi{id,1}=si.StructureSetROISequence.(temp).ROIName;
end

numROIs = length(fieldnames(si.ROIContourSequence));%num of ROIs for which contours are available



cdata=si.ROIContourSequence.Item_4.ContourSequence.Item_23.ContourData;%get contour data points for a particular ROI, in a particular plane
z=cdata(3);%get z coordinate for the plane
ImageSOP = si.ROIContourSequence.Item_4.ContourSequence.Item_23.ContourImageSequence.Item_1.ReferencedSOPInstanceUID;% get SOP UID of associated image
roiNum=si.ROIContourSequence.Item_4.ReferencedROINumber;%retrieve the ROI ID
selectedStructure=roi(roiNum);%give name of selected structure using the roi ID
imagei = dicominfo(strcat('UCLA_PR_3/CT.',ImageSOP,'.dcm'));% get dicom metadata of assoc image
image = dicomread(strcat('UCLA_PR_3/CT.',ImageSOP,'.dcm'));%get assoc. image
imageOrig=im2double(image);%copy of the original image converted to type double
correspondingZ = imagei.ImagePositionPatient(3);%to check if slice location of contour plane and image plane match; corrZ is z of the image plane

%disp(z);
%disp(correspondingZ);

[x y] =size(cdata);%get number of elements in cdata, which is a 1d array (is number of contour points)
%disp(x)
image=im2double(image);
m=max(max(image));%maximum value

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
xCoords=zeros(temp,1);%an array of all the x coords in the patient coordinate system initialized
yCoords=zeros(temp,1);
%imageMap=zeros(size(image));

count=1;
for i=1:3:x % only rowCoors and colCoors are needed from this loop
    px=cdata(i);%x coordinate from cdata, which contains the x,y and z coordinates in a single 1D array
    py=cdata(i+1);%y coordinate from cdata
    pz=cdata(i+2);%z coordinate form cdata
    
    A=[xx*delI yx*delJ; xy*delI yy*delJ];
    b=[px-sx; py-sy];
    v=A\b; %backward slash not forward slash
    
    j=round(v(1));
    k=round(v(2));
    
    xCoords(count)=px;
    yCoords(count)=py;
    rowCoords(count)=k;
    colCoords(count)=j;
    
    image(k,j)=m;
    %imageMap(k,j)=1;
    
    count=count+1;
end

imshow(image,[]);
%figure, fill(colCoords, rowCoords,'r');
%figure, fill(xCoords, yCoords,'r');
disp(selectedStructure);
disp(z);

polyMask=poly2mask(colCoords,rowCoords,512,512);
imageMod=imageOrig+0.005*polyMask;
figure,imshow(imageMod,[]);
