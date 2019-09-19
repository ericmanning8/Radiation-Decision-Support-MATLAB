clear all;
roiName = 'larynx';

conn = mysql('open','localhost','root');
mysql('use rt_hn_v6');

[id qID dbID qDist dbDist qDoseMean dbDoseMean qDoseMax dbDoseMax qROIVol dbROIVol qPTVVol dbPTVVol qPTVDoseMean dbPTVDoseMean qPTVDoseMax dbPTVDoseMax qOverlap dbOverlap qPrescription dbPrescription emd sim]=mysql(horzcat('SELECT * from ',roiName,' ORDER BY id'));

for i=1:length(id)
    if (emd(i)<10)&&(sim(i)>0.975)&&(qOverlap(i)<=dbOverlap(i))&&(qDist(i)>=dbDist(i))&&(qDoseMean(i)>=dbDoseMean(i))&&(qPrescription(i)<=dbPrescription(i));
        disp(horzcat(num2str(qID(i)),';',num2str(dbID(i)),';',num2str(qDoseMean(i)),';',num2str(dbDoseMean(i)),';',num2str(qDoseMax(i)),';',num2str(dbDoseMax(i)),';',num2str(qOverlap(i)),';',num2str(dbOverlap(i)),';',num2str(qDist(i)),';',num2str(dbDist(i)),';',num2str(qPTVDoseMean(i)),';',num2str(dbPTVDoseMean(i)),';',num2str(qPTVDoseMax(i)),';',num2str(dbPTVDoseMax(i)),';',num2str(qROIVol(i)),';',num2str(dbROIVol(i)),';',num2str(qPTVVol(i)),';',num2str(dbPTVVol(i)),';',num2str(qPrescription(i)),';',num2str(dbPrescription(i)),';',num2str(emd(i)),';',num2str(sim(i))));
    end
end