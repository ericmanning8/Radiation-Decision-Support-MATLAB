clear all;

%% database init
conn = mysql('open','localhost','root');
mysql('use rt_hn_v5');

%% 

patient_ids=mysql('SELECT DISTINCT fk_patient_id FROM structure_set_roi_sequence_copy WHERE ptv1 IS NOT NULL');

for i = 1:length(patient_ids)
    disp(horzcat('Patient ',num2str(patient_ids(i))));
    %[roiIDs roiNames] = mysql(horzcat('SELECT id, stdROIName FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(patient_ids(i)),' AND stdROIName NOT LIKE "brain" AND stdROIName NOT LIKE "heart" AND stdROIName NOT LIKE "liver" AND stdROIName NOT LIKE "lungRt" AND stdROIName NOT LIKE "lungLt" AND stdROIName NOT LIKE "lungTt" AND stdROIName NOT LIKE "tvc" AND stdROIName NOT LIKE "lensRt" AND stdROIName NOT LIKE "lensLt" AND stdROIName NOT LIKE "chiasm" AND stdROIName NOT LIKE "parotidTt" AND stdROIName NOT LIKE "ptv%"'));
    [roiIDs roiNames] = mysql(horzcat('SELECT id, stdROIName FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(patient_ids(i)),' AND stdROIName NOT LIKE "brain" AND stdROIName NOT LIKE "heart" AND stdROIName NOT LIKE "liver" AND stdROIName NOT LIKE "lungRt" AND stdROIName NOT LIKE "lungLt" AND stdROIName NOT LIKE "lungTt" AND stdROIName NOT LIKE "tvc" AND stdROIName NOT LIKE "parotidTt" AND stdROIName NOT LIKE "ptv%"'));
    [ptvName] = mysql(horzcat('SELECT DISTINCT ptv1 FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(patient_ids(i))));   
    ptvName = ptvName{1};
    [ptvID] = mysql(horzcat('SELECT id FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(patient_ids(i)),' AND stdROIName = "',ptvName,'"')); 
    ptvBlock = HN_getContoursFull(patient_ids(i),ptvName);
    ptvCentroid = regionprops(ptvBlock,'centroid');
    mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET centroidX="',num2str(ptvCentroid.Centroid(1)),'", centroidY="',num2str(ptvCentroid.Centroid(2)),'", centroidZ="',num2str(ptvCentroid.Centroid(3)),'" WHERE id="',num2str(ptvID),'"'));
    
    for roiIndex = 1:length(roiNames)
        roiBlock = HN_getContoursFull(patient_ids(i),roiNames{roiIndex}); 
        roiCentroid = regionprops(roiBlock,'centroid');
%         disp(roiNames{roiIndex});
%         disp(roiCentroid.Centroid);
        alpha = (ptvCentroid.Centroid(1)-roiCentroid.Centroid(1))/(sqrt(((ptvCentroid.Centroid(1)-roiCentroid.Centroid(1))^2)+((ptvCentroid.Centroid(2)-roiCentroid.Centroid(2))^2)+((ptvCentroid.Centroid(3)-roiCentroid.Centroid(3))^2)));
        beta = (ptvCentroid.Centroid(2)-roiCentroid.Centroid(2))/(sqrt(((ptvCentroid.Centroid(1)-roiCentroid.Centroid(1))^2)+((ptvCentroid.Centroid(2)-roiCentroid.Centroid(2))^2)+((ptvCentroid.Centroid(3)-roiCentroid.Centroid(3))^2)));
        gamma = (ptvCentroid.Centroid(3)-roiCentroid.Centroid(3))/(sqrt(((ptvCentroid.Centroid(1)-roiCentroid.Centroid(1))^2)+((ptvCentroid.Centroid(2)-roiCentroid.Centroid(2))^2)+((ptvCentroid.Centroid(3)-roiCentroid.Centroid(3))^2)));
%         disp(horzcat('alpha: ',num2str(alpha),' beta: ',num2str(beta),' gamma: ',num2str(gamma)));  
        mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET centroidX="',num2str(roiCentroid.Centroid(1)),'", centroidY="',num2str(roiCentroid.Centroid(2)),'", centroidZ="',num2str(roiCentroid.Centroid(3)),'", alpha_ptv1="',num2str(alpha),'", beta_ptv1="',num2str(beta),'", gamma_ptv1="',num2str(gamma),'" WHERE id="',num2str(roiIDs(roiIndex)),'"'));
    
    end
end

mysql('close');
clear conn;

