clear all;

%% database init
conn = mysql('open','localhost','root');
mysql('use rt_hn_v4');
[ssroi_ids dvhs] = mysql('SELECT id, dvh FROM structure_set_roi_sequence_copy WHERE stdROIName IS NOT NULL AND dvh IS NOT NULL');

for i = 1:length(ssroi_ids)
%for i = 13:13
    
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
    maxDose = cumDose(length(cumDose));
    meanDose = sum(cumDose.*volume)/sum(volume);
    
%     for g=1:19
%         dvhSetPoints{g}=findX(cumDose,cumVolume,(g*5));
%     end;
%     d99 =  findX(cumDose,cumVolume,(99));
% 
    mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET doseMean = "',num2str(meanDose), '", doseMax = "',num2str(maxDose),'" WHERE id = "',num2str(ssroi_ids(i)),'"'));
    %disp(horzcat('UPDATE structure_set_roi_sequence SET doseMean = "',num2str(meanDose), '" AND doseMax = "',num2str(maxDose),'" WHERE id = "',num2str(ssroi_ids(i)),'"'));
end


mysql('close');