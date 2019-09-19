%% assumes that one plane has only one contour
tic;
clear all;
%% database init
conn = mysql('open','localhost','root');
mysql('use rt_hn_v6');
patient_ids=[1 2 3 4 5 7 8 9 11 12 14 15 16 17 18 19 20 21 22 23 24 25 27 29 30 31 32 33 34 35 37 38 39 40 41 44 45 47 48 49 50 52 53 54 55 56 57 58 60 62 63 65 67 68 69 70 71];

color = [65 105 225; 124 252 0; 135 206 250; 255 255 0; 255 165 0; 255 20 147; 255 0 0; 51 255 255; 0 128 0; 32 178 170; 102 102 102; 51 0 0; 204 102 102; 153 0 102; 51 204 51; 255 204 0; 204 255 51; 102 51 0; 201 153 153; 204 255 51; 51 102 0; 204 204 204;102 102 0; 102 0 51; 255 204 255; 255 204 153; 102 0 102]/255; 

for pid=1:length(patient_ids)
    %patient_id=input('Enter Patient ID:');
    patient_id=patient_ids(pid);
    disp(horzcat('Processing Patient ',num2str(patient_id)));

    %Get ROI information for every ROI. roiNumber, stdROIName etc are all lists
    [structure_set_roi_sequence_ids, roiNumbers, stdROINames, structure_set_ids, strSet_sop_ids, strSet_series_ids, strSet_study_ids, roi_dose_ids, roi_dvh_sequence_ids] = mysql(horzcat('SELECT id, ROINumber, stdROIName, fk_structure_set_id, fk_sop_id, fk_series_id, fk_study_id, fk_dose_id, fk_dvh_sequence_id FROM structure_set_roi_sequence_copy WHERE fk_patient_id = ',num2str(patient_id),' AND stdROIName IS NOT NULL'));

    %Since every contour has an associated CT Slice, extract the first ct image
    %for the first roi
    [sampleCTSOP, ct_series_id] = mysql(horzcat('SELECT ct_fk_sop_id, ct_fk_series_id FROM contour_sequence WHERE fk_structure_set_roi_sequence_id = "',num2str(structure_set_roi_sequence_ids(1)),'" LIMIT 1'));
    numCTs = mysql(horzcat('SELECT numCTifCT FROM series WHERE id = "',num2str(ct_series_id),'"'));%Get number of CT Images
    %Get row spacing, slice spacing etc based on the sample ct image
    [rowSpacing, columnSpacing, sliceSpacing, width, height]=mysql(horzcat('SELECT pixelSpacingRow, pixelSpacingColumn, sliceThickness, columns, rows FROM image_plane_pixel WHERE fk_sop_id="',num2str(sampleCTSOP),'"'));
    rowSpacing=str2double(rowSpacing{1,1});columnSpacing=str2double(columnSpacing{1,1});sliceSpacing=str2double(sliceSpacing{1,1});
    imageBlock=zeros(height, width, numCTs);

    %imgPosPatZ gives the z indices of all CT images. This is useful in
    %assembling the CT Block
    imgPosPatZ = sort(str2double(mysql(horzcat('SELECT imgPosPatZ FROM image_plane_pixel WHERE fk_series_id="',num2str(ct_series_id),'"'))));
    allCTs = mysql(horzcat('SELECT id FROM sop WHERE fk_series_id="',num2str(ct_series_id),'"'));
    for vv=1:length(allCTs)
            [ser,st,pat]=mysql(horzcat('SELECT fk_series_id,fk_study_id,fk_patient_id FROM sop WHERE id="',num2str(allCTs(vv)),'"'));
            ct_z=str2double(mysql(horzcat('SELECT imgPosPatZ FROM image_plane_pixel WHERE fk_sop_id="',num2str(allCTs(vv)),'"')));
            imageBlock(:,:,imgPosPatZ==ct_z)=im2double(dicomread(horzcat('/Users/ruchi/Documents/python/rt/test/dicom/',num2str(pat),'/',num2str(st),'/',num2str(ser),'/',num2str(allCTs(vv)),'.dcm')));        
    end;

    %% ************************* LOOP OVER EACH ROI *************************************
    %% **********************************************************************************
    legendList={};
    counter=1;
    for i=1:length(stdROINames) %For each ROI in the patient's ROI Sequence

        %if strcmp(stdROINames{i},'parotidRt')
        if (~(strcmp(stdROINames{i},'brain')||strcmp(stdROINames{i},'heart')||strcmp(stdROINames{i},'liver')||strcmp(stdROINames{i},'lungLt')||strcmp(stdROINames{i},'lungRt')||strcmp(stdROINames{i},'lungTt')||strcmp(stdROINames{i},'tvc')||strcmp(stdROINames{i}(1:3),'ptv')))%execute only if the ROI is not a PTV

            currentROIName = stdROINames{i};
            legendList{counter}=currentROIName;
            disp(horzcat('Processing ',currentROIName,' ',num2str(i),' of ',num2str(length(stdROINames))));
            roiBlock=HN_getContoursFull(patient_id, stdROINames{i}); 

            %Calculate ROI Volume
            roiVolume = sum(sum(sum(roiBlock*rowSpacing*columnSpacing*sliceSpacing)))/1000;
            mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET Volume="',num2str(roiVolume),'" WHERE stdROIName = "',stdROINames{i},'" AND fk_patient_id="',num2str(patient_id),'"'));

            % Get a list of all the PTVs
            ptvs = mysql(horzcat('SELECT stdROIName FROM structure_set_roi_sequence_copy WHERE stdROIName LIKE "ptv%" AND fk_patient_id = "',num2str(patient_id),'" ORDER BY stdROIName DESC'));

                for ptvIndex = 1:length(ptvs)
                    %% SEPARATION OF OAR into intersecting and non-intersecting parts
                    ptvName = horzcat('ptv',int2str(ptvIndex));
                    ptvBlock=HN_getContoursFull(patient_id, ptvs{ptvIndex});
                    disp(horzcat('Processing ',ptvs{ptvIndex}));
                    ptvOutline3D = zeros(size(ptvBlock));
                    for j = 2:(size(ptvBlock,3)-1)
                        ptvOutline3D(:,:,j) = bwperim(ptvBlock(:,:,j));
                    end
                    ptvOutline3D(:,:,1) = ptvBlock(:,:,1);
                    ptvOutline3D(:,:,size(ptvBlock,3)) = ptvBlock(:,:,size(ptvBlock,3));

                    roiIntersecting = roiBlock&ptvBlock;
                    roiNonIntersecting = roiBlock - roiIntersecting;

                    %% CALCULATE ORGAN VOLUMES

                    roiIntersectingVolume = sum(sum(sum(roiIntersecting*rowSpacing*columnSpacing*sliceSpacing)))/1000;
                    roiPercentageOverlap_OAR_Fraction = roiIntersectingVolume/roiVolume*100;

                    ptvVolume = sum(sum(sum(ptvBlock*rowSpacing*columnSpacing*sliceSpacing)))/1000;
                    roiPercentageOverlap_Total_Fraction = roiIntersectingVolume/(roiVolume+ptvVolume)*100;

                    %% Get positions of all ON pixels in the organ masks and the smooth ptv contour object
                    % bladderSub contains pixel positions of all ON pixels in the solid bladder
                    % mask, and rectumSub for the rectum. ptvSub has pixel positions of all ON
                    % pixels in the smoothened outline mask of the ptv

                    %INITIALIZE
                    numRoiVoxels = nnz(roiBlock);
                    numPtvVoxels = nnz(ptvBlock);
                    roiSub = zeros(numRoiVoxels,3);
                    ptvSub = zeros(numPtvVoxels,3);

                    numIntersectingRoiVoxels = nnz(roiIntersecting);
                    numNonIntersectingRoiVoxels = nnz(roiNonIntersecting);
                    numPtvOutlineVoxels = nnz(ptvOutline3D);

                    roiIntersectingSub = zeros(numIntersectingRoiVoxels,4);
                    roiNonIntersectingSub = zeros(numNonIntersectingRoiVoxels,4);
                    ptvOutlineSub = zeros(numPtvOutlineVoxels,3);

                    %FIND LINEAR INDICES OF ALL NON ZERO VOXELS

                    roiLin = find(roiBlock);
                    ptvLin = find(ptvBlock);

                    roiIntersectingLin = find(roiIntersecting);
                    roiNonIntersectingLin = find(roiNonIntersecting);
                    ptvOutlineLin = find(ptvOutline3D);

                    %CONVERT LINEAR INDICES TO SUBSCRIPTS 
                    %bladderIntersectingSub is an nx4 array, where n is the number of bladder
                    %voxels, and each row of the array contains the pixel coordinates of a
                    %voxel and the minimum distance to the PTV surface of that voxel

                    [roiSub(:,1), roiSub(:,2), roiSub(:,3)] = ind2sub(size(roiBlock),roiLin);
                    [ptvSub(:,1), ptvSub(:,2), ptvSub(:,3)] = ind2sub(size(ptvBlock),ptvLin);

                    [roiIntersectingSub(:,1), roiIntersectingSub(:,2), roiIntersectingSub(:,3)] = ind2sub(size(roiIntersecting),roiIntersectingLin);
                    [roiNonIntersectingSub(:,1), roiNonIntersectingSub(:,2), roiNonIntersectingSub(:,3)] = ind2sub(size(roiNonIntersecting),roiNonIntersectingLin); 
                    [ptvOutlineSub(:,1), ptvOutlineSub(:,2), ptvOutlineSub(:,3)] = ind2sub(size(ptvOutline3D),ptvOutlineLin);

                    % %% WEIGHTED EUCLIDEAN DISTANCE FOR OVH
                    % % d((i,j,k),(a,b,c))=sqrt[1(i-a)^2+alpha(j-b)^2+beta(k-c)^2], where the
                    % % ratio of the sampling intervals in the three axes is 1:alpha:beta for
                    % % row:column:plane viz 1:columnSpacing/rowSpacing:heightSpacing/rowSpacing
                    alpha = columnSpacing/rowSpacing;
                    beta = sliceSpacing/rowSpacing;

                    %% CALCULATE MINIMUM DISTANCE FROM EACH OAR POINT TO THE PTV OUTLINE FOR OVH

                    if (numIntersectingRoiVoxels~=0) 
                        for oarVoxel = 1:numIntersectingRoiVoxels
                            minimumDistance=1000000;
                            for ptvVoxel = 1:numPtvOutlineVoxels
                                distance = sqrt((columnSpacing*(ptvOutlineSub(ptvVoxel,1)-roiIntersectingSub(oarVoxel,1)))^2+(rowSpacing*(ptvOutlineSub(ptvVoxel,2)-roiIntersectingSub(oarVoxel,2)))^2+(sliceSpacing*(ptvOutlineSub(ptvVoxel,3)-roiIntersectingSub(oarVoxel,3)))^2);
                                minimumDistance = min(minimumDistance, distance);
                            end
                            roiIntersectingSub(oarVoxel,4) = -1*minimumDistance;
                        end

                        roiIntersectingBinWidth = 2*iqr(roiIntersectingSub(:,4))*(numIntersectingRoiVoxels^(-1/3));
                        if (roiIntersectingBinWidth==0)
                            numBins_roiIntersecting=10;
                        else
                            numBins_roiIntersecting = (max(roiIntersectingSub(:,4))-min(roiIntersectingSub(:,4)))/roiIntersectingBinWidth; 
                        end;

                        [v_roiIntersecting, r_roiIntersecting] = hist(roiIntersectingSub(:,4),numBins_roiIntersecting);

                        temp_r_roiIntersecting=r_roiIntersecting;
                        temp_v_roiIntersecting=v_roiIntersecting;
                        clear r_roiIntersecting;
                        clear v_roiIntersecting;
                        r_roiIntersecting=[];
                        v_roiIntersecting=[];

                        for v=1:length(temp_r_roiIntersecting)
                            if (temp_r_roiIntersecting(v)<0||temp_r_roiIntersecting(v)==0)
                                r_roiIntersecting=horzcat(r_roiIntersecting, temp_r_roiIntersecting(v));
                                v_roiIntersecting=horzcat(v_roiIntersecting, temp_v_roiIntersecting(v));
                            end;     
                        end;

                    else %The OAR is entirely outside the PTV
                        v_roiIntersecting=[];
                        r_roiIntersecting=[];
                        roiIntersectingBinWidth=0;
                    end;

                    % hist: r_bladderIntersecting gives the bin positions, i.e. the center of
                    % each bin. Therefore, r_bladderIntersecting(2)-r_bladderIntersecting(1)
                    % gives the bin width

                    %% do for Non Intersecting part of the ROI

                    if (numNonIntersectingRoiVoxels~=0)
                        for oarVoxel = 1:numNonIntersectingRoiVoxels
                            minimumDistance=1000000;
                            for ptvVoxel = 1:numPtvOutlineVoxels
                                distance = sqrt((columnSpacing*(ptvOutlineSub(ptvVoxel,1)-roiNonIntersectingSub(oarVoxel,1)))^2+(rowSpacing*(ptvOutlineSub(ptvVoxel,2)-roiNonIntersectingSub(oarVoxel,2)))^2+(sliceSpacing*(ptvOutlineSub(ptvVoxel,3)-roiNonIntersectingSub(oarVoxel,3)))^2);
                                minimumDistance = min(minimumDistance, distance);
                            end
                            roiNonIntersectingSub(oarVoxel,4) = minimumDistance;
                        end

                        roiNonIntersectingBinWidth = 2*iqr(roiNonIntersectingSub(:,4))*(numNonIntersectingRoiVoxels^(-1/3));

                        if (roiNonIntersectingBinWidth==0)
                            numBins_roiNonIntersecting=10;
                        else
                            numBins_roiNonIntersecting = (max(roiNonIntersectingSub(:,4))-min(roiNonIntersectingSub(:,4)))/roiNonIntersectingBinWidth;
                        end;

                        [v_roiNonIntersecting, r_roiNonIntersecting] = hist(roiNonIntersectingSub(:,4),numBins_roiNonIntersecting);

                        temp_r_roiNonIntersecting=r_roiNonIntersecting;
                        temp_v_roiNonIntersecting=v_roiNonIntersecting;
                        clear r_roiNonIntersecting;
                        clear v_roiNonIntersecting;
                        r_roiNonIntersecting=[];
                        v_roiNonIntersecting=[];

                        for v=1:length(temp_r_roiNonIntersecting)
                            if (temp_r_roiNonIntersecting(v)>0)
                                r_roiNonIntersecting=horzcat(r_roiNonIntersecting, temp_r_roiNonIntersecting(v));
                                v_roiNonIntersecting=horzcat(v_roiNonIntersecting, temp_v_roiNonIntersecting(v));
                            end;     
                        end;

                    else %i.e. if the OAR is contained entirely within the PTV
                        v_roiNonIntersecting=[];
                        r_roiNonIntersecting=[];
                        roiNonIntersectingBinWidth=0;      
                    end;

                % %% CALCULATE OVH PARAMETERS AND PLOT OVH
                    %roiVolume = sum(sum(sum(roiBlock)));
                    r_roi = horzcat(r_roiIntersecting, r_roiNonIntersecting);
                    v_roiUnscaled = horzcat(v_roiIntersecting, v_roiNonIntersecting);
                    v_roi = (v_roiUnscaled*rowSpacing*columnSpacing*sliceSpacing)/1000;
                    vp_roi = (v_roi./(roiVolume))*100;
                    cum_v_roi = cumsum(vp_roi);
                    figure(ptvIndex);
                    p=plot(r_roi, cum_v_roi);
                    set(p,'Color',color(i,:),'LineWidth',2);
                    hold on;

                    % Format OVH arrays as strings for entry into the database
                    roiOVH_distance = mat2str(round(r_roi*10000)/10000);
                    roiOVH_distance = strrep(roiOVH_distance, ' ', ',');
                    roiOVH_v = mat2str(round(cum_v_roi*10000)/10000);
                    roiOVH_v = strrep(roiOVH_v, ' ', ',');

                    % Calculate OVH Set Points - r5, r10, r15 .... r100
                    ovhSetPoints = cell(20,1);
                    ovhComplete='y';
                    if ~isempty(cum_v_roi)
                        for g=1:20
                            if cum_v_roi(1)<(g*5)
                                ovhSetPoints{g}=findX(r_roi,cum_v_roi,(g*5));
                                if isempty(ovhSetPoints{g})
                                    ovhSetPoints{g}='NULL';
                                end;
                            else
                                ovhSetPoints{g}='NULL';
                                ovhComplete='n';
                            end;
                        end;
                    else 
                        for g=1:20
                            ovhSetPoints{g}='NULL';
                        end
                    end;


                    %% DISTANCE STATISTICS

                    roiDistances = vertcat(roiIntersectingSub(:,4),roiNonIntersectingSub(:,4));

                    roiMean = mean(roiDistances);
                    roiStandardDeviation = std(roiDistances);
                    roiMode = mode(roiDistances);
                    roiMedian=median(roiDistances);
                    roiSkewness=skewness(roiDistances);
                    roiMin=min(roiDistances);
                    roiMax=max(roiDistances);

                    mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET ',ptvName,' = "',ptvs{ptvIndex},'" WHERE fk_patient_id="',num2str(patient_id),'"'));
                    mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET Volume="',num2str(ptvVolume),'" WHERE stdROIName = "',ptvs{ptvIndex},'" AND fk_patient_id="',num2str(patient_id),'"'));
                    mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET DistanceMean_',ptvName,'="',num2str(roiMean),'", DistanceStdDev_',ptvName,'="',num2str(roiStandardDeviation),'", DistanceMode_',ptvName,'="',num2str(roiMode),'", DistanceSkewness_',ptvName,'="',num2str(roiSkewness),'", DistanceMedian_',ptvName,'="',num2str(roiMedian),'", DistanceMin_',ptvName,'="',num2str(roiMin),'", DistanceMax_',ptvName,'="',num2str(roiMax),'" WHERE id="',num2str(structure_set_roi_sequence_ids(i)),'"'));
                    mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET OverlapVolume_',ptvName,'="',num2str(roiIntersectingVolume),'", PercentageOverlap_ROI_Fraction_',ptvName,'="',num2str(roiPercentageOverlap_OAR_Fraction),'", PercentageOverlap_Total_Fraction_',ptvName,'="',num2str(roiPercentageOverlap_Total_Fraction),'" WHERE id="',num2str(structure_set_roi_sequence_ids(i)),'"'));
                    mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET ovhDistance_',ptvName,'="',roiOVH_distance,'", ovhVolume_',ptvName,'="',roiOVH_v,'" WHERE id="',num2str(structure_set_roi_sequence_ids(i)),'"'));
                    %disp(horzcat('UPDATE structure_set_roi_sequence_copy SET ovhDistance_',ptvName,'="',roiOVH_distance,'", ovhVolume_',ptvName,'="',roiOVH_v,'" WHERE id="',num2str(structure_set_roi_sequence_ids(i)),'"'));
                    mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET ovhComplete_',ptvName,' = "',ovhComplete,'" WHERE id="',num2str(structure_set_roi_sequence_ids(i)),'"'));
                    mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET ',ptvName,'_ovh5=',num2str(ovhSetPoints{1}),', ',ptvName,'_ovh10=',num2str(ovhSetPoints{2}),', ',ptvName,'_ovh15=',num2str(ovhSetPoints{3}),', ',ptvName,'_ovh20=',num2str(ovhSetPoints{4}),', ',ptvName,'_ovh25=',num2str(ovhSetPoints{5}),', ',ptvName,'_ovh30=',num2str(ovhSetPoints{6}),', ',ptvName,'_ovh35=',num2str(ovhSetPoints{7}),', ',ptvName,'_ovh40=',num2str(ovhSetPoints{8}),', ',ptvName,'_ovh45=',num2str(ovhSetPoints{9}),', ',ptvName,'_ovh50=',num2str(ovhSetPoints{10}),', ',ptvName,'_ovh55=',num2str(ovhSetPoints{11}),', ',ptvName,'_ovh60=',num2str(ovhSetPoints{12}),', ',ptvName,'_ovh65=',num2str(ovhSetPoints{13}),', ',ptvName,'_ovh70=',num2str(ovhSetPoints{14}),', ',ptvName,'_ovh75=',num2str(ovhSetPoints{15}),', ',ptvName,'_ovh80=',num2str(ovhSetPoints{16}),', ',ptvName,'_ovh85=',num2str(ovhSetPoints{17}),', ',ptvName,'_ovh90=',num2str(ovhSetPoints{18}),', ',ptvName,'_ovh95=',num2str(ovhSetPoints{19}),', ',ptvName,'_ovh100=',num2str(ovhSetPoints{20}),' WHERE id="',num2str(structure_set_roi_sequence_ids(i)),'"'));
                end;
                counter=counter+1;
        else
            %mysql(horzcat('UPDATE structure_set_roi_sequence_copy SET Volume="',num2str(ptvVolume),'" WHERE id="',num2str(structure_set_roi_sequence_ids(i)),'"'));
        end;

    end


    figure(1)
    title('Overlap Volume Histogram for PTV1');
    xlabel('Distance in mm');
    ylabel('Percentage Volume of ROI');
    legend(legendList,'Location','BestOutside');
    saveas(figure(1),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/OVH/patient',num2str(patient_id),'ptv1.fig'));
    saveas(figure(1),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/Results/hnAnalysis72/patient',num2str(patient_id),'ptv1.png'));

    if (length(ptvs)>1)
        figure(2)
        title('Overlap Volume Histogram for PTV2');
        xlabel('Distance in mm');
        ylabel('Percentage Volume of ROI');
        legend(legendList,'Location','BestOutside');
        saveas(figure(2),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/OVH/patient',num2str(patient_id),'ptv2.fig'));
        saveas(figure(2),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/OVH/patient',num2str(patient_id),'ptv2.png'));
    end;

    if (length(ptvs)==3)
        figure(3)
        title('Overlap Volume Histogram for PTV3');
        xlabel('Distance in mm');
        ylabel('Percentage Volume of ROI');
        legend(legendList,'Location','BestOutside');
        saveas(figure(3),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/OVH/patient',num2str(patient_id),'ptv3.fig'));
        saveas(figure(3),horzcat('/Users/ruchi/Documents/IPI/RadiationOncology/quals/OVH/patient',num2str(patient_id),'ptv3.png'));
    end;
    close all;
end;

mysql('close');

toc;
