function [bladderPtv, rectumPtv] = centroidDistances(patient_number)

    %%% assumes that one plane has only one contour

    % patient_number = 26;

    % database init
    conn = mysql('open','localhost','root');
    mysql('use rt_test');
    PatientID = horzcat('UCLA_PR_',num2str(patient_number));
    patient_id = mysql(horzcat('SELECT id FROM patient WHERE PatientID="',PatientID,'"'));
    ptv_structure_set_roi_sequence_id=mysql(horzcat('SELECT id FROM structure_set_roi_sequence WHERE ROIName="PTV" AND fk_patient_id="',num2str(patient_id),'"'));
    bladder_structure_set_roi_sequence_id=mysql(horzcat('SELECT id FROM structure_set_roi_sequence WHERE ROIName="Bladder" AND fk_patient_id="',num2str(patient_id),'"'));
    rectum_structure_set_roi_sequence_id=mysql(horzcat('SELECT id FROM structure_set_roi_sequence WHERE ROIName="Rectum" AND fk_patient_id="',num2str(patient_id),'"'));
    bladderROINumber = mysql(horzcat('SELECT ROINumber FROM structure_set_roi_sequence WHERE ROIName="Bladder" AND fk_patient_id="',num2str(patient_id),'"'));
    rectumROINumber = mysql(horzcat('SELECT ROINumber FROM structure_set_roi_sequence WHERE ROIName="Rectum" AND fk_patient_id="',num2str(patient_id),'"'));
    ptvROINumber = mysql(horzcat('SELECT ROINumber FROM structure_set_roi_sequence WHERE ROIName="PTV" AND fk_patient_id="',num2str(patient_id),'"'));
    study_id=mysql(horzcat('SELECT fk_study_id from structure_set_roi_sequence WHERE id="',num2str(ptv_structure_set_roi_sequence_id),'"'));
    series_id=mysql(horzcat('SELECT fk_series_id from structure_set_roi_sequence WHERE id="',num2str(ptv_structure_set_roi_sequence_id),'"'));
    sop_common_id=mysql(horzcat('SELECT fk_sop_common_id from structure_set_roi_sequence WHERE id="',num2str(ptv_structure_set_roi_sequence_id),'"'));

    ptvID = ptvROINumber;
    bladderID = bladderROINumber;
    rectumID = rectumROINumber;
    containing_folder = strcat('UCLA_PR_',num2str(patient_number));%create folder path from patient number
    structureset_file_path = strcat('UCLA_PR_',num2str(patient_number),'/structureset.dcm');%create pathname for structure set file

    structureSetInfo=dicominfo(structureset_file_path);%structure set file metadata
    numStructures=length(fieldnames(structureSetInfo.StructureSetROISequence));%total number of structures in the structure set

    % To CREATE MAPPING OF ROI NUMBER AND NAMES
    roiList=cell(numStructures,2);
    for j = 1:numStructures
        item_number_string=strcat('Item_',num2str(j));% to generate strings 'Item_1','Item_2', etc.
        roiID=structureSetInfo.StructureSetROISequence.(item_number_string).ROINumber;
        roiList{roiID,1}=structureSetInfo.StructureSetROISequence.(item_number_string).ROIName;%column 1 contains names
        roiList{roiID,2}=roiID;%column 2 contains ROI Numbers
    end

    % To DETERMINE ITEM NUMBER CORRESPONDING TO ROI NUMBER in ROI Contour
    % Sequence object

    numContourSeqs = length(fieldnames(structureSetInfo.ROIContourSequence));
    for k = 1:numContourSeqs
        item_number_string=strcat('Item_',num2str(k));
        current_roi_number=structureSetInfo.ROIContourSequence.(item_number_string).ReferencedROINumber;
        if current_roi_number==ptvID
            ptv_Item_no=strcat('Item_',num2str(k));
        end
        if current_roi_number==bladderID
            bladder_Item_no=strcat('Item_',num2str(k));
        end
        if current_roi_number==rectumID
            rectum_Item_no=strcat('Item_',num2str(k));
        end
    end

    % DETERMINE ROW SPACING AND COLUMN SPACING
    ImageSOP = structureSetInfo.ROIContourSequence.(ptv_Item_no).ContourSequence.Item_1.ContourImageSequence.Item_1.ReferencedSOPInstanceUID;
    imagei = dicominfo(strcat(containing_folder,'/CT.',ImageSOP,'.dcm'));
    rowSpacing = imagei.PixelSpacing(1);
    columnSpacing = imagei.PixelSpacing(2);
    sliceSpacing = imagei.SliceThickness;%assume slice thickness is always set and that there is no gap b/w slices
    width = imagei.Width;
    height = imagei.Height;

    % GET PTV, BLADDER AND RECTUM CONTOURS AND MASKS
    % ptvBlock is the entire solid ptv - an object contour
    % ptvContourBlock contains contour slices derived from the patient
    % coordinate system translated to pixel coordinate system

    [ptvBlock, ptvContourBlock]=getContoursFull(structureSetInfo, ptv_Item_no, width, height, patient_number);
    [bladderBlock, bladderContourBlock]=getContoursFull(structureSetInfo, bladder_Item_no, width, height, patient_number);
    [rectumBlock, rectumContourBlock]=getContoursFull(structureSetInfo, rectum_Item_no, width, height, patient_number);

    % show contours and object slices
    % ptvContour = ptvContourBlock(:,:,15);
    % ptvFilled = ptvBlock(:,:,15);
    % ptvSmoothContour = bwperim(ptvFilled);
    % imshow(ptvContour); title('PTV Contour');
    % figure, imshow(ptvSmoothContour); title('PTV Smoothened Contour');
    % figure, imshow(ptvFilled); title('PTV Filled');
    % ***********************************

    % Get positions of all ON pixels in the organ masks and the smooth ptv contour object
    % bladderSub contains pixel positions of all ON pixels in the solid bladder
    % mask, and rectumSub for the rectum. ptvSub has pixel positions of all ON
    % pixels in the smoothened outline mask of the ptv

    %INITIALIZE
    numBladderVoxels = nnz(bladderBlock);
    numRectumVoxels = nnz(rectumBlock);
    numPtvVoxels = nnz(ptvBlock);
    bladderSub = zeros(numBladderVoxels,3);
    rectumSub = zeros(numRectumVoxels,3);
    ptvSub = zeros(numPtvVoxels,3);

    %FIND LINEAR INDICES OF ALL NON ZERO VOXELS
    bladderLin = find(bladderBlock);
    rectumLin = find(rectumBlock);
    ptvLin = find(ptvBlock);

    %CONVERT LINEAR INDICES TO SUBSCRIPTS
    [bladderSub(:,1), bladderSub(:,2), bladderSub(:,3)] = ind2sub(size(bladderBlock),bladderLin);
    [rectumSub(:,1), rectumSub(:,2), rectumSub(:,3)] = ind2sub(size(rectumBlock),rectumLin);
    [ptvSub(:,1), ptvSub(:,2), ptvSub(:,3)] = ind2sub(size(ptvBlock),ptvLin);

    %CALCULATE CENTROIDS

    bladderCentroid=[mean(bladderSub(:,1)); mean(bladderSub(:,2)); mean(bladderSub(:,3))];
    rectumCentroid=[mean(rectumSub(:,1)); mean(rectumSub(:,2)); mean(rectumSub(:,3))];
    ptvCentroid=[mean(ptvSub(:,1)); mean(ptvSub(:,2)); mean(ptvSub(:,3))];

    % WEIGHTED EUCLIDEAN DISTANCE
    % d((i,j,k),(a,b,c))=sqrt[1(i-a)^2+alpha(j-b)^2+beta(k-c)^2], where the
    % ratio of the sampling intervals in the three axes is 1:alpha:beta for
    % row:column:plane viz 1:columnSpacing/rowSpacing:heightSpacing/rowSpacing

    bladderPtv = sqrt((bladderCentroid(1,1)-ptvCentroid(1,1))^2+(bladderCentroid(2,1)-ptvCentroid(2,1))^2+(bladderCentroid(3,1)-ptvCentroid(3,1))^2);
    rectumPtv = sqrt((rectumCentroid(1,1)-ptvCentroid(1,1))^2+(rectumCentroid(2,1)-ptvCentroid(2,1))^2+(rectumCentroid(3,1)-ptvCentroid(3,1))^2);

    mysql(horzcat('UPDATE volume_distance SET Distance="',num2str(bladderPtv),'" WHERE fk_patient_id="',num2str(patient_id),'" AND ROIName="Bladder"'));
    mysql(horzcat('UPDATE volume_distance SET Distance="',num2str(rectumPtv),'" WHERE fk_patient_id="',num2str(patient_id),'" AND ROIName="Rectum"'));

    mysql('close');

end