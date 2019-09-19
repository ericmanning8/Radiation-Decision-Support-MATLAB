%function [roiBlock, contourBlock] = getContoursFull(structureSetInfo, ROI_Item_no, width, height, patient_number)
% gets contours for the entire CT block

containing_folder = strcat('PT/06216287/1.3.51.0.1.1.172.16.20.234.6081352.2950264/1.2.840.113619.2.55.3.3314508558.778.1250723131.71');
imageList = dir(fullfile(containing_folder, '*.dcm'));
numImages = size(imageList);
imageBlock=zeros(512,512,numImages(1));
for i=1:numImages(1)
    imageBlock(:,:,i)=dicomread(strcat(containing_folder,'/',imageList(i).name));

end

