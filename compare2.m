function compare2(patient_id1, patient_id2, roiName)

    conn_compare2 = mysql('open','localhost','root');
    mysql('use rt_hn_v6');
    
    [dvhDose1,dvhVolume1]=getDVHdb(patient_id1,roiName);
    [dvhDose2,dvhVolume2]=getDVHdb(patient_id2,roiName);
    [ovhDistance1,ovhVolume1]=getOVHdb(patient_id1,roiName);
    [ovhDistance2,ovhVolume2]=getOVHdb(patient_id2,roiName);
    
    text_patient1=horzcat('Patient ',num2str(patient_id1));
    text_patient2=horzcat('Patient ',num2str(patient_id2));
    
    figure;
    plot(dvhDose1,dvhVolume1,'r');
    hold on;
    plot(dvhDose2,dvhVolume2,'b');
    legend(text_patient1, text_patient2);
    
    figure;
    plot(ovhDistance1,ovhVolume1,'r');
    hold on;
    plot(ovhDistance2,ovhVolume2,'b');
    legend(text_patient1, text_patient2);
      
    clear conn_compare2;
    mysql('close');
end