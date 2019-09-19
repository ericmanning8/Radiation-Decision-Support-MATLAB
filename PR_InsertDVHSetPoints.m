clear all;

%% database init
conn = mysql('open','localhost','root');
mysql('use pt_pr_v3');
[ssroi_ids] = mysql('SELECT id FROM structure_set_roi_sequence');

for i = 1:length(ssroi_ids)
%for i = 197:197
     
    [dvhDose, dvhVolume] = mysql(horzcat('SELECT dvhDose, dvhVolume FROM structure_set_roi_sequence WHERE id="',num2str(ssroi_ids(i)),'"'));
   
    dvhDose = regexp(dvhDose{1},',','split');
    dvhDose{1}=dvhDose{1}(2:length(dvhDose{1}));%Trim the '[' character off 
    dvhDose{length(dvhDose)}=dvhDose{length(dvhDose)}(1:length(dvhDose{length(dvhDose)})-1);%Trim the ']' character off 
    dvhDose = str2double(dvhDose);
    
    dvhVolume = regexp(dvhVolume{1},',','split');%Split the first set of contour data points at the commas
    dvhVolume{1}=dvhVolume{1}(2:length(dvhVolume{1}));%Trim the '[' character off 
    dvhVolume{length(dvhVolume)}=dvhVolume{length(dvhVolume)}(1:length(dvhVolume{length(dvhVolume)})-1);%Trim the ']' character off 
    dvhVolume = str2double(dvhVolume);
    
    dvhSetPoints = cell(19,1);

    for g=1:19
        dvhSetPoints{g}=findX(dvhDose,dvhVolume,(g*5));
    end;
    d99 =  findX(dvhDose,dvhVolume,(99));

    mysql(horzcat('UPDATE structure_set_roi_sequence set d5="',num2str(dvhSetPoints{1}),'", d10="',num2str(dvhSetPoints{2}),'", d15="',num2str(dvhSetPoints{3}),'", d20="',num2str(dvhSetPoints{4}),'", d25="',num2str(dvhSetPoints{5}),'", d30="',num2str(dvhSetPoints{6}),'", d35="',num2str(dvhSetPoints{7}),'", d40="',num2str(dvhSetPoints{8}),'", d45="',num2str(dvhSetPoints{9}),'", d50="',num2str(dvhSetPoints{10}),'", d55="',num2str(dvhSetPoints{11}),'", d60="',num2str(dvhSetPoints{12}),'", d65="',num2str(dvhSetPoints{13}),'", d70="',num2str(dvhSetPoints{14}),'", d75="',num2str(dvhSetPoints{15}),'", d80="',num2str(dvhSetPoints{16}),'", d85="',num2str(dvhSetPoints{17}),'", d90="',num2str(dvhSetPoints{18}),'", d95="',num2str(dvhSetPoints{19}),'", d99="',num2str(d99),'" WHERE id="',num2str(ssroi_ids(i)),'"'));  
    %mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET dvhDose="',dvhDose,'", dvhVolume="',dvhVolume,'" WHERE id="',num2str(ssroi_ids(i)),'"'));
end


mysql('close');
clear conn;