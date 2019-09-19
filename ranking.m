clear all;
conn = mysql('open','localhost','root');
mysql('use rt_hn_v6');
queryPatientID = '1';
[parotidRtId parotidRtEmd parotidRtSim]=mysql(horzcat('SELECT dbPatientID, emd, sim FROM parotidRt WHERE queryPatientID="',queryPatientID,'" ORDER BY dbPatientID ASC'));
[parotidLtId parotidLtEmd parotidLtSim]=mysql(horzcat('SELECT dbPatientID, emd, sim FROM parotidLt WHERE queryPatientID="',queryPatientID,'" ORDER BY dbPatientID ASC'));
[mandibleId mandibleEmd mandibleSim]=mysql(horzcat('SELECT dbPatientID, emd, sim FROM mandible WHERE queryPatientID="',queryPatientID,'" ORDER BY dbPatientID ASC'));
[tongueId tongueEmd tongueSim]=mysql(horzcat('SELECT dbPatientID, emd, sim FROM tongue WHERE queryPatientID="',queryPatientID,'" ORDER BY dbPatientID ASC'));
[cochleaRtId cochleaRtEmd cochleaRtSim]=mysql(horzcat('SELECT dbPatientID, emd, sim FROM cochleaRt WHERE queryPatientID="',queryPatientID,'" ORDER BY dbPatientID ASC'));
[cochleaLtId cochleaLtEmd cochleaLtSim]=mysql(horzcat('SELECT dbPatientID, emd, sim FROM cochleaLt WHERE queryPatientID="',queryPatientID,'" ORDER BY dbPatientID ASC'));
[eyeRtId eyeRtEmd eyeRtSim]=mysql(horzcat('SELECT dbPatientID, emd, sim FROM eyeRt WHERE queryPatientID="',queryPatientID,'" ORDER BY dbPatientID ASC'));
[eyeLtId eyeLtEmd eyeLtSim]=mysql(horzcat('SELECT dbPatientID, emd, sim FROM eyeLt WHERE queryPatientID="',queryPatientID,'" ORDER BY dbPatientID ASC'));
[larynxId larynxEmd larynxSim]=mysql(horzcat('SELECT dbPatientID, emd, sim FROM larynx WHERE queryPatientID="',queryPatientID,'" ORDER BY dbPatientID ASC'));
[pharynxId pharynxEmd pharynxSim]=mysql(horzcat('SELECT dbPatientID, emd, sim FROM pharynx WHERE queryPatientID="',queryPatientID,'" ORDER BY dbPatientID ASC'));

ids = [parotidRtId; parotidLtId; mandibleId; tongueId; cochleaRtId; cochleaLtId; eyeRtId; eyeLtId; larynxId; pharynxId];
ids = unique(ids);

%figure;

results = zeros(length(ids),6);

emdValues=[];
simValues=[];
for i = 1:length(ids)
    counter=0;
    if any(parotidRtId==ids(i))
        emdValues = [emdValues; parotidRtEmd(parotidRtId==ids(i))];
        simValues = [simValues; parotidRtSim(parotidRtId==ids(i))];
        counter=counter+1;
    end
    if any(parotidLtId==ids(i))
        emdValues = [emdValues; parotidLtEmd(parotidLtId==ids(i))];
        simValues = [simValues; parotidLtSim(parotidLtId==ids(i))];
        counter=counter+1;
    end   
    if any(eyeRtId==ids(i))
        emdValues = [emdValues; eyeRtEmd(eyeRtId==ids(i))];
        simValues = [simValues; eyeRtSim(eyeRtId==ids(i))];
        counter=counter+1;
    end
    if any(eyeLtId==ids(i))
        emdValues = [emdValues; eyeLtEmd(eyeLtId==ids(i))];
        simValues = [simValues; eyeLtSim(eyeLtId==ids(i))];
        counter=counter+1;
    end
    if any(cochleaRtId==ids(i))
        emdValues = [emdValues; cochleaRtEmd(cochleaRtId==ids(i))];
        simValues = [simValues; cochleaRtSim(cochleaRtId==ids(i))];
        counter=counter+1;
    end
    if any(cochleaLtId==ids(i))
        emdValues = [emdValues; cochleaLtEmd(cochleaLtId==ids(i))];
        simValues = [simValues; cochleaLtSim(cochleaLtId==ids(i))];
        counter=counter+1;
    end
    if any(larynxId==ids(i))
        emdValues = [emdValues; larynxEmd(larynxId==ids(i))];
        simValues = [simValues; larynxSim(larynxId==ids(i))];
        counter=counter+1;
    end
    if any(pharynxId==ids(i))
        emdValues = [emdValues; pharynxEmd(pharynxId==ids(i))];
        simValues = [simValues; pharynxSim(pharynxId==ids(i))];
        counter=counter+1;
    end
    if any(tongueId==ids(i))
        emdValues = [emdValues; tongueEmd(tongueId==ids(i))];
        simValues = [simValues; tongueSim(tongueId==ids(i))];
        counter=counter+1;
    end
    if any(mandibleId==ids(i))
        emdValues = [emdValues; mandibleEmd(mandibleId==ids(i))];
        simValues = [simValues; mandibleSim(mandibleId==ids(i))];
        counter=counter+1;
    end
    
%     if i<30
%         scatter(ones(size(emdValues)).*ids(i),emdValues,'blue');hold on;
%     end;
    emdMean=mean(emdValues);
    emdMedian = median(emdValues);
    emdStd = std(emdValues);
    emdMin = min(emdValues);
    
    simMean = mean(simValues);
    simStd = std(simValues);
    simMax = max(simValues);
    
    results(i,1)=emdMean;
    
%     if i<30
%         scatter(ids(i),emdMean,'red');
%         scatter(ids(i),emdMedian,'black');
%     end
    results(i,2)=emdStd;
    results(i,3)=emdMin;
    results(i,4)=simMean;
    results(i,5)=simStd;
    results(i,6)=simMax;
    clear emdValues;
    clear simValues;
    emdValues=[];
    simValues=[];
end
ranks = ((100-(results(:,1)./max(results(:,1))).*100)).*results(:,4);
figure;
scatter(1:length(ids),(results(:,1)./max(results(:,1))).*100,'blue');hold on;
scatter(1:length(ids),results(:,4).*100,'red');hold on;
scatter(1:length(ids),ranks,'black');
mysql('close');
clear conn;