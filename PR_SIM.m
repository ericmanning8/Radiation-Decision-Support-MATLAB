clear all;

%% database init
conn = mysql('open','localhost','root');
mysql('use pt_pr_v3');

%% 

patient_ids=mysql('SELECT DISTINCT fk_PatientID FROM structure_set_roi_sequence');

for i = 1:length(patient_ids)
    disp(horzcat('Patient ',num2str(patient_ids{i})));
    %[roiIDs roiNames] = mysql(horzcat('SELECT id, stdROIName FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(patient_ids(i)),' AND stdROIName NOT LIKE "brain" AND stdROIName NOT LIKE "heart" AND stdROIName NOT LIKE "liver" AND stdROIName NOT LIKE "lungRt" AND stdROIName NOT LIKE "lungLt" AND stdROIName NOT LIKE "lungTt" AND stdROIName NOT LIKE "tvc" AND stdROIName NOT LIKE "lensRt" AND stdROIName NOT LIKE "lensLt" AND stdROIName NOT LIKE "chiasm" AND stdROIName NOT LIKE "parotidTt" AND stdROIName NOT LIKE "ptv%"'));
    [roiIDs roiNames] = mysql(horzcat('SELECT ROINumber, ROIName FROM structure_set_roi_sequence WHERE fk_PatientID=',num2str(patient_ids{i}),' AND ROIName NOT LIKE "Prostate" AND ROIName NOT LIKE "PROSTATE" AND ROIName NOT LIKE "prostate"'));
    [ptvID, ptvName] = mysql(horzcat('SELECT ROINumber, ROIName FROM structure_set_roi_sequence WHERE (fk_PatientID="',num2str(patient_ids{i}),'") AND (ROIName = "PROSTATE" OR ROIName = "Prostate" OR ROIName = "prostate")')); 
    ptvBlock = PT_getContoursFull2(patient_ids{i},ptvID);
    ptvCentroid = regionprops(ptvBlock,'centroid');
    %mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET centroidX="',num2str(ptvCentroid.Centroid(1)),'", centroidY="',num2str(ptvCentroid.Centroid(2)),'", centroidZ="',num2str(ptvCentroid.Centroid(3)),'" WHERE id="',num2str(ptvID),'"'));
    
    for roiIndex = 1:length(roiNames)
        roiBlock = PT_getContoursFull2(patient_ids{i},roiIDs(roiIndex)); 
        entryIndex = mysql(horzcat('SELECT id FROM structure_set_roi_sequence WHERE fk_PatientID = "',patient_ids{i},'" AND ROINumber = "',num2str(roiIDs(roiIndex)),'"'));
        roiCentroid = regionprops(roiBlock,'centroid');
%         disp(roiNames{roiIndex});
%         disp(roiCentroid.Centroid);
        alpha = (ptvCentroid.Centroid(1)-roiCentroid.Centroid(1))/(sqrt(((ptvCentroid.Centroid(1)-roiCentroid.Centroid(1))^2)+((ptvCentroid.Centroid(2)-roiCentroid.Centroid(2))^2)+((ptvCentroid.Centroid(3)-roiCentroid.Centroid(3))^2)));
        beta = (ptvCentroid.Centroid(2)-roiCentroid.Centroid(2))/(sqrt(((ptvCentroid.Centroid(1)-roiCentroid.Centroid(1))^2)+((ptvCentroid.Centroid(2)-roiCentroid.Centroid(2))^2)+((ptvCentroid.Centroid(3)-roiCentroid.Centroid(3))^2)));
        gamma = (ptvCentroid.Centroid(3)-roiCentroid.Centroid(3))/(sqrt(((ptvCentroid.Centroid(1)-roiCentroid.Centroid(1))^2)+((ptvCentroid.Centroid(2)-roiCentroid.Centroid(2))^2)+((ptvCentroid.Centroid(3)-roiCentroid.Centroid(3))^2)));
        disp(horzcat('alpha: ',num2str(alpha),' beta: ',num2str(beta),' gamma: ',num2str(gamma)));  
        mysql(horzcat('UPDATE structure_set_roi_sequence SET alpha="',num2str(alpha),'", beta="',num2str(beta),'", gamma="',num2str(gamma),'" WHERE id="',num2str(entryIndex),'"'));
    
    end
end

mysql('close');
clear conn;

