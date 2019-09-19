
patient_number = 4;
folder = strcat('UCLA_PR_',num2str(patient_number));
structureset_file = strcat('UCLA_PR_',num2str(patient_number),'/structureset.dcm');

si=dicominfo(structureset_file);
numStructures=length(fieldnames(si.StructureSetROISequence));%total number of structures in the structure set

roi=cell(numStructures,2);
for j = 1:numStructures
    temp=strcat('Item_',num2str(j));% to generate strings 'Item_1','Item_2', etc.
    id=si.StructureSetROISequence.(temp).ROINumber;
    roi{id,1}=si.StructureSetROISequence.(temp).ROIName;
    roi{id,2}=id;
end

disp(roi);