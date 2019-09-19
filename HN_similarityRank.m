clear all;

conn = mysql('open','localhost','root');
mysql('use rt_hn_v6');

%**************************************************************************

%qPatient = 1; %Query Patient
allPatients = [1 3 4 5 7 8 11 12 14 15 16 17 18 19 20 22 23 24 25 27 29 30 31 32 33 34 35 37 38 40 41 45 47 48 49 50 52 53 54 55 56 57 58 60 62 63 65 67 68 69 70 71];

for qPatientIndex=1:length(allPatients)
    qPatient=allPatients(qPatientIndex);
    dbPatients = allPatients(allPatients ~= qPatient);
    dbPatientsString = sprintf('%.0f,' , dbPatients);
    dbPatientsString = dbPatientsString(1:end-1);

    rois = {'parotidRt','parotidLt','cochleaRt','cochleaLt','tongue','mandible','larynx','pharynx'};
    qrois = {};

    %**************** Get ROI List for qPatient *******************************

    qrois_count=1;
    for i = 1:length(rois)
        roiExists = mysql(horzcat('SELECT id FROM structure_set_roi_sequence WHERE stdROIName = "',rois{i},'" AND fk_patient_id="',num2str(qPatient),'"'));
        if ~isempty(roiExists)
            qrois{qrois_count}=rois{i};
            qrois_count=qrois_count+1;
        end

    end

    %************************* Get all features *******************************

    emd=[];
    sim=[];

    for i = 1:length(qrois)
        emdStack=[];
        simStack=[];
        for currentIdIndex = 1:length(dbPatients)
            queryID = min(qPatient,dbPatients(currentIdIndex));
            dbID = max(qPatient,dbPatients(currentIdIndex));
            [currentEmd,currentSim]=mysql(horzcat('SELECT emd, sim FROM ',qrois{i},' WHERE queryPatientID="',num2str(queryID),'" AND dbPatientID="',num2str(dbID),'"'));
            if isempty(currentEmd)
                emdStack=[emdStack; NaN];
            else
                emdStack=[emdStack; currentEmd];
            end
            if isempty(currentSim)
                simStack=[simStack; NaN];
            else
                simStack=[simStack; currentSim];
            end
        end
        emd = [emd emdStack];
        sim = [sim simStack];
    end

    %*************************** Normalize EMD ********************************
    maxEMD = max(max(emd));
    emdNew=emd./maxEMD;
    emdNew=ones(size(emdNew))-emdNew;

    %*************************** SIMILARITY VECTOR ****************************

    similarity = zeros(length(emdNew),1);
    for i = 1:length(similarity)
        s=0;
        numFeatures = 0;
        for j = 1:length(qrois)
            if ~isnan(emdNew(i,j))
                s=s+emdNew(i,j)+sim(i,j);
                numFeatures=numFeatures+2;
            end
            similarity(i)=(s/numFeatures)*100;
        end
    end

    %*************************** Filter Matches *******************************

    filteredMatchIndices = find(similarity>90);
    filteredMatches = dbPatients(filteredMatchIndices);

    for i=1:length(qrois)
        for j=1:length(filteredMatches)
            similarityValue = similarity(filteredMatchIndices(j));
            [qDoseMean, qDoseMax, qDistanceMean, qOverlap, qDosePrescription]=mysql(horzcat('SELECT doseMean, doseMax, DistanceMean_ptv1, PercentageOverlap_ROI_Fraction_ptv1, dosePrescription FROM structure_set_roi_sequence_copy WHERE stdROIName="',qrois{i},'" AND fk_patient_id="',num2str(qPatient),'"'));
            [dbDoseMean, dbDoseMax, dbDistanceMean, dbOverlap, dbDosePrescription]=mysql(horzcat('SELECT doseMean, doseMax, DistanceMean_ptv1, PercentageOverlap_ROI_Fraction_ptv1, dosePrescription FROM structure_set_roi_sequence_copy WHERE stdROIName="',qrois{i},'" AND fk_patient_id="',num2str(filteredMatches(j)),'"'));
            if ~isempty(dbDoseMean)
                % Get PTV Volumes of the query and db patients
                qptv = mysql(horzcat('SELECT ptv1 FROM structure_set_roi_sequence_copy WHERE stdROIName="',qrois{i},'" AND fk_patient_id="',num2str(qPatient),'"'));
                dbptv = mysql(horzcat('SELECT ptv1 FROM structure_set_roi_sequence_copy WHERE stdROIName="',qrois{i},'" AND fk_patient_id="',num2str(filteredMatches(j)),'"'));
                qptvVolume = mysql(horzcat('SELECT Volume FROM structure_set_roi_sequence_copy WHERE stdROIName="',qptv{1},'" AND fk_patient_id="',num2str(qPatient),'"'));
                dbptvVolume = mysql(horzcat('SELECT Volume FROM structure_set_roi_sequence_copy WHERE stdROIName="',dbptv{1},'" AND fk_patient_id="',num2str(filteredMatches(j)),'"'));
                if ((qDoseMean>dbDoseMean+4)&&((qOverlap<dbOverlap)&&(qDistanceMean>dbDistanceMean))&&(qDosePrescription<dbDosePrescription+200))
                    mysql(horzcat('INSERT INTO outliersLowSimThreshold (queryID, dbID, roi, queryDoseMean, dbDoseMean, queryDoseMax, dbDoseMax, queryDistance, dbDistance, queryOverlap, dbOverlap, queryPtvVolume, dbPtvVolume, similarity) VALUES ("',num2str(qPatient),'","',num2str(filteredMatches(j)),'","',qrois{i},'","',num2str(qDoseMean),'","',num2str(dbDoseMean),'","',num2str(qDoseMax),'","',num2str(dbDoseMax),'","',num2str(qDistanceMean),'","',num2str(dbDistanceMean),'","',num2str(qOverlap),'","',num2str(dbOverlap),'","',num2str(qptvVolume),'","',num2str(dbptvVolume),'","',num2str(similarityValue),'")'));
                end
            end
        end
    end
end



