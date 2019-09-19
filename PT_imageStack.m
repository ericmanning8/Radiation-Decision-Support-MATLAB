%% assumes that one plane has only one contour

function PT_imageStack(patient_id,selectedROI)
%patient_id='06208549';
%selectedROI='Bladder';
color = [65 105 225; 124 252 0; 135 206 250; 255 255 0; 255 165 0; 255 20 147; 255 0 0; 51 255 255; 0 128 0; 32 178 170]/255; 
%% database init
conn = mysql('open','localhost','root');
mysql('use pt_pr_v1');

% if strcmp(selectedROI{1},'Bladder')
%        roiNumber='3';
% elseif strcmp(selectedROI{1},'Rectum')
%        roiNumber='2';
% elseif strcmp(selectedROI{1},'Prostate')
%        roiNumber='4';
% end
% disp(roiNumber);
%Since every contour has an associated CT Slice, extract the first ct image
%for the first roi
%disp(horzcat('SELECT ROINumber FROM structure_set_roi_sequence WHERE roiName="',selectedROI{1},'" AND fk_PatientID="',patient_id,'"'));
    
roiNumberSample = mysql(horzcat('SELECT ROINumber FROM structure_set_roi_sequence WHERE roiName="',selectedROI{1},'" AND fk_PatientID="',patient_id,'"'));    

[ct_SeriesInstanceUID, sample_ct_SOPInstanceUID] = mysql(horzcat('SELECT fk_CT_SeriesInstanceUID, fk_CT_SOPInstanceUID FROM seq_contour WHERE (fk_PatientID="',patient_id,'" AND fk_ReferencedROINumber="',num2str(roiNumberSample),'") LIMIT 1'));
disp(horzcat('SELECT fk_CT_SeriesInstanceUID, fk_CT_SOPInstanceUID FROM seq_contour WHERE (fk_PatientID="',patient_id,'" AND fk_ReferencedROINumber="',num2str(roiNumberSample),'") LIMIT 1'));
%disp(length(ct_SeriesInstanceUID));
numCTs = mysql(horzcat('SELECT numCTifCT FROM iod_general_series WHERE SeriesInstanceUID = "',ct_SeriesInstanceUID{1},'"'));%Get number of CT Images
%Get row spacing, slice spacing etc based on the sample ct image
[width, height]=mysql(horzcat('SELECT columns, rows FROM iod_image_pixel WHERE fk_SOPInstanceUID="',sample_ct_SOPInstanceUID{1},'"'));
imageBlock=zeros(height, width, numCTs);

%imgPosPatZ gives the z indices of all CT images. This is useful in
%assembling the CT Block
imgPosPatZ = sort(str2double(mysql(horzcat('SELECT imgPosPatZ FROM iod_image_plane WHERE fk_SeriesInstanceUID="',ct_SeriesInstanceUID{1},'"'))));
[ct_PatientIDs ct_StudyInstanceUIDs ct_SeriesInstanceUIDs  ct_SOPInstanceUIDs] = mysql(horzcat('SELECT fk_PatientID, fk_StudyInstanceUID, fk_SeriesInstanceUID, SOPInstanceUID FROM iod_ct_image WHERE fk_SeriesInstanceUID="',ct_SeriesInstanceUID{1},'"'));
ct_PatientIDs=cellstr(ct_PatientIDs);
ct_StudyInstanceUIDs=cellstr(ct_StudyInstanceUIDs);
ct_SeriesInstanceUIDs=cellstr(ct_SeriesInstanceUIDs);
ct_SOPInstanceUIDs=cellstr(ct_SOPInstanceUIDs);

for vv=1:length(ct_SOPInstanceUIDs)
        ct_z=str2double(mysql(horzcat('SELECT imgPosPatZ FROM iod_image_plane WHERE fk_SOPInstanceUID="',ct_SOPInstanceUIDs{vv},'"')));
        imageBlock(:,:,imgPosPatZ==ct_z)=im2double(dicomread(horzcat('/Users/ruchi/Documents/MATLAB/pt/',ct_PatientIDs{vv},'/',ct_StudyInstanceUIDs{vv},'/',ct_SeriesInstanceUIDs{vv},'/',ct_SOPInstanceUIDs{vv},'.dcm')));
end;

%% ************************* LOOP OVER EACH ROI *************************************
%% **********************************************************************************

imageBlockRGB=repmat(reshape(imageBlock,[height width 1 numCTs]),[1 1 3 1]);%Change to RGB
imageBlockRGBNorm=imageBlockRGB/max(max(max(max(imageBlockRGB))));%Normalize

for i=1:length(selectedROI) %For each ROI in the patient's ROI Sequence 
    
    roiNumber = mysql(horzcat('SELECT roiNumber FROM structure_set_roi_sequence WHERE roiName="',selectedROI{i},'" AND fk_PatientID="',patient_id,'"'));
    roiBlock=PT_getContoursFull2(patient_id, roiNumber);
    roiOutline3D = zeros(size(roiBlock));
    for j = 1:(size(roiBlock,3))
        roiOutline3D(:,:,j) = bwperim(roiBlock(:,:,j));
    end 
    disp(selectedROI{i});
    disp(horzcat(num2str(color(i,1)),',',num2str(color(i,2)),',',num2str(color(i,3))));
    for k=1:numCTs
        red=imageBlockRGBNorm(:,:,1,k);
        green=imageBlockRGBNorm(:,:,2,k);
        blue=imageBlockRGBNorm(:,:,3,k);
        red(roiOutline3D(:,:,k)==1)=color(i,1);
        green(roiOutline3D(:,:,k)==1)=color(i,2);
        blue(roiOutline3D(:,:,k)==1)=color(i,3);
        imageBlockRGBNorm(:,:,1,k)=red;
        imageBlockRGBNorm(:,:,2,k)=green;
        imageBlockRGBNorm(:,:,3,k)=blue;
    end;
    
end;   

global dicom_images;
dicom_images = imageBlockRGBNorm;

f = figure('Visible','on','Name','My GUI','Position',[360,500,600,600]);
% Create an axes object to show which color is selected

Img = axes('Parent',f,'units','pixels','Position',[50 50 512 512]);
% Create a slider to display the images
slider1 = uicontrol('Style', 'slider', 'Parent', f, 'String', 'Image No.', 'Callback', @slider_callback, 'Units', 'pixels', 'Position', [231 5 100 20]);

for i=1:length(selectedROI)
    text(width,5+i*20,selectedROI{i},'BackgroundColor',color(i,:));
end;

set(slider1, 'Min', 1);
set(slider1, 'Max', length(ct_SOPInstanceUIDs));
set(slider1, 'SliderStep', [1/(length(ct_SOPInstanceUIDs) - 1) 1/(length(ct_SOPInstanceUIDs) - 1)]);
set(slider1, 'Value', 1);
 
%movegui(Img,'onscreen')% To display application onscreen
%movegui(Img,'center') % To display application in the center of screen
imshow(dicom_images(:,:,:,1));
set(findobj(gcf,'type','axes'),'hittest','on');
disp('abc');
%% Beginning of slider callback function
%hListener = handle.listener(slider1,'ActionEvent',@myCbFcn);

mysql('close');
end

function slider_callback(slider1, eventdata, handles, dicom_images)
    global dicom_images;
    position = round(get(slider1, 'Value'));
    disp(position);
    imshow(dicom_images(:,:,:,position));
   
end