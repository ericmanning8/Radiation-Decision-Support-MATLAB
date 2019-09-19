%test 20 and 8
clear all;
object_patient_id=1;

conn = mysql('open','localhost','root');
mysql('use rt_hn_v5');

[objectDistance objectVolume objectROIList objectOverlap objectDoseMean objectDoseMax] = mysql(horzcat('SELECT ovhDistance_ptv1, ovhVolume_ptv1, stdROIName, PercentageOverlap_ROI_Fraction_ptv1, doseMean, doseMax FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(object_patient_id),' AND stdROIName NOT LIKE "brain" AND stdROIName NOT LIKE "heart" AND stdROIName NOT LIKE "liver" AND stdROIName NOT LIKE "lungRt" AND stdROIName NOT LIKE "lungLt" AND stdROIName NOT LIKE "lungTt" AND stdROIName NOT LIKE "tvc" AND stdROIName NOT LIKE "lensRt" AND stdROIName NOT LIKE "lensLt" AND stdROIName NOT LIKE "chiasm" AND stdROIName NOT LIKE "parotidTt" AND stdROIName NOT LIKE "ptv%"'));
ovhObject = cell(length(objectROIList),1);

objectParameters=cell(1,length(objectROIList),3);

for roiIndex = 1:length(objectROIList)
    distance = regexp(objectDistance{roiIndex},',','split');
    distance{1}=distance{1}(2:length(distance{1}));
    distance{length(distance)}=distance{length(distance)}(1:length(distance{length(distance)})-1);
    distance=str2double(distance);
    volume = regexp(objectVolume{roiIndex},',','split');
    volume{1}=volume{1}(2:length(volume{1}));
    volume{length(volume)}=volume{length(volume)}(1:length(volume{length(volume)})-1);
    volume=str2double(volume);  
    ovhObject{roiIndex} = [distance' volume'];
    objectParameters{1,roiIndex,1}=objectOverlap(roiIndex);
    objectParameters{1,roiIndex,2}=objectDoseMean(roiIndex);
    objectParameters{1,roiIndex,3}=objectDoseMax(roiIndex);
end;

%Select all patient ids other than the object patient id. Exclude all
%patients with no dose and structure set objects
%Exclude patient 49 (Very low dose prescription)
patient_ids=mysql(horzcat('SELECT DISTINCT fk_patient_id FROM structure_set_roi_sequence_copy WHERE fk_patient_id NOT LIKE "',num2str(object_patient_id),'" AND fk_patient_id NOT LIKE "49" AND fk_patient_id NOT LIKE "58" AND fk_patient_id NOT LIKE "61" AND fk_patient_id NOT LIKE "16" AND fk_patient_id NOT LIKE "11" AND fk_patient_id NOT LIKE "23" AND fk_patient_id NOT LIKE "57" AND ptv1 IS NOT NULL'));

%Initialize result set. Rows represent different patients, columns
%represent ROIs in the order given by objectROIList, and the third
%dimension represents parameters: 1-overlap; 2-dose mean; 3-dose max; 4-emd
results=zeros(length(patient_ids),length(objectROIList),4);

for pid = 1:length(patient_ids) %Cycle through all patients
    
    %Exclude brain, lung, liver, heart, etc. Also exclude lens and chiasm
    %because the ovh arrays are too small. Maybe include a mean distance
    %metric for them later?
    [searchROIList searchDistanceResult searchVolumeResult searchOverlap searchDoseMean searchDoseMax] = mysql(horzcat('SELECT stdROIName, ovhDistance_ptv1, ovhVolume_ptv1, PercentageOverlap_ROI_Fraction_ptv1, doseMean, doseMax FROM structure_set_roi_sequence_copy WHERE fk_patient_id=',num2str(patient_ids(pid)),' AND stdROIName NOT LIKE "brain" AND stdROIName NOT LIKE "heart" AND stdROIName NOT LIKE "liver" AND stdROIName NOT LIKE "lungRt" AND stdROIName NOT LIKE "lungLt" AND stdROIName NOT LIKE "lungTt" AND stdROIName NOT LIKE "tvc" AND stdROIName NOT LIKE "lensRt" AND stdROIName NOT LIKE "lensLt" AND stdROIName NOT LIKE "chiasm" AND stdROIName NOT LIKE "parotidTt" AND stdROIName NOT LIKE "ptv%"'));
    
    for roiIndex=1:length(searchROIList)
        temp=strcmp(objectROIList,searchROIList{roiIndex});%Check if this search ROI is present in the object ROI List
        if (~isempty(searchDistanceResult))&&(any(temp))%ensure that the ROI is part of the 0bject ROI List
            %Find position of the ROI in the object list
            objectROIListPosition = find(temp);
            disp(horzcat(num2str(pid),' ',searchROIList{roiIndex},' ',num2str(objectROIListPosition)));
            clear temp;
            clear temp2;            
       
            searchDistance = regexp(searchDistanceResult{roiIndex},',','split');
            searchDistance{1}=searchDistance{1}(2:length(searchDistance{1}));
            searchDistance{length(searchDistance)}=searchDistance{length(searchDistance)}(1:length(searchDistance{length(searchDistance)})-1);
            searchDistance=str2double(searchDistance);

            searchVolume = regexp(searchVolumeResult{roiIndex},',','split');
            searchVolume{1}=searchVolume{1}(2:length(searchVolume{1}));
            searchVolume{length(searchVolume)}=searchVolume{length(searchVolume)}(1:length(searchVolume{length(searchVolume)})-1);
            searchVolume=str2double(searchVolume);

            searchElement=[searchDistance' searchVolume'];
            w1=ones(length(ovhObject{objectROIListPosition}),1);
            w2=ones(length(searchElement),1);
            [x fval] = emd(ovhObject{objectROIListPosition}, searchElement, w1, w2, @gdf);

        results(pid,objectROIListPosition,1)=searchOverlap(roiIndex);
        results(pid,objectROIListPosition,2)=searchDoseMean(roiIndex);
        results(pid,objectROIListPosition,3)=searchDoseMax(roiIndex);
        results(pid,objectROIListPosition,4)=fval;
        
        end

    end
   
end

emdValues=results(:,:,4);
emdMax=max(emdValues,[],2);
emdMean=mean(emdValues,2);
emdStd=std(emdValues,0,2);
[~,sortedIndices]=sort(emdMax);

objectDoseMean=objectDoseMean';
objectDoseMax=objectDoseMax';
objectOverlap=objectOverlap';

for v=1:5
   if any((objectOverlap<results(sortedIndices(v),:,1))&(objectDoseMean>results(sortedIndices(v),:,2)))
       disp(horzcat('Patient ',num2str(patient_ids(sortedIndices(v)))));
       roiIndices=find((objectOverlap<results(sortedIndices(v),:,1))&(objectDoseMean>results(sortedIndices(v),:,2)));
       for w=1:length(roiIndices)
           disp(objectROIList{roiIndices(w)});
           disp(horzcat('Object Overlap: ',num2str(objectOverlap(roiIndices(w))),' Object Dose Mean: ',num2str(objectDoseMean(roiIndices(w)))));
           disp(horzcat('Search Overlap: ',num2str(results(sortedIndices(v),roiIndices(w),1)),' Search Dose Mean: ',num2str(results(sortedIndices(v),roiIndices(w),2))));
       end
   end
end
disp(horzcat('Minimum emd: ',num2str(min(emdMax))));    

mysql('close');
clear conn;