%% assumes that one plane has only one contour

function [roiBlock] = HN_getContoursFull(patient_id,stdROIName)

%% database init
conn = mysql('open','localhost','root');
mysql('use rt_hn_v6');

%% Create ROI List with standardized ROI Namea
%ROIList = ['brain','brainstem','chiasm','cochleaLt','cochleaRt','cord','cornea','esophagus','eyeLt','eyeRt','heart','lacrimalLt','lacrimalRt','larynx','lensLt','lensRt','lips','liver','lungLt','lungRt','lynxEsoTrch','lynxEsoTrchThy','lynxOrophnx','lynxThy','mandible','opticNerveLt','opticNerveRt','oralCavity','parotidLt','parotidRt','pharynx','ptvAll','tongue','trachea','parotidTt','lungTt'];

%Get ROI information for ever ROI. roiNumber, strROIName etc are all lists
[structure_set_roi_sequence_id] = mysql(horzcat('SELECT id FROM structure_set_roi_sequence WHERE fk_patient_id = ',num2str(patient_id),' AND stdROIName="',stdROIName,'"'));

%Determine number of CT Images in the series

ct_series_id = mysql(horzcat('SELECT id FROM series WHERE fk_patient_id="',num2str(patient_id),'" AND Modality="CT"'));
numCTs = mysql(horzcat('SELECT numCTifCT FROM series WHERE id = "',num2str(ct_series_id),'"'));
[rows, columns]=mysql(horzcat('SELECT DISTINCT Rows, Columns FROM image_plane_pixel WHERE fk_series_id="',num2str(ct_series_id),'"'));
imgPosPatZ = sort(str2double(mysql(horzcat('SELECT imgPosPatZ FROM image_plane_pixel WHERE fk_series_id="',num2str(ct_series_id),'"'))));
imgPosPatZ=round(imgPosPatZ*10)/10;
roiBlock = zeros(rows,columns,numCTs);
    

[ct_sop_ids, contourData] = mysql(horzcat('SELECT ct_fk_sop_id, ContourData FROM contour_sequence WHERE fk_structure_Set_roi_sequence_id="',num2str(structure_set_roi_sequence_id),'"'));

for j = 1:length(contourData)
    cdata = regexp(contourData{j},',','split');%Split the first set of contour data points at the commas
    cdata{1}=cdata{1}(2:length(cdata{1}));%Trim the '[' character off 
    cdata{length(cdata)}=cdata{length(cdata)}(1:length(cdata{length(cdata)})-1);%Trim the ']' character off 
    cdata=str2double(cdata);%Convert the character data to numeric data

    cdata_x=cdata(1:3:length(cdata));
    cdata_y=cdata(2:3:length(cdata));
    cdata_z=cdata(3);

    [xx,xy,yx,yy,sx,sy,delJ,delI]=mysql(horzcat('SELECT imgOrPat1, imgOrPat2, imgOrPat4, imgOrPat5, imgPosPatX, imgPosPatY, pixelSpacingRow, pixelSpacingColumn FROM image_plane_pixel WHERE fk_sop_id="',num2str(ct_sop_ids(j)),'"'));
    xx=str2double(xx{1,1});xy=str2double(xy{1,1});yx=str2double(yx{1,1});yy=str2double(yy{1,1});sx=str2double(sx{1,1});sy=str2double(sy{1,1});delJ=str2double(delJ{1,1});delI=str2double(delI{1,1});

    rowCoords=zeros(length(cdata_x),1);%an array of all the row coordinates initialized
    colCoords=zeros(length(cdata_y),1);%an array of all the column coordinates initialized
    correction = zeros(length(cdata_x),1);
    correction(:,1) = 0.5;%all coordinates must be changed from (x,y) to ((x-1).5, (y-1).5) to make sure that contour boundary pixels are also included in the object in poly2mask

    for k=1:length(cdata_x) 
        px=cdata_x(k);%x coordinate from planeContourData, which contains the x,y and z coordinates in a single 1D array
        py=cdata_y(k);%y coordinate from planeContourData

        A=[xx*delI yx*delJ; xy*delI yy*delJ];
        b=[px-sx; py-sy];
        v=A\b; %backward slash not forward slash

        colCoords(k)=round(v(1));%j - pixel coordinate for the column
        rowCoords(k)=round(v(2));%i - pixel coordinate for the row

    end
    polyMask=poly2mask(colCoords-correction,rowCoords-correction,rows,columns);%1s (ones) represent the structure; is an ROI mask
    roiBlock(:,:,imgPosPatZ==cdata_z)=roiBlock(:,:,imgPosPatZ==cdata_z)|im2double(polyMask);% Logical OR to previous image in case there are multiple contours per slice. Else the new contour would wipe out the previous contour

end
   
mysql('close');
end