clear all;
roiName = 'Bladder';

conn = mysql('open','localhost','root');
mysql('use pt_pr_v3');

patient_ids=mysql(horzcat('SELECT DISTINCT fk_PatientID FROM structure_set_roi_sequence WHERE ROIName LIKE "',roiName,'%" ORDER BY fk_PatientID ASC'));
[doseMean doseMax alpha beta gamma]=mysql(horzcat('SELECT doseMean, doseMax, alpha, beta, gamma FROM structure_set_roi_sequence WHERE ROIName LIKE "',roiName,'%" ORDER BY fk_PatientID ASC'));

numPatients = length(patient_ids);

patientPairs = zeros(nchoosek(numPatients,2),2);
emdPairs = zeros(nchoosek(numPatients,2),1);
doseMeanError = zeros(nchoosek(numPatients,2),1);
doseMaxError = zeros(nchoosek(numPatients,2),1);
counter=1;

for q = 1:numPatients
    disp(horzcat('Patient',num2str(q)));
    for db = 1:numPatients
        if ~strcmp(patient_ids{q},patient_ids{db})
            %patientPairs(counter,1)=patient_ids(q);
            %patientPairs(counter,2)=patient_ids(db);
            emdPairs(counter,1)=PR_emdCalculator(patient_ids{q},patient_ids{db},roiName);
            doseMeanError(counter,1) = abs(doseMean(q)-doseMean(db));
            doseMaxError(counter,1) = abs(doseMax(q)-doseMax(db));
            counter=counter+1;
        end     
    end
end

result = [emdPairs doseMeanError doseMaxError];

mysql('close');
clear conn;