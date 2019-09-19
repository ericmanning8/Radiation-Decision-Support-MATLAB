%assumes that one plane has only one contour

clear all;
str_info=dicominfo('UCLA_PR_3/structureset.dcm');
numStructures=length(fieldnames(str_info.StructureSetROISequence));%total number of structures in the structure set
roi=cell(numStructures,1);

for i = 1:numStructures
    temp=strcat('Item_',num2str(i));
    id=str_info.StructureSetROISequence.(temp).ROINumber;
    roi{id,1}=str_info.StructureSetROISequence.(temp).ROIName;
end

numROIs = length(fieldnames(str_info.ROIContourSequence));%num of ROIs for which contours are available

numPlanes=length(fieldnames(str_info.ROIContourSequence.Item_7.ContourSequence));%number of planes for which contour data is available for this ROI

roiBlock=zeros(512,512,numPlanes);
imageBlock=zeros(512,512,numPlanes);

Area=0;

for plane = 1:numPlanes
    
    item=strcat('Item_',num2str(plane));
    cdata=str_info.ROIContourSequence.Item_7.ContourSequence.(item).ContourData;%get contour data points for a particular ROI, in a particular plane
    z=cdata(3);%get z coordinate for the plane
    ImageSOP = str_info.ROIContourSequence.Item_7.ContourSequence.Item_23.ContourImageSequence.Item_1.ReferencedSOPInstanceUID;% get SOP UID of associated image
    roiNum=str_info.ROIContourSequence.Item_7.ReferencedROINumber;%retrieve the ROI ID
    selectedStructure=roi(roiNum);%give name of selected structure using the roi ID
    imagei = dicominfo(strcat('UCLA_PR_3/CT.',ImageSOP,'.dcm'));% get dicom metadata of assoc image
    image = im2double(dicomread(strcat('UCLA_PR_3/CT.',ImageSOP,'.dcm')));%get assoc. image
    correspondingZ = imagei.ImagePositionPatient(3);%to check if slice location of contour plane and image plane match; corrZ is z of the image plane
    
    cdata_x=zeros(length(cdata)/3,1);
    cdata_y=zeros(length(cdata)/3,1);
    count=1;
    for j = 1:3:length(cdata)
        cdata_x(count)=cdata(j);
        cdata_y(count)=cdata(j+1);
        count=count+1;
    end
    cArea=0;
    for k = 1:((length(cdata)/3)-1)
        cArea=cArea+(cdata_x(k)*cdata_y(k+1)-cdata_x(k+1)*cdata_y(k));
        cArea=abs(cArea/2);
    end
    Area=Area+cArea;
        
    
    
end

disp(Area);
