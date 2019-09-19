%test 20 and 8
clear all;
roiName = 'parotidRt';

conn = mysql('open','localhost','root');
mysql('use rt_hn_v6');

all_patient_ids = mysql(horzcat('SELECT DISTINCT fk_patient_id FROM structure_set_roi_sequence_copy WHERE stdROIName = "',roiName,'" AND fk_patient_id NOT LIKE "2" AND fk_patient_id NOT LIKE "9" AND fk_patient_id NOT LIKE "21" AND fk_patient_id NOT LIKE "39" ORDER BY fk_patient_id ASC'));
sample = randsample(all_patient_ids,5);
dbPool = setdiff(all_patient_ids,sample);

queryText = '';
for sampleIndex = 1:(length(sample)-1)
    queryText=horzcat(queryText,'fk_patient_id = "',num2str(sample(sampleIndex)),'" OR ');
end
queryText=horzcat(queryText,'fk_patient_id = "',num2str(sample(length(sample))),'"');
[queryPatientID queryDistance queryVolume queryAlpha queryBeta queryGamma queryOverlap queryDistanceMean queryDoseMean queryDoseMax, queryPrescriptionDose] = mysql(horzcat('SELECT fk_patient_id, ovhDistance_ptv1, ovhVolume_ptv1, alpha_ptv1, beta_ptv1, gamma_ptv1, PercentageOverlap_ROI_Fraction_ptv1, distanceMean_ptv1, doseMean, doseMax, dosePrescription FROM structure_set_roi_sequence_copy WHERE (',queryText,') AND stdROIName="',roiName,'" ORDER BY fk_patient_id ASC'));

result = zeros(length(sample),2);
result(:,1)=sample;

clear sampleIdex;

for sampleIndex = 1:length(sample)
    
    distance = regexp(queryDistance{sampleIndex},',','split');
    distance{1}=distance{1}(2:length(distance{1}));
    distance{length(distance)}=distance{length(distance)}(1:length(distance{length(distance)})-1);
    distance=str2double(distance);
    volume = regexp(queryVolume{sampleIndex},',','split');
    volume{1}=volume{1}(2:length(volume{1}));
    volume{length(volume)}=volume{length(volume)}(1:length(volume{length(volume)})-1);
    volume=str2double(volume);  
    qOVH = [distance' volume'];
    
    qAlpha = queryAlpha(sampleIndex);
    qBeta = queryBeta(sampleIndex);
    qGamma = queryGamma(sampleIndex);
    qOverlap = queryOverlap(sampleIndex);
    qDoseMean = queryDoseMean(sampleIndex);
    qDistanceMean = queryDistanceMean(sampleIndex);
    qDoseMean = queryDoseMean(sampleIndex);
    qPrescriptionDose = queryPrescriptionDose(sampleIndex);

    for dbPatientIndex = 1:length(dbPool) %Cycle through all patients
        %`disp(sampleIndex)
        [dbDistance dbVolume dbAlpha dbBeta dbGamma dbOverlap dbDistanceMean dbDoseMean dbDoseMax, dbPrescriptionDose] = mysql(horzcat('SELECT ovhDistance_ptv1, ovhVolume_ptv1, alpha_ptv1, beta_ptv1, gamma_ptv1, PercentageOverlap_ROI_Fraction_ptv1, distanceMean_ptv1, doseMean, doseMax, dosePrescription FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(dbPool(dbPatientIndex)),' AND stdROIName = "',roiName,'"'));        
        %********************************* CALCULATE EMD *********************************
        dbDistance = regexp(dbDistance{1},',','split');
        dbDistance{1}=dbDistance{1}(2:length(dbDistance{1}));
        dbDistance{length(dbDistance)}=dbDistance{length(dbDistance)}(1:length(dbDistance{length(dbDistance)})-1);
        dbDistance=str2double(dbDistance);

        dbVolume = regexp(dbVolume{1},',','split');
        dbVolume{1}=dbVolume{1}(2:length(dbVolume{1}));
        dbVolume{length(dbVolume)}=dbVolume{length(dbVolume)}(1:length(dbVolume{length(dbVolume)})-1);
        dbVolume=str2double(dbVolume);

        dbOVH=[dbDistance' dbVolume'];
        w1=ones(length(qOVH),1);
        w2=ones(length(dbOVH),1);
        [x emdValue] = emd(qOVH, dbOVH, w1, w2, @gdf);
        %**********************************************************************************

        %*********************** CALCULATE ORIENTATION SIM ********************************
        sim = (1+qAlpha*dbAlpha+qBeta*dbBeta+qGamma*dbGamma)/2;
        %**********************************************************************************
        
        %****************************** DETERMINE MATCH ***********************************
        %if (emdValue<5)&&(sim>0.975)&&(qOverlap<=dbOverlap)&&(qDistanceMean>=dbDistanceMean)&&(qPrescriptionDose<=dbPrescriptionDose)&&(qDoseMean>=dbDoseMean)
        if (emdValue<5)&&(sim>0.975)&&(qOverlap<=dbOverlap)&&(qDistanceMean>=dbDistanceMean)&&(qDoseMean>=dbDoseMean)&&(qPrescriptionDose<=dbPrescriptionDose)
          result(sampleIndex,2)=result(sampleIndex,2)+1;
          disp(horzcat('Query Patient: ',num2str(queryPatientID(sampleIndex)),' Dose Mean: ',num2str(qDoseMean)));
          disp(horzcat('DB Patient: ',num2str(dbPool(dbPatientIndex)),' Dose Mean: ',num2str(dbDoseMean))); 
        end
        %**********************************************************************************
    end 
end

mysql('close');
clear conn;