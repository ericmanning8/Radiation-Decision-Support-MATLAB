%% assumes that one plane has only one contour

function imageStackColorv2r(patient_id,selectedROI)

%% database init
conn = mysql('open','localhost','root');
mysql('use rt_3');

%Get ROI information for every ROI. roiNumber, strROIName etc are all lists
[structure_set_roi_sequence_ids, roiNumbers, stdROINames, structure_set_ids, strSet_sop_ids, strSet_series_ids, strSet_study_ids, roi_dose_ids, roi_dvh_sequence_ids] = mysql(horzcat('SELECT id, ROINumber, stdROIName, fk_structure_set_id, fk_sop_id, fk_series_id, fk_study_id, fk_dose_id, fk_dvh_sequence_id FROM structure_set_roi_sequence WHERE fk_patient_id = ',num2str(patient_id),' AND stdROIName IS NOT NULL'));
disp(stdROINames);
%Since every contour has an associated CT Slice, extract the first ct image
%for the first roi
[sampleCTSOP, ct_series_id] = mysql(horzcat('SELECT ct_fk_sop_id, ct_fk_series_id FROM contour_sequence WHERE fk_structure_set_roi_sequence_id = "',num2str(structure_set_roi_sequence_ids(1)),'" LIMIT 1'));
numCTs = mysql(horzcat('SELECT numCTifCT FROM series WHERE id = "',num2str(ct_series_id),'"'));%Get number of CT Images
%Get row spacing, slice spacing etc based on the sample ct image
[rowSpacing, columnSpacing, sliceSpacing, width, height]=mysql(horzcat('SELECT pixelSpacingRow, pixelSpacingColumn, sliceThickness, columns, rows FROM image_plane_pixel WHERE fk_sop_id="',num2str(sampleCTSOP),'"'));
rowSpacing=str2double(rowSpacing{1,1});columnSpacing=str2double(columnSpacing{1,1});sliceSpacing=str2double(sliceSpacing{1,1});
imageBlock=zeros(height, width, numCTs);

%imgPosPatZ gives the z indices of all CT images. This is useful in
%assembling the CT Block
imgPosPatZ = sort(str2double(mysql(horzcat('SELECT imgPosPatZ FROM image_plane_pixel WHERE fk_series_id="',num2str(ct_series_id),'"'))));
allCTs = mysql(horzcat('SELECT id FROM sop WHERE fk_series_id="',num2str(ct_series_id),'"'));
for vv=1:length(allCTs)
        [ser,st,pat]=mysql(horzcat('SELECT fk_series_id,fk_study_id,fk_patient_id FROM sop WHERE id="',num2str(allCTs(vv)),'"'));
        ct_z=str2double(mysql(horzcat('SELECT imgPosPatZ FROM image_plane_pixel WHERE fk_sop_id="',num2str(allCTs(vv)),'"')));
        imageBlock(:,:,imgPosPatZ==ct_z)=im2double(dicomread(horzcat('/Users/ruchi/Documents/python/rt/test/dicom/',num2str(pat),'/',num2str(st),'/',num2str(ser),'/',num2str(allCTs(vv)),'.dcm')));
        
end;

%% ************************* LOOP OVER EACH ROI *************************************
%% **********************************************************************************

imageBlockRGB=repmat(reshape(imageBlock,[height width 1 numCTs]),[1 1 3 1]);%Change to RGB
imageBlockRGBNorm=imageBlockRGB/max(max(max(max(imageBlockRGB))));%Normalize
randomColor = jet(40);
for i=1:length(selectedROI) %For each ROI in the patient's ROI Sequence    
    roiBlock=HN_getContoursFull(patient_id, selectedROI{i});
    roiOutline3D = zeros(size(roiBlock));
    for j = 1:(size(roiBlock,3))
        roiOutline3D(:,:,j) = bwperim(roiBlock(:,:,j));
    end 
    disp(selectedROI{i});

    for k=1:numCTs
        red=imageBlockRGBNorm(:,:,1,k);
        green=imageBlockRGBNorm(:,:,2,k);
        blue=imageBlockRGBNorm(:,:,3,k);
        red(roiOutline3D(:,:,k)==1)=randomColor(1,1);
        green(roiOutline3D(:,:,k)==1)=randomColor(1,2);
        blue(roiOutline3D(:,:,k)==1)=randomColor(1,3);
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


set(slider1, 'Min', 1);
set(slider1, 'Max', length(allCTs));
set(slider1, 'SliderStep', [1/(length(allCTs) - 1) 1/(length(allCTs) - 1)]);
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
    imshow(dicom_images(:,:,:,position),[]);
   
end