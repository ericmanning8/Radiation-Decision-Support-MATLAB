
function isodose()

color = [65 105 225; 124 252 0; 135 206 250; 255 255 0; 255 165 0; 255 20 147; 255 0 0; 51 255 255; 0 128 0; 32 178 170; 150 200 10]/255; 

conn = mysql('open','localhost','root');
mysql('use rt_hn_v6');
fk_patient_id=1;
%Since every contour has an associated CT Slice, extract the first ct image
%for the first roi
[sampleCTSOP, ct_series_id] = mysql(horzcat('SELECT fk_sop_id, fk_series_id FROM ct_image WHERE fk_patient_id = "1" LIMIT 1'));
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

[dose_sop_id, dose_series_id, dose_study_id, doseGridScaling]=mysql(horzcat('SELECT fk_sop_id, fk_series_id, fk_study_id, doseGridScaling FROM dose WHERE fk_patient_id="1"'));
doseGrid = dicomread(horzcat('/Users/ruchi/Documents/python/rt/test/dicom/',num2str(fk_patient_id),'/',num2str(dose_study_id),'/',num2str(dose_series_id),'/',num2str(dose_sop_id),'.dcm'));
doseGrid=doseGrid.*str2double(doseGridScaling{1,1});
doseGrid=reshape(doseGrid,size(doseGrid,1),size(doseGrid,2),size(doseGrid,4));
maxDose = max(max(max(doseGrid)));
imageBlockRGB=repmat(reshape(imageBlock,[height width 1 numCTs]),[1 1 3 1]);%Change to RGB
imageBlockRGB=imageBlockRGB/max(max(max(max(imageBlockRGB))));

isodoseValues=[40;50;60;70;80;90;95];

roiBlock=HN_getContoursFull(fk_patient_id, 'ptv6930');

for k=1:numCTs
        red=imageBlockRGB(:,:,1,k);
        green=imageBlockRGB(:,:,2,k);
        blue=imageBlockRGB(:,:,3,k);
        red(roiBlock(:,:,k)==1)=color(1,1);
        green(roiBlock(:,:,k)==1)=color(1,2);
        blue(roiBlock(:,:,k)==1)=color(1,3);
        imageBlockRGB(:,:,1,k)=red;
        imageBlockRGB(:,:,2,k)=green;
        imageBlockRGB(:,:,3,k)=blue;
    end;
    
%for j=1:1
for j=1:length(isodoseValues)
    tempDoseMask = zeros(size(doseGrid));
    doseOutline = zeros(size(doseGrid));
    tempDoseMask(doseGrid>(isodoseValues(j)*0.01*maxDose))=1;
    for i=1:size(doseGrid,3)
        doseOutline(:,:,i) = bwperim(tempDoseMask(:,:,i));
    end
    %for k=50:50
    for k=1:size(doseGrid,3)
            red=imageBlockRGB(:,:,1,k);
            green=imageBlockRGB(:,:,2,k);
            blue=imageBlockRGB(:,:,3,k);
            red(doseOutline(:,:,k)==1)=color(j+2,1);
            green(doseOutline(:,:,k)==1)=color(j+2,2);
            blue(doseOutline(:,:,k)==1)=color(j+2,3);
            imageBlockRGB(:,:,1,k)=red;
            imageBlockRGB(:,:,2,k)=green;
            imageBlockRGB(:,:,3,k)=blue;
    end;
end;
clear conn;

global dicom_images;
dicom_images = imageBlockRGB;

f = figure('Visible','on','Name','My GUI','Position',[360,500,600,600]);
% Create an axes object to show which color is selected

Img = axes('Parent',f,'units','pixels','Position',[50 50 512 512]);
% Create a slider to display the images
slider1 = uicontrol('Style', 'slider', 'Parent', f, 'String', 'Image No.', 'Callback', @slider_callback, 'Units', 'pixels', 'Position', [231 5 100 20]);

% for i=1:length(selectedROI)
%     text(width,5+i*20,selectedROI{i},'BackgroundColor',color(i,:));
% end;

set(slider1, 'Min', 1);
set(slider1, 'Max', length(allCTs));
set(slider1, 'SliderStep', [1/(length(allCTs) - 1) 1/(length(allCTs) - 1)]);
set(slider1, 'Value', 1);
 
%movegui(Img,'onscreen')% To display application onscreen
%movegui(Img,'center') % To display application in the center of screen
imshow(dicom_images(:,:,:,1));
set(findobj(gcf,'type','axes'),'hittest','on');
%disp('abc');
%% Beginning of slider callback function
%hListener = handle.listener(slider1,'ActionEvent',@myCbFcn);
end

function slider_callback(slider1, eventdata, handles, dicom_images)
    global dicom_images;
    position = round(get(slider1, 'Value'));
    disp(position);
    imshow(dicom_images(:,:,:,position),[]);
   
end
    
