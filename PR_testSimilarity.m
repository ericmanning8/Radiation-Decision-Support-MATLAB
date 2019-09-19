%test 20 and 8
clear all;
roiName = 'Bladder';

conn = mysql('open','localhost','root');
mysql('use pt_pr_v3');

[query_patient_ids query_PatientIDs] = mysql(horzcat('SELECT DISTINCT id, fk_PatientID FROM structure_set_roi_sequence WHERE ROIName LIKE "',roiName,'%" ORDER BY id ASC'));
counter=1;

for queryIndex = 1:length(query_patient_ids)
% for queryIndex = 1:1
    
    disp(horzcat('Processing Patient ',num2str(query_patient_ids(queryIndex))));
    [queryDistance queryVolume qAlpha qBeta qGamma qOverlap qDistanceMean qDoseMean qDoseMax qROIVolume] = mysql(horzcat('SELECT ovhDistance, ovhVolume, alpha, beta, gamma, PercentageOverlap_ROI_Fraction, distanceMean, doseMean, doseMax, Volume FROM structure_set_roi_sequence WHERE id="',num2str(query_patient_ids(queryIndex)),'"'));
    [qPTVVolume qPTVDoseMean qPTVDoseMax] = mysql(horzcat('SELECT Volume, doseMean, doseMax from structure_set_roi_sequence WHERE fk_PatientID="',query_PatientIDs{queryIndex},'" AND (ROIName LIKE "prostate%" OR ROIName LIKE "PROSTATE%")'));
    db_patient_ids = setdiff(query_patient_ids,query_patient_ids(queryIndex));
    
    distance = regexp(queryDistance{1},',','split');
    distance{1}=distance{1}(2:length(distance{1}));
    distance{length(distance)}=distance{length(distance)}(1:length(distance{length(distance)})-1);
    distance=str2double(distance);
    volume = regexp(queryVolume{1},',','split');
    volume{1}=volume{1}(2:length(volume{1}));
    volume{length(volume)}=volume{length(volume)}(1:length(volume{length(volume)})-1);
    volume=str2double(volume);  
    qOVH = [distance' volume'];

    for dbIndex = 1:length(db_patient_ids)
%     for dbIndex = 1:1    
        %Cycle through all patients
        %disp(sampleIndex)
        [db_PatientID dbDistance dbVolume dbAlpha dbBeta dbGamma dbOverlap dbDistanceMean dbDoseMean dbDoseMax dbROIVolume] = mysql(horzcat('SELECT fk_PatientID, ovhDistance, ovhVolume, alpha, beta, gamma, PercentageOverlap_ROI_Fraction, distanceMean, doseMean, doseMax, Volume FROM structure_set_roi_sequence WHERE id=',num2str(db_patient_ids(dbIndex))));        
        [dbPTVVolume dbPTVDoseMean dbPTVDoseMax] = mysql(horzcat('SELECT Volume, doseMean, doseMax from structure_set_roi_sequence WHERE fk_PatientID="',query_PatientIDs{dbIndex},'" AND (ROIName LIKE "prostate%" OR ROIName LIKE "PROSTATE%")'));
    
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
        
%         %****************************** DETERMINE MATCH ***********************************
%         %if (emdValue<5)&&(sim>0.975)&&(qOverlap<=dbOverlap)&&(qDistanceMean>=dbDistanceMean)&&(qPrescriptionDose<=dbPrescriptionDose)&&(qDoseMean>=dbDoseMean)
%         if (emdValue<10)&&(sim>0.975)&&(qOverlap<=dbOverlap)&&(qDistanceMean>=dbDistanceMean)&&(qDoseMean>=dbDoseMean)&&(qPrescriptionDose<=dbPrescriptionDose)
%           result(counter,1)=query_patient_ids(queryIndex);
%           result(counter,2)=db_patient_ids(dbIndex);
%           result(counter,3)=emdValue;
%           result(counter,4)=sim;
%           result(counter,5)=qDoseMean;
%           result(counter,6)=dbDoseMean;
% %           disp(horzcat('Query Patient: ',num2str(queryPatientID(sampleIndex)),' Dose Mean: ',num2str(qDoseMean)));
% %           disp(horzcat('DB Patient: ',num2str(dbPool(dbIndex)),' Dose Mean: ',num2str(dbDoseMean))); 
%           counter=counter+1;
%         end

        %**********************************************************************************
        
        mysql(horzcat('INSERT INTO bladderPairwise (queryPatientID, dbPatientID, queryDistanceMean, dbDistanceMean, queryDoseMean, dbDoseMean, queryDoseMax, dbDoseMax, queryROIVolume, dbROIVolume, queryProstateVolume, dbProstateVolume, queryProstateDoseMean, dbProstateDoseMean, queryProstateDoseMax, dbProstateDoseMax, queryOverlap, dbOverlap, emd, sim) VALUES (',query_PatientIDs{queryIndex},',',db_PatientID{1},',',num2str(qDistanceMean),',',num2str(dbDistanceMean),',',num2str(qDoseMean),',',num2str(dbDoseMean),',',num2str(qDoseMax),',',num2str(dbDoseMax),',',num2str(qROIVolume),',',num2str(dbROIVolume),',',num2str(qPTVVolume),',',num2str(dbPTVVolume),',',num2str(qPTVDoseMean),',',num2str(dbPTVDoseMean),',',num2str(qPTVDoseMax),',',num2str(dbPTVDoseMax),',',num2str(qOverlap),',',num2str(dbOverlap),',',num2str(emdValue),',',num2str(sim),')'));
        
    end 
end

mysql('close');
clear conn;