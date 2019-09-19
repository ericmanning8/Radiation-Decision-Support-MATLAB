clear all;

conn = mysql('open','localhost','root');
mysql('use rt_hn_v6');
roi = 'eyeRt';

allPatients = [1 3 4 5 7 8 11 12 14 15 16 17 18 19 20 22 23 24 25 27 29 30 31 32 33 34 35 37 38 40 41 45 47 48 49 50 52 53 54 55 56 57 58 60 62 63 65 67 68 69 70 71];
realValues = [];
predictedValues = [];

for i = 1:length(allPatients)
    qPatient = allPatients(i);
    dbPatients = allPatients(allPatients ~= qPatient);
    dbPatientsString = sprintf('%.0f,' , dbPatients);
    dbPatientsString = dbPatientsString(1:end-1);
    [ovh10, ovh20, ovh30, ovh40, ovh50, ovh60, ovh70, ovh80, ovh90, ovh95, alpha, beta, gamma, doseMean] = mysql(horzcat('SELECT ptv1_ovh10, ptv1_ovh20, ptv1_ovh30, ptv1_ovh40, ptv1_ovh50, ptv1_ovh60, ptv1_ovh70, ptv1_ovh80, ptv1_ovh90, ptv1_ovh95, alpha_ptv1, beta_ptv1, gamma_ptv1, doseMean FROM structure_set_roi_sequence_copy WHERE stdROIName="',roi,'" AND fk_patient_id IN (',dbPatientsString,')'));
    [qovh10, qovh20, qovh30, qovh40, qovh50, qovh60, qovh70, qovh80, qovh90, qovh95, qalpha, qbeta, qgamma, qdoseMean] = mysql(horzcat('SELECT ptv1_ovh10, ptv1_ovh20, ptv1_ovh30, ptv1_ovh40, ptv1_ovh50, ptv1_ovh60, ptv1_ovh70, ptv1_ovh80, ptv1_ovh90, ptv1_ovh95, alpha_ptv1, beta_ptv1, gamma_ptv1, doseMean FROM structure_set_roi_sequence_copy WHERE stdROIName="',roi,'" AND fk_patient_id = "',num2str(qPatient),'"'));
    %training_inputs = [ovh10 ovh20 ovh30 ovh40 ovh50 ovh60 ovh70 ovh80 ovh90 ovh95 alpha beta gamma];
    training_inputs = [ovh10 ovh30 ovh50 ovh70 ovh90 ovh95 alpha beta gamma];
    training_output = doseMean;
    [b,bint]=regress(training_output, training_inputs);
    mdl = LinearModel.fit(training_inputs,training_output);
    %prediction_inputs = [qovh10 qovh20 qovh30 qovh40 qovh50 qovh60 qovh70 qovh80 qovh90 qovh95 qalpha qbeta qgamma];
    prediction_inputs = [qovh10 qovh30 qovh50 qovh70 qovh90 qovh95 qalpha qbeta qgamma];
    predicted_output = predict(mdl,prediction_inputs);
    realValues = [realValues qdoseMean];
    predictedValues = [predictedValues predicted_output];
end
figure;
plot(1:length(realValues),realValues, 'black');
hold on;
plot(1:length(realValues),predictedValues,'red');
    
[h,p] = ttest(realValues,predictedValues);
rho = corr(realValues',predictedValues');
mysql('close');    
clear conn;