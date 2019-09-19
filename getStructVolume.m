function volume = getStructVolume(ROI_num, patient_number)

%*********************************

folder = strcat('UCLA_PR_',num2str(patient_number));
dose_file = strcat('UCLA_PR_',num2str(patient_number),'/structureset.dcm');
si=dicominfo(dose_file);
numStructures=length(fieldnames(si.StructureSetROISequence));%total number of structures in the structure set

image1_SOP = si.ReferencedFrameOfReferenceSequence.Item_1.RTReferencedStudySequence.Item_1.RTReferencedSeriesSequence.Item_1.ContourImageSequence.Item_1.ReferencedSOPInstanceUID;
image2_SOP = si.ReferencedFrameOfReferenceSequence.Item_1.RTReferencedStudySequence.Item_1.RTReferencedSeriesSequence.Item_1.ContourImageSequence.Item_2.ReferencedSOPInstanceUID;
image1i = dicominfo(strcat(folder,'/CT.',image1_SOP,'.dcm'));
image2i = dicominfo(strcat(folder,'/CT.',image2_SOP,'.dcm'));

rowSpacing = image1i.PixelSpacing(1);
columnSpacing = image1i.PixelSpacing(2);

slice1_location = image1i.ImagePositionPatient(3);
slice2_location = image2i.ImagePositionPatient(3);
sliceSpacing = abs(slice1_location-slice2_location);

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

numPlanes=length(fieldnames(si.ROIContourSequence.(ROI_Item_no).ContourSequence));%number of planes 


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

roiBlock = getStructMask(ROI_num, patient_number);

% **********************************
% DIVIDE THE FIRST AND LAST PLANES BY 2 (first and last planes must be
% multiplied by only half the slice spacing)
roiBlock(:,:,:)=roiBlock(:,:,:)*sliceSpacing*rowSpacing*columnSpacing;
roiBlock(:,:,1)=roiBlock(:,:,1)/2;
roiBlock(:,:,numPlanes)=roiBlock(:,:,numPlanes)/2;
% **********************************

% **********************************
% create LUT for determining which pixels are on the edges
row_fcn = @(x) (x(2,2) ~= 0) && ~((x(2,1)==0)&&(x(2,3)==0)) && ~((x(2,1)==1)&&(x(2,3)==1));
%function handle specifies rules for determining which pixels have an on
%pixel on either their left or right side (not both)
column_fcn = @(y) (y(2,2) ~= 0) && ~((y(1,2)==0)&&(y(3,2)==0)) && ~((y(1,2)==1)&&(y(3,2)==1));
%function handle specifies rules for determining which pixels have an on
%pixel on either their top or bottom side (not both)
row_lut = makelut(row_fcn, 3);
column_lut = makelut(column_fcn, 3);

roiBlock_rowEdge = zeros(512,512,numPlanes);
roiBlock_columnEdge = zeros(512,512,numPlanes);

for l = 1:numPlanes % apply LUT to all planes
    roiBlock_rowEdge(:,:,l) = applylut(roiBlock(:,:,l),row_lut);
    roiBlock_columnEdge(:,:,l) = applylut(roiBlock(:,:,l), column_lut);
end
% **********************************

% **********************************
%convert all 'on' pixels to 0.5; 0 to 1; 
roiBlock_rowEdge(roiBlock_rowEdge==1)=0.5;
roiBlock_rowEdge(roiBlock_rowEdge==0)=1;
roiBlock_columnEdge(roiBlock_columnEdge==1)=0.5;
roiBlock_columnEdge(roiBlock_columnEdge==0)=1;
% **********************************

%disp(selectedStructure);
output = roiBlock.*roiBlock_rowEdge.*roiBlock_columnEdge;
volume=sum(sum(sum(output)))/1000;

% 1. work on determination of pixel spacing and slice spacing

end