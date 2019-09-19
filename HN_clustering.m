clear all;

conn = mysql('open','localhost','root');
mysql('use rt_hn_v5');
[patient_id brainstemOverlap chiasmOverlap opticNerveRtOverlap opticNerveLtOverlap cochleaRtOverlap cochleaLtOverlap tongueOverlap mandibleOverlap pharynxOverlap larynxOverlap parotidRtOverlap parotidLtOverlap cordOverlap] = mysql('SELECT fk_patient_id, brainstemOverlap, chiasmOverlap, opticNerveRtOverlap, opticNerveLtOverlap, cochleaRtOverlap, cochleaLtOverlap, tongueOverlap, mandibleOverlap, pharynxOverlap, larynxOverlap, parotidRtOverlap, parotidLtOverlap, cordOverlap FROM knowledge ORDER BY fk_patient_id ASC');
[patient_id brainstemDistance chiasmDistance opticNerveRtDistance opticNerveLtDistance cochleaRtDistance cochleaLtDistance tongueDistance mandibleDistance pharynxDistance larynxDistance parotidRtDistance parotidLtDistance cordDistance] = mysql('SELECT fk_patient_id, brainstemDistance, chiasmDistance, opticNerveRtDistance, opticNerveLtDistance, cochleaRtDistance, cochleaLtDistance, tongueDistance, mandibleDistance, pharynxDistance, larynxDistance, parotidRtDistance, parotidLtDistance, cordDistance FROM knowledge ORDER BY fk_patient_id ASC');
mysql('close');
%rois = {'brainstem', 'chiasm', 'opticNerveRt', 'opticNerveLt', 'cochleaRt', 'cochleaLt', 'tongue', 'mandible', 'pharynx', 'larynx', 'parotidRt', 'parotidLt', 'cord'};
features = [brainstemOverlap chiasmOverlap opticNerveRtOverlap opticNerveLtOverlap cochleaRtOverlap cochleaLtOverlap tongueOverlap mandibleOverlap pharynxOverlap larynxOverlap parotidRtOverlap parotidLtOverlap cordOverlap];
features(isnan(features))=0;

[membership centroids sumd d]=kmeans(features,6);
clear brainstemOverlap chiasmOverlap opticNerveRtOverlap opticNerveLtOverlap cochleaRtOverlap cochleaLtOverlap tongueOverlap mandibleOverlap pharynxOverlap larynxOverlap parotidRtOverlap parotidLtOverlap cordOverlap;
clear brainstemDistance chiasmDistance opticNerveRtDistance opticNerveLtDistance cochleaRtDistance cochleaLtDistance tongueDistance mandibleDistance pharynxDistance larynxDistance parotidRtDistance parotidLtDistance cordDistance;

mysql('close');
clear conn;