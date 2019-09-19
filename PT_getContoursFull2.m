function roiBlock = PT_getContoursFull2(patientID, roiNumber)
%     conn = mysql('open','localhost','root');
%     mysql('use pt_pr_v1');

    %patientID='96248017';
    %roiName='Bladder';
%     if strcmp(roiName,'Bladder')||strcmp(roiName,'bladder')
%         roiNumber=3;
%     elseif strcmp(roiName,'Rectum')||strcmp(roiName,'rectum')
%         roiNumber=2;
%     elseif strcmp(roiName,'Prostate')||strcmp(roiName,'prostate')||strcmp(roiName,'PROSTATE')
%         roiNumber=4;
%     end
    %Determine number of CT Images in the series

    %[structure_set_roi_sequence_id] = mysql(horzcat('SELECT id FROM structure_set_roi_sequence WHERE fk_patient_id = ',num2str(patient_id),' AND stdROIName="',stdROIName,'"'));

    CT_SeriesInstanceUID = mysql(horzcat('SELECT SeriesInstanceUID FROM iod_general_series WHERE fk_PatientID = "',patientID,'" AND Modality="CT"'));
    numCTs = mysql(horzcat('SELECT numCTifCT FROM iod_general_series WHERE fk_PatientID = "',patientID,'" AND Modality="CT"'));
    [rows, columns]=mysql(horzcat('SELECT DISTINCT Rows, Columns FROM iod_image_pixel WHERE fk_SeriesInstanceUID="',CT_SeriesInstanceUID{1},'"'));
    imgPosPatZ = sort(str2double(mysql(horzcat('SELECT imgPosPatZ FROM iod_image_plane WHERE fk_SeriesInstanceUID="',CT_SeriesInstanceUID{1},'"'))));
    %imgPosPatZ=round(imgPosPatZ*10)/10;
    roiBlock = zeros(rows,columns,numCTs);

    [ct_SOPInstanceUIDs, contourData] = mysql(horzcat('SELECT fk_CT_SOPInstanceUID, ContourData FROM seq_contour WHERE fk_PatientID="',patientID,'" AND fk_ReferencedROINumber="',num2str(roiNumber),'"'));

    for j = 1:length(contourData)
    %for j=1:1
        cdata = regexp(contourData{j},'/','split');%Split the first set of contour data points at the commas
        cdata=str2double(cdata);%Convert the character data to numeric data

        cdata_x=cdata(1:3:length(cdata));
        cdata_y=cdata(2:3:length(cdata));
        cdata_z=cdata(3);  
        %disp(cdata_z);
        [xx,xy,yx,yy,sx,sy,delJ,delI]=mysql(horzcat('SELECT imgOrPat1, imgOrPat2, imgOrPat4, imgOrPat5, imgPosPatX, imgPosPatY, pixelSpacingRow, pixelSpacingColumn FROM iod_image_plane WHERE fk_SOPInstanceUID="',ct_SOPInstanceUIDs{j},'"'));
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
% 
% % gets contours for the entire CT block
% containing_folder = strcat('PT/',num2str(patientID),'/',num2str(ctStudyInstanceUID),'/',num2str(ctSeriesInstanceUID));
% imageList = dir(fullfile(containing_folder, '*.dcm'));
% numImages = size(imageList);
% slicePositionMap = zeros(numImages(1),1);
% for i=1:numImages(1)
%     info=dicominfo(strcat(containing_folder,'/',imageList(i).name));
%     slicePositionMap(i) = info.ImagePositionPatient(3);
% end
% 
% roiNumPlanes=length(fieldnames(structureSetInfo.ROIContourSequence.(ROI_Item_no).ContourSequence));%number of planes for which contour data is available for this ROI
% roiBlock=zeros(double(width),double(height),double(numImages));%use functions to determine image size
% contourBlock=zeros(double(width),double(height),double(numImages));
% 
% for planeIndex = 1:roiNumPlanes % for each contour plane of the selected ROI
%     
%     item_number_string=strcat('Item_',num2str(planeIndex));%generate sequence of items  - Item_1, Item_2, etc.
%     planeContourData=structureSetInfo.ROIContourSequence.(ROI_Item_no).ContourSequence.(item_number_string).ContourData;%get contour data points for a particular ROI, in a particular plane
%     z=planeContourData(3);%get z coordinate for the plane
%     ImageSOP = structureSetInfo.ROIContourSequence.(ROI_Item_no).ContourSequence.(item_number_string).ContourImageSequence.Item_1.ReferencedSOPInstanceUID;% get SOP UID of associated image
%     %roiNum=structureSetInfo.ROIContourSequence.(ROI_Item_no).ReferencedROINumber;%retrieve the ROI ID
%     %selectedStructure=roiList(roiNum,1);%give name of selected structure using the roi ID
%     imagei = dicominfo(strcat(containing_folder,'/',ImageSOP,'.dcm'));% get dicom metadata of assoc image
%     %image = im2double(dicomread(strcat(containing_folder,'/CT.',ImageSOP,'.dcm')));%get assoc. image
%     %correspondingZ = imagei.ImagePositionPatient(3);%to check if slice location of contour plane and image plane match; corrZ is z of the image plane
% 
%     [x y] =size(planeContourData);%get number of elements in planeContourData, which is a 1d array (is number of contour points)
% 
%     % **********************************
%     % extracting information for converting to pixel coordinates
%     xx=imagei.ImageOrientationPatient(1);
%     xy=imagei.ImageOrientationPatient(2);
%     yx=imagei.ImageOrientationPatient(4);
%     yy=imagei.ImageOrientationPatient(5);
%     sx=imagei.ImagePositionPatient(1);
%     sy=imagei.ImagePositionPatient(2);
%     delJ=imagei.PixelSpacing(1);
%     delI=imagei.PixelSpacing(2);
%     % **********************************
%     
%     temp=length(planeContourData)/3;%number of x points, and therefor also the number of y points and number of z points
%     rowCoords=zeros(temp,1);%an array of all the row coordinates initialized
%     colCoords=zeros(temp,1);%an array of all the column coordinates initialized
%     correction = zeros(temp,1);
%     correction(:,1) = 0.5;%all coordinates must be changed from (x,y) to ((x-1).5, (y-1).5) to make sure that contour boundary pixels are also included in the object in poly2mask
%     count=1;
%     for i=1:3:x 
%         px=planeContourData(i);%x coordinate from planeContourData, which contains the x,y and z coordinates in a single 1D array
%         py=planeContourData(i+1);%y coordinate from planeContourData
% 
%         A=[xx*delI yx*delJ; xy*delI yy*delJ];
%         b=[px-sx; py-sy];
%         v=A\b; %backward slash not forward slash
% 
%         colCoords(count)=round(v(1));%j - pixel coordinate for the column
%         rowCoords(count)=round(v(2));%i - pixel coordinate for the row
%         contourBlock(rowCoords(count),colCoords(count),slicePositionMap==z)=1;
%         count=count+1;
%     end
%     
%     polyMask=poly2mask(colCoords-correction,rowCoords-correction,double(height),double(width));%1s (ones) represent the structure; is an ROI mask
%     roiBlock(:,:,slicePositionMap==z)=polyMask;
%     
% end

% mysql('close');
% clear conn
end