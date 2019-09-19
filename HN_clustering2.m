clear all;
roi = 'parotidLt';
k=6;
conn = mysql('open','localhost','root');
mysql('use rt_hn_v5');
[patient_ids ovhMean ovhMedian ovhStd ovhMode ovhMax ovhMin ovhSkewness roiOverlap Volume alpha beta gamma doseMean doseMax] = mysql(horzcat('SELECT fk_patient_id, DistanceMean_ptv1, DistanceMedian_ptv1, DistanceStdDev_ptv1, DistanceMode_ptv1, DistanceMax_ptv1, DistanceMin_ptv1, DistanceSkewness_ptv1, PercentageOverlap_ROI_Fraction_ptv1, Volume, alpha_ptv1, beta_ptv1, gamma_ptv1, doseMean, doseMax FROM structure_set_roi_sequence_copy WHERE stdROIName="',roi,'" AND ptv1 IS NOT NULL ORDER BY fk_patient_id ASC'));

numPatients = length(patient_ids);
ptvVolume = zeros(numPatients,1);
for i = 1:length(patient_ids)
    ptvName = mysql(horzcat('SELECT DISTINCT ptv1 FROM structure_set_roi_sequence_copy WHERE fk_patient_id="',num2str(patient_ids(i)),'"'));
    ptvVolume(i) = mysql(horzcat('SELECT Volume FROM structure_set_roi_sequence_copy WHERE stdROIName = "',ptvName{1},'" AND fk_patient_id="',num2str(patient_ids(i)),'"'));
end

mysql('close');

%rois = {'brainstem', 'chiasm', 'opticNerveRt', 'opticNerveLt', 'cochleaRt', 'cochleaLt', 'tongue', 'mandible', 'pharynx', 'larynx', 'parotidRt', 'parotidLt', 'cord'};
features = [ovhMean ovhMedian ovhStd ovhMode ovhMax ovhMin ovhSkewness roiOverlap Volume ptvVolume alpha beta gamma];
features(isnan(features))=0;

[membership centroids sumd d]=kmeans(features,k);
clear brainstemOverlap chiasmOverlap opticNerveRtOverlap opticNerveLtOverlap cochleaRtOverlap cochleaLtOverlap tongueOverlap mandibleOverlap pharynxOverlap larynxOverlap parotidRtOverlap parotidLtOverlap cordOverlap;
clear brainstemDistance chiasmDistance opticNerveRtDistance opticNerveLtDistance cochleaRtDistance cochleaLtDistance tongueDistance mandibleDistance pharynxDistance larynxDistance parotidRtDistance parotidLtDistance cordDistance;

centroids2 = [centroids(:,1) centroids(:,8)];

doseMeanMeans = zeros(k,1);
doseMeanStdDevs = zeros(k,1);
doseMaxMeans = zeros(k,1);
doseMaxStdDevs = zeros(k,1);
for m=1:k
    doseMeanMeans(m)=mean(doseMean(membership==m)); 
    doseMeanStdDevs(m)=std(doseMean(membership==m)); 
    doseMaxMeans(m)=mean(doseMax(membership==m));
    doseMaxStdDevs(m)=std(doseMax(membership==m)); 
end

centroids3 = [centroids2 doseMeanMeans doseMaxMeans doseMeanStdDevs doseMaxStdDevs];
centroids3 = sortrows(centroids3,2);
mysql('close');
clear conn;