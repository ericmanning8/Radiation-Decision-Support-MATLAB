clear all;

%% database init
conn = mysql('open','localhost','root');
mysql('use rt_hn_v5');
[ssroi_ids dvhs] = mysql('SELECT id, dvh FROM structure_set_roi_sequence_copy WHERE stdROIName IS NOT NULL AND dvh IS NOT NULL');

for i = 1:length(ssroi_ids)
%for i = 197:197
    
    dvhCell=dvhs{i};
    
    dvh = regexp(dvhCell,',','split');%Split the first set of contour data points at the commas
    if dvh{1}(1)=='['
        dvh{1}=dvh{1}(2:length(dvh{1}));%Trim the '[' character off 
        dvh{length(dvh)}=dvh{length(dvh)}(1:length(dvh{length(dvh)})-1);%Trim the ']' character off 
    end;
    
    dvh=str2double(dvh);%convert to an array of doubles
    
    doseBinWidths = dvh(1:2:length(dvh));
    volume = dvh(2:2:length(dvh));
    cumDose = cumsum(doseBinWidths);
    cumVolume = (fliplr(cumsum(fliplr(volume)))/sum(volume))*100;
    
    dvhDose = mat2str(round(cumDose*10000)/10000);
    dvhDose = strrep(dvhDose, ' ', ',');
    dvhVolume = mat2str(round(cumVolume*10000)/10000);
    dvhVolume = strrep(dvhVolume, ' ', ',');
    
%     dvhSetPoints = cell(19,1);
% 
%     for g=1:19
%         dvhSetPoints{g}=findX(cumDose,cumVolume,(g*5));
%     end;
%     d99 =  findX(cumDose,cumVolume,(99));

    %mysql(horzcat('UPDATE structure_set_roi_sequence set d5="',num2str(dvhSetPoints{1}),'", d10="',num2str(dvhSetPoints{2}),'", d15="',num2str(dvhSetPoints{3}),'", d20="',num2str(dvhSetPoints{4}),'", d25="',num2str(dvhSetPoints{5}),'", d30="',num2str(dvhSetPoints{6}),'", d35="',num2str(dvhSetPoints{7}),'", d40="',num2str(dvhSetPoints{8}),'", d45="',num2str(dvhSetPoints{9}),'", d50="',num2str(dvhSetPoints{10}),'", d55="',num2str(dvhSetPoints{11}),'", d60="',num2str(dvhSetPoints{12}),'", d65="',num2str(dvhSetPoints{13}),'", d70="',num2str(dvhSetPoints{14}),'", d75="',num2str(dvhSetPoints{15}),'", d80="',num2str(dvhSetPoints{16}),'", d85="',num2str(dvhSetPoints{17}),'", d90="',num2str(dvhSetPoints{18}),'", d95="',num2str(dvhSetPoints{19}),'", d99="',num2str(d99),'" WHERE id="',num2str(ssroi_ids(i)),'"'));  
    mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET dvhDose="',dvhDose,'", dvhVolume="',dvhVolume,'" WHERE id="',num2str(ssroi_ids(i)),'"'));
end


mysql('close');