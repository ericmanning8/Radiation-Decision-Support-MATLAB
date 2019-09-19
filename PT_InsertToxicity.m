clear all;
conn = mysql('open','localhost','root');
mysql('use pttest');
PatientIDs = mysql('SELECT DISTINCT fk_PatientID FROM volume_distance');
for i = 1: length(PatientIDs)
    week1_toxicity = mysql(horzcat('SELECT toxicity_grade FROM pt_toxicity_info WHERE fk_PatientID = "',num2str(PatientIDs{i,1}),'" AND week = "1"'));
    week2_toxicity = mysql(horzcat('SELECT toxicity_grade FROM pt_toxicity_info WHERE fk_PatientID = "',num2str(PatientIDs{i,1}),'" AND week = "2"'));
    week3_toxicity = mysql(horzcat('SELECT toxicity_grade FROM pt_toxicity_info WHERE fk_PatientID = "',num2str(PatientIDs{i,1}),'" AND week = "3"'));
    week4_toxicity = mysql(horzcat('SELECT toxicity_grade FROM pt_toxicity_info WHERE fk_PatientID = "',num2str(PatientIDs{i,1}),'" AND week = "4"'));
    
    mysql(horzcat('UPDATE volume_distance SET week1_toxicity = "',num2str(week1_toxicity),'", week2_toxicity = "',num2str(week2_toxicity),'", week3_toxicity = "',num2str(week3_toxicity),'", week4_toxicity = "',num2str(week4_toxicity),'" WHERE fk_PatientID = "',num2str(PatientIDs{i,1}),'"'));
end;
mysql('close');