function S = stat_hn(dvhindex)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dvhindex = [0.99999 0.99 0.98 0.97 0.96 0.95 0.94 0.93 0.92 0.91 0.90...
                    0.89 0.88 0.87 0.86 0.85 0.84 0.83 0.82 0.81 0.80...
                    0.79 0.78 0.77 0.76 0.75 0.74 0.73 0.72 0.71 0.70...
                    0.69 0.68 0.67 0.66 0.65 0.64 0.63 0.62 0.61 0.60...
                    0.59 0.58 0.57 0.56 0.55 0.54 0.53 0.52 0.51 0.50...
                    0.49 0.48 0.47 0.46 0.45 0.44 0.43 0.42 0.41 0.40...
                    0.39 0.38 0.37 0.36 0.35 0.34 0.33 0.32 0.31 0.30...
                    0.29 0.28 0.27 0.26 0.25 0.24 0.23 0.22 0.21 0.20...
                    0.19 0.18 0.17 0.16 0.15 0.14 0.13 0.12 0.11 0.10...
                    0.09 0.08 0.07 0.06 0.05 0.04 0.03 0.02 0.01 0.001 0.0001 0.00001];

                
datadose=xlsread('\\rbrofs1\PHI\Shared\UCLARadoncRegistry\H&N\DVHTechData_H&N.xls','Data_Dose'); %All Patients
[rowdose,coldose] = size(datadose); %rowdose is number of entries in datadose sheet

datatech=xlsread('\\rbrofs1\PHI\Shared\UCLARadoncRegistry\H&N\DVHTechData_H&N.xls','Data_Tech'); %All Patients
[rowtech,coltech] = size(datatech);%rowtech is number of patients listed in datatech sheet

S(1) = rowtech;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c1 = datadose(:,3)== 33;   %Lt Parotid %command gives a vector of 1s and 0s
c2 = datadose(:,3)== 34;   %Rt Parotid %flags all the entries which correspond to a certain structure
c3 = datadose(:,3)== 35;   %Mandible % for this command, all 1s correspond to entries related for the mandible
c4 = datadose(:,3)== 36;   %Lt Cochlea
c5 = datadose(:,3)== 37;   %Rt Cochlea
c6 = datadose(:,3)== 7;    %Cord
c7 = datadose(:,3)== 6;    %Chiasm
c8 = datadose(:,3)== 30;   %PTV1
c9 = datadose(:,3)== 31;   %PTV2
c10 = datadose(:,3)== 32;  %PTV3

idx1=find(c1);%Finds the indices of non-zero entries, i.e. finds the indices for all enties in datadose which correspond to a particular structure
idx2=find(c2);
idx3=find(c3);
idx4=find(c4);
idx5=find(c5);
idx6=find(c6);
idx7=find(c7);
idx8=find(c8);
idx9=find(c9);
idx10=find(c10);

%Intersection between the patient index number for the tech sheet%%%%%%%%%%
%and the dose sheet%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~, ~, ib] = intersect( datadose(:,1), datatech(:,1), 'rows');%ib gives the 
% indices of all ids that are common between datadose and datatech. 
%if datatech has multiple entries of the same value, it selects the bottom most
[rowsize,~] = size(ib);
fprintf(1,'\nTotal # OF PATIENT (DATADOSE and DATATECH INTERSECT): %d',rowsize);
S(2) = rowsize;
fprintf(1,'\nDuplicate Patient Index Values');
b = unique(datatech(:,2));%returns all the MRNs in datatech but without repetitions
idxvals=setxor(datatech(:,2),b);%returns all the duplicate entries (the values themselves) %i.e. return only entires which are not common

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_ltpar = mean(datadose(idx1(:),4));%idx1 gives the row indices of all the entries in datadose for the left parotid 
std_meanltpar = std(datadose(idx1(:),4));%datadose(idx1(:),4) selects those rows of column 4 in datadose whose indices correspond to idx1 
max_ltpar = mean(datadose(idx1(:),5));%basically, the mean dose of all entries for the left parotid
std_maxltpar = std(datadose(idx1(:),5));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_rtpar = mean(datadose(idx2(:),4));
std_meanrtpar = std(datadose(idx2(:),4));
max_rtpar = mean(datadose(idx2(:),5));
std_maxrtpar = std(datadose(idx2(:),5));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_mand = mean(datadose(idx3(:),4));
std_meanmand = std(datadose(idx3(:),4));
max_mand = mean(datadose(idx3(:),5));
std_maxmand = std(datadose(idx3(:),5));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_ltcoch = mean(datadose(idx4(:),4));
std_meanltcoch = std(datadose(idx4(:),4));
max_ltcoch = mean(datadose(idx4(:),5));
std_meanltcoch = std(datadose(idx4(:),5));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_rtcoch = mean(datadose(idx5(:),4));
std_meanrtcoch = std(datadose(idx5(:),4));
max_rtcoch = mean(datadose(idx5(:),5));
std_maxrtcoch = std(datadose(idx5(:),5));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_cord = mean(datadose(idx6(:),4));
std_meancord = std(datadose(idx6(:),4));
max_cord = mean(datadose(idx6(:),5));
std_maxcord = std(datadose(idx6(:),5));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_chiasm = mean(datadose(idx7(:),4));
std_meanchiasm = std(datadose(idx7(:),4));
max_chiasm = mean(datadose(idx7(:),5));
std_maxchiasm = std(datadose(idx7(:),5));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_ptv1 = mean(datadose(idx8(:),4));
std_meanptv1 = std(datadose(idx8(:),4));
max_ptv1 = mean(datadose(idx8(:),5));
std_maxptv1 = std(datadose(idx8(:),5));
min_ptv1 = mean(datadose(idx8(:),6));
std_minptv1 = std(datadose(idx8(:),6));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_ptv2 = mean(datadose(idx9(:),4));
std_meanptv2 = std(datadose(idx9(:),4));
max_ptv2 = mean(datadose(idx9(:),5));
std_maxptv2 = std(datadose(idx9(:),5));
min_ptv2 = mean(datadose(idx9(:),6));
std_minptv2 = std(datadose(idx9(:),6));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_ptv3 = mean(datadose(idx10(:),4));
std_meanptv3 = std(datadose(idx10(:),4));
max_ptv3 = mean(datadose(idx10(:),5));
std_maxptv3 = std(datadose(idx10(:),5));
min_ptv3 = mean(datadose(idx10(:),6));
std_minptv3 = std(datadose(idx10(:),6));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plots patient id versus dose to 95% of the PTV

%plots patient id versus dose to 95% of PTV1
[~, ia, ib] = intersect( datadose(idx8(:),1), datatech(:,1)); %both columns are 'id' columns
[rowsize,~] = size(ib);
fprintf(1,'\nINTERSECT PTV1 DOSE and TECH: %d',rowsize);
scatX = datadose(idx8(ia),1); scatY = datadose(idx8(ia),14).\datadose(idx8(ia),8); %PTV1 normD95 Dose for all patients, ie dose to 95% of the volume
scatter(scatX,scatY*100,'filled'); hold on;
xlabel('Patient Index #'); ylabel('PTV1 D95 DOSE (%)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PTV1_normD95.pdf'); hold off;
scatX = datadose(idx8(ia),1); scatY = datadose(idx8(ia),14); %PTV1 D95 Dose for all patients
scatter(scatX,scatY,'filled'); hold on;
xlabel('Patient Index #'); ylabel('PTV1 D95 DOSE (%)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PTV1_D95.pdf'); hold off;
scatX = datatech(ib,8); scatY = datadose(idx8(ia),14); %PTV1 D95 Dose for all patients
scatter(scatX,scatY,6); hold on;
set(gca,'XTick',[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]);
xlabel('Treatment Site Index #'); ylabel('PTV D95 DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PTV1_TxSiteD95.pdf'); hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%plots patient id versus dose to 95% of PTV2
[~, ia, ib] = intersect( datadose(idx9(:),1), datatech(:,1));
[rowsize,~] = size(ib);
fprintf(1,'\nINTERSECT PTV2 DOSE and TECH: %d',rowsize);
scatX = datadose(idx9(ia),1); scatY = datadose(idx9(ia),14).\datadose(idx9(ia),8); %PTV2 normD95 Dose for all patients
scatter(scatX,scatY*100,'filled'); hold on;
ylim([50 120]); xlabel('Patient Index #'); ylabel('PTV2 D95 DOSE (%)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PTV2_normD95.pdf'); hold off;
scatY = datadose(idx9(ia),14); %PTV2 D95 Dose for all patients
scatter(scatX,scatY,'filled'); hold on;
xlabel('Patient Index #'); ylabel('PTV2 D95 DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PTV2_D95.pdf'); hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

yinterp = dvhindex;%cumulative DVH (volume axis)

scatX = datadose(idx3(:),1); %idx3 gives indices of entries in datadose for mandible; column1 is id, and col5 is max. dose
scatY = datadose(idx3(:),5); 
scatter(scatX,scatY,'filled'); hold on; % plots ID versus maximum dose to mandible for all maandible related entries
xlabel('Patient Index #'); ylabel('MAX MANDIBLE DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\MANDIBLE_MAXDOSE.pdf'); hold off;

[~, ia, ib] = intersect( datadose(idx3(:),1), datatech(:,1));
[rowsize,~] = size(ia);
V70GY_idx = find(datadose(idx3(ia),109) > 7000); %109 represents D0.1%
%V70GY_idx gives indices of rows in datadose where dose to 0.1% of the mandible exceeds
%7000cGY (or 70GY)
[V70GYsize,~] = size(V70GY_idx); %gives number of entries (num of patients) where D0.1% exceeds 70GY
fprintf(1,'\n\n# of patients with Max Mandible Dose > 7000cGy: %d',V70GYsize);

for i=1:V70GYsize %print patient index and the dose to 0.1% of mandible
    fprintf(1,'\nPATIENT INDEX: %d',datadose(idx3(V70GY_idx(i)),1)); %datadose(idx3(V70GY_idx(i)),1) gives the id of all entries in datadose 
    %for mandible, where max dose to 0.01% exceeds 70GY
    fprintf(1,'\t%6.1f cGy',datadose(idx3(V70GY_idx(i)),109));  
    %prints id number and corresponding max dose of all entries from
    %datadose where D0.01% exceeds 70Gy 
end
V70GY_MANDIBLE = zeros(V70GYsize,1);%for every entry (ir for every patient) where D0.01% exceeds 70 Gy, V70GY_MANDIBLE gives 
%the % volume which receives greater than or equal to 70 Gy dose
for j = 1:V70GYsize
    xinterp = datadose(idx3(V70GY_idx(j)),9:111); % (dose axis of DVH) - 103 points
    [bb,ii,~] = unique(xinterp); %ii is index of xinterp, not of bb
    V70GY_MANDIBLE(j) = interp1(bb,yinterp(ii),7000);% percentage volume of mandible which receives > 70GY
end
scatX = datadose(idx3(V70GY_idx),1); scatY = V70GY_MANDIBLE*100;
scatter(scatX,scatY,'ro','filled'); hold on;
xlabel('Patient Index #'); ylabel('% MANDIBLE VOLUME > 70GY')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\MANDIBLE_V70GY.pdf'); hold off; clear V70GY_MANDIBLE;

%%%%QC check on max dose
for j = 1:rowsize
    rx = datadose(idx3(ia(j)),8);
    x = datadose(idx3(ia(j)),9:108)./rx; 
    if max(x) > 1.1
        fprintf(1,'\nID#%d',datadose(idx3(ia(j)),1));
    end
end


y = dvhindex(1:100);
for j = 1:rowsize
    rx = datadose(idx3(ia(j)),8);
    x = datadose(idx3(ia(j)),9:108)./rx; 
    %fprintf(1,'\nID#%d RX:%d x: %6.3f',datadose(idx1(ia(j)),2),datadose(idx1(ia(j)),8),x(100));
    plot(x,y); hold on;
end
xlabel('FRACTIONAL RX DOSE'); ylabel('FRACTIONAL MANDIBLE VOLUME')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\MANDIBLE_PLOT.pdf'); hold off;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scatX = datadose(idx7(:),1); %patient index number
scatY = datadose(idx7(:),109); %Max Chiasm Dose for all patients
scatter(scatX,scatY,'filled'); hold on;
xlabel('Patient Index #'); ylabel('Max CHIASM DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\OAR_ChiasmMax.pdf'); hold off;
Vexceed = datadose(idx7(:),109) > 5500; %Max dose > 5500 cGy %109 represents D0.1% --> gives 0s and 1s
Vexceed_idx=find(Vexceed); %finds indices of rows which exceed 55Gy
[row,col] = size(Vexceed_idx); % fow is the number of entries for which D0.01 exceeds 55Gy
fprintf(1,'\n\n# of patients with MAX CHIASM DOSE > 55Gy: %d',row);
for i=1:row % prints the id number and the D0.01% when for those entries which exceed 55Gy
    fprintf(1,'\nPATIENT INDEX: %d',Vexceed_idx(i));
    fprintf(1,'\t%6.1f cGy',datadose(idx7(Vexceed_idx(i)),109));  
end
X = datadose(idx7(:),109); obj = gmdistribution.fit(X,2); %two cluster fit to D0.1% chiasm dose
for i=1:2
    fprintf(1,'\nCLUSTER #%d\tMean: %6.1f\tCovariance: %6.1f',i,obj.mu(i),obj.Sigma(i));  
end
idx = cluster(obj,X);  %compute the index clusters
cluster1 = X(idx == 1,:); cluster2 = X(idx == 2,:);
plot(datadose(idx7(idx==1),1),datadose(idx7(idx==1),109),'r.','MarkerSize',12); hold on
plot(datadose(idx7(idx==2),1),datadose(idx7(idx==2),109),'b.','MarkerSize',12)
xlabel('Patient Index #'); ylabel('D0.1% CHIASM DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\OAR_ChiasmMax_gmCluster.pdf'); hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scatX = datadose(idx4(:),1); %patient index number
scatY = datadose(idx4(:),4); %Mean Lt Cochlea Dose for all patients
scatter(scatX,scatY,'filled'); hold on;
xlabel('Patient Index #'); ylabel('MEAN LT COCHLEA DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\OAR_LTCochleaMean.pdf'); hold off;
Vexceed = datadose(idx4(:),4) > 4500; %Mean dose > 4500 cGy
Vexceed_idx=find(Vexceed);
[row,col] = size(Vexceed_idx);
fprintf(1,'\n\n# of patients with MEAN LT COCHLEA DOSE > 45Gy: %d',row);
for i=1:row
    fprintf(1,'\nPATIENT INDEX: %d',Vexceed_idx(i));
    fprintf(1,'\t%6.1f cGy',datadose(idx4(Vexceed_idx(i)),4));  
end
X = datadose(idx4(:),4); obj = gmdistribution.fit(X,2); %two cluster fit to mean LT cochlea dose
for i=1:2
    fprintf(1,'\nCLUSTER #%d\tMean: %6.1f\tCovariance: %6.1f',i,obj.mu(i),obj.Sigma(i));  
end
idx = cluster(obj,X);  %compute the index clusters
cluster1 = X(idx == 1,:); cluster2 = X(idx == 2,:);
plot(datadose(idx4(idx==1),1),datadose(idx4(idx==1),4),'r.','MarkerSize',12); hold on
plot(datadose(idx4(idx==2),1),datadose(idx4(idx==2),4),'b.','MarkerSize',12)
xlabel('Patient Index #'); ylabel('MEAN LT COCHLEA DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\OAR_LTCochleaMean_gmCluster.pdf'); hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scatX = datadose(idx5(:),1); %patient index number
scatY = datadose(idx5(:),4); %Mean Rt Cochlea Dose for all patients
scatter(scatX,scatY,'filled'); hold on;
xlabel('Patient Index #'); ylabel('MEAN RT COCHLEA DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\OAR_RTCochleaMean.pdf'); hold off;
Vexceed = datadose(idx5(:),4) > 4500; %Mean dose > 4500 cGy
Vexceed_idx=find(Vexceed);
[row,col] = size(Vexceed_idx);
fprintf(1,'\n\n# of patients with MEAN RT COCHLEA DOSE > 45Gy: %d',row);
for i=1:row
    fprintf(1,'\nPATIENT INDEX: %d',Vexceed_idx(i));
    fprintf(1,'\t%6.1f cGy',datadose(idx5(Vexceed_idx(i)),4));  
end
X = datadose(idx5(:),4); obj = gmdistribution.fit(X,2); %two cluster fit to mean RT cochlea dose
for i=1:2
    fprintf(1,'\nCLUSTER #%d\tMean: %6.1f\tCovariance: %6.1f',i,obj.mu(i),obj.Sigma(i));  
end
idx = cluster(obj,X);  %compute the index clusters
cluster1 = X(idx == 1,:); cluster2 = X(idx == 2,:);
plot(datadose(idx5(idx==1),1),datadose(idx5(idx==1),4),'r.','MarkerSize',12); hold on
plot(datadose(idx5(idx==2),1),datadose(idx5(idx==2),4),'b.','MarkerSize',12)
xlabel('Patient Index #'); ylabel('MEAN RT COCHLEA DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\OAR_RTCochleaMean_gmCluster.pdf'); hold off;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scatX = datadose(idx1(:),1); %patient index number
scatY = datadose(idx1(:),4); %Mean Lt Parotid Dose for all patients
scatter(scatX,scatY,'filled'); hold on;
xlabel('Patient Index #'); ylabel('Mean LT PARIOTID DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_LT_MEAN.pdf'); hold off;
fprintf(1,'\nLT PAROTID MEAN');
X = datadose(idx1(:),4); obj = gmdistribution.fit(X,2); %two cluster fit to mean LT parotid dose
for i=1:2
    fprintf(1,'\nCLUSTER #%d\tMean: %6.1f\tCovariance: %6.1f',i,obj.mu(i),obj.Sigma(i));  
end
idx = cluster(obj,X);  %compute the index clusters
%cluster1 = X(idx == 1,:); cluster2 = X(idx == 2,:);
plot(datadose(idx1(idx==1),1),datadose(idx1(idx==1),4),'r.','MarkerSize',12); hold on
plot(datadose(idx1(idx==2),1),datadose(idx1(idx==2),4),'b.','MarkerSize',12)
xlabel('Patient Index #'); ylabel('MEAN LT PAROTID DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_LT_MEAN_gmCluster.pdf'); hold off;
[~, ia, ib] = intersect( datadose(idx1(:),1), datatech(:,1)); [rowsize,~] = size(ib);
fprintf(1,'\n# of Matches for LT PAROTID (IDX1 vs. TECH): %d',rowsize);
Vexceed = datadose(idx1(:),4) > 2500; %Mean dose > 2500 cGy
Vexceed_idx=find(Vexceed);
[row,~] = size(Vexceed_idx);
fprintf(1,'\n\n# of patients with Mean LT PAROTID DOSE > 25Gy: %d',row);
for i=1:row
    fprintf(1,'\nPATIENT INDEX: %d',Vexceed_idx(i));
    fprintf(1,'\t%6.1f cGy',datadose(idx1(Vexceed_idx(i)),4));  
end
V25GY_LTPAROT = zeros(rowsize,1);
for j = 1:rowsize
    xinterp = datadose(idx1(ia(j)),9:111);
    [bb,ii,~] = unique(xinterp); 
    if datadose(idx1(ia(j)),5) < 2500
        V25GY_LTPAROT(j) = 0.0;
    else
        V25GY_LTPAROT(j) = interp1(bb,yinterp(ii),2500);
    end
end
scatX = datadose(idx1(ia),1); %patient index number
scatY = V25GY_LTPAROT*100;
scatter(scatX,scatY,'ro','filled'); hold on;
xlabel('Patient Index #'); ylabel('% LT PAROTID VOLUME > 25GY')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_LT_V25GY.pdf'); hold off;
fprintf(1,'\nLT PAROTID V25GY');

%options = statset('TolFun',1e-8,'maxiter',1000);
%X = V25GY_LTPAROT; obj = gmdistribution.fit(X,2,'Options', options); %two cluster fit to mean LT parotid dose
%for i=1:2
%    fprintf(1,'\nCLUSTER #%d\tMean: %6.1f\tCovariance: %6.1f',i,obj.mu(i),obj.Sigma(i));  
%end
%idx = cluster(obj,X);  %compute the index clusters
%cluster1 = X(idx == 1,:); cluster2 = X(idx == 2,:);
%plot(datadose(idx1(ia(idx==1)),1),V25GY_LTPAROT(idx==1),'r.','MarkerSize',12); hold on
%plot(datadose(idx1(ia(idx==2)),1),V25GY_LTPAROT(idx==2),'b.','MarkerSize',12)
%xlabel('Patient Index #'); ylabel('LT PAROTID VOLUME > 25GY')
%saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_LT_V25GY_gmCluster.pdf'); hold off;
%clear V25GY_LTPAROT;

y = dvhindex(1:100);
for j = 1:rowsize
    rx = datadose(idx1(ia(j)),8);
    x = datadose(idx1(ia(j)),9:108)./rx; 
        %fprintf(1,'\nID#%d RX:%d x: %6.3f',datadose(idx1(ia(j)),2),datadose(idx1(ia(j)),8),x(100));
    plot(x,y); hold on;
end
xlabel('FRACTIONAL RX DOSE'); ylabel('FRACTIONAL LT PAROTID VOLUME')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_LT_PLOT.pdf'); hold off;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
scatX = datadose(idx2(:),1); %patient index number
scatY = datadose(idx2(:),4); %Mean RT Parotid Dose for all patients
scatter(scatX,scatY,'filled'); hold on;
xlabel('Patient Index #'); ylabel('MEAN RT PAROTID DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_RT_MEAN.pdf'); hold off;
fprintf(1,'\nRT PAROTID MEAN');
X = datadose(idx2(:),4); obj = gmdistribution.fit(X,2); %two cluster fit to mean RT parotid dose
for i=1:2
    fprintf(1,'\nCLUSTER #%d\tMean: %6.1f\tCovariance: %6.1f',i,obj.mu(i),obj.Sigma(i));  
end
idx = cluster(obj,X);  %compute the index clusters
cluster1 = X(idx == 1,:); cluster2 = X(idx == 2,:);
plot(datadose(idx2(idx==1),1),datadose(idx2(idx==1),4),'r.','MarkerSize',12); hold on
plot(datadose(idx2(idx==2),1),datadose(idx2(idx==2),4),'b.','MarkerSize',12)
xlabel('Patient Index #'); ylabel('MEAN RT PAROTID DOSE (cGy)')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_RT_MEAN_gmCluster.pdf'); hold off;
[~, ia, ib] = intersect( datadose(idx2(:),1), datatech(:,1)); [rowsize,~] = size(ib);
fprintf(1,'\n# of Matches for RT PAROTID (IDX2 vs. TECH): %d',rowsize);
Vexceed = datadose(idx2(ia),4) > 2500; %Mean dose > 2500 cGy
Vexceed_idx=find(Vexceed);
[row,~] = size(Vexceed_idx);
fprintf(1,'\n\n# of patients with Mean RT PAROTID DOSE > 25Gy: %d',row);
for i=1:row
    fprintf(1,'\nPATIENT INDEX: %d',Vexceed_idx(i));
    fprintf(1,'\t%6.1f cGy',datadose(idx2(Vexceed_idx(i)),4));  
end
V25GY_RTPAROT = zeros(rowsize,1);
for j = 1:rowsize
    [bb,ii,~] = unique(xinterp); 
    xinterp = datadose(idx2(ia(j)),9:111);
    if datadose(idx2(ia(j)),5) < 2500
        V25GY_RTPAROT(j) = 0.0;
    else
        V25GY_RTPAROT(j) = interp1(bb,yinterp(ii),2500);
    end
end
scatX = datadose(idx2(ia),1); %patient index number
scatY = V25GY_RTPAROT*100;
scatter(scatX,scatY,'ro','filled'); hold on;
xlabel('Patient Index #'); ylabel('% RT PAROTID VOLUME > 25GY')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_RT_V25GY.pdf'); hold off;
fprintf(1,'\nRT PAROTID V25GY');
options = statset('TolFun',1e-8,'maxiter',200);
X = V25GY_RTPAROT; obj = gmdistribution.fit(X,2,'Options', options); %two cluster fit to V25GY RT parotid dose
for i=1:2
    fprintf(1,'\nCLUSTER #%d\tMean: %6.3f\tCovariance: %6.3f',i,obj.mu(i),obj.Sigma(i));  
end
idx = cluster(obj,X);  %compute the index clusters
%cluster1 = X(idx == 1,:); cluster2 = X(idx == 2,:);
plot(datadose(idx2(ia(idx==1)),1),V25GY_RTPAROT(idx==1),'r.','MarkerSize',12); hold on
plot(datadose(idx2(ia(idx==2)),1),V25GY_RTPAROT(idx==2),'b.','MarkerSize',12)
xlabel('Patient Index #'); ylabel('RT PAROTID VOLUME > 25GY')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_RT_V25GY_gmCluster.pdf'); hold off;
clear V25GY_RTPAROT;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~, ia1, ib1] = intersect( datadose(idx1(:),1), datatech(:,1));
[size1,~] = size(ib1);
fprintf(1,'\n\nINTERSECT LT PAROTID DOSE and TECH: %d',size1);
[~, ia2, ib2] = intersect( datadose(idx2(:),1), datatech(:,1));
[size2,~] = size(ib2);
fprintf(1,'\nINTERSECT RT PAROTID DOSE and TECH: %d',size2);
minsize = min(size1,size2);
if minsize == size1
    scatX = datadose(idx1(ia1),1); %patient index number
    scatY = datadose(idx2(ia1),4)./datadose(idx1(ia1),4);
    scatY1 = datadose(idx1(ia1),4);
    scatY2 = datadose(idx2(ia1),4);
else
    scatX = datadose(idx1(ia2),1); %patient index number
    scatY = datadose(idx2(ia2),4)./datadose(idx1(ia2),4);
    scatY1 = datadose(idx1(ia2),4);
    scatY2 = datadose(idx2(ia2),4);
end
scatter(scatX,scatY,'filled'); hold on;
xlabel('Patient Index #'); ylabel('RATIO RT VS. LT MEAN PARIOTID DOSE')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_RATIO_MEAN.pdf'); hold off;
scatX = scatY; %plot ratio versus mean dose
scatY = scatY2;
scatter(scatX,scatY,'filled'); hold on;
xlabel('RATIO RT VS. LT MEAN PARIOTID DOSE'); ylabel('MEAN RT PAROTID DOSE')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_RATIO_RTMEAN.pdf'); hold off;
scatY = scatY1;
scatter(scatX,scatY,'filled'); hold on;
xlabel('RATIO RT VS. LT MEAN PARIOTID DOSE'); ylabel('MEAN LT PAROTID DOSE')
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PAROTID_RATIO_LTMEAN.pdf'); hold off;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rho = corr(scatY2,scatX,'type','Kendall');
fprintf(1,'\nK-T Correlation RT MEAN PAROTID DOSE vs. RATIO: %f',rho);
rho = corr(scatY1,scatX,'type','Kendall');
fprintf(1,'\nK-T Correlation LT MEAN PAROTID DOSE vs. RATIO: %f',rho);
rho = corr(datadose(idx8(ia2),7),datadose(idx2(ia2),4),'type','Kendall');
fprintf(1,'\nK-T Correlation PTV1 VOLUME vs. RT PAROTID MEAN: %f',rho);
rho = corr(datadose(idx9(ia2),7),datadose(idx2(ia2),4),'type','Kendall');
fprintf(1,'\nK-T Correlation PTV2 VOLUME vs. RT PAROTID MEAN: %f',rho);
[~, ia1, ~] = intersect( datadose(idx10(:),1), datatech(:,1));
[~, ia2, ~] = intersect( datadose(idx2(:),1), datatech(:,1));
[size1,~] = size(ia1); [size2,~] = size(ia2);
if size1 < size2
    rho = corr(datadose(idx10(ia1),7),datadose(idx2(ia1),4),'type','Kendall');
else
    rho = corr(datadose(idx10(ia2),7),datadose(idx2(ia2),4),'type','Kendall');
end
fprintf(1,'\nK-T Correlation PTV3 VOLUME vs. RT PAROTID MEAN: %f',rho);



%fprintf(1,'\n###########################################################');
%[c1, ia1, ib1] = intersect( datadose(idx8(:),1) , datadose(idx7(:),1) );
%mean1a = mean(datadose(idx8(ia1),4));
%[rowsize,colsize] = size(ia1);
%fprintf(1,'\nTotal number of PTV1 match: %d',rowsize);
%fprintf(1,'\nMEAN PTV1: %6.1f',mean1a);
%mean1b = mean(datadose(idx7(ib1),5));
%[rowsize,colsize] = size(ib1);
%fprintf(1,'\nTotal number of Chiasm match: %d',rowsize);
%fprintf(1,'\nMax Chiasm: %6.1f',mean1b);
%rho = corr(datadose(idx8(ia1),4:7),datadose(idx7(ib1),4:7),'type','Kendall');
%display(rho);
%fprintf(1,'\n###########################################################');
%[c1, ia1, ib1] = intersect( datadose(idx8(:),1) , datadose(idx4(:),1) );
%mean1a = mean(datadose(idx8(ia1),4));
%[rowsize,colsize] = size(ia1);
%fprintf(1,'\nTotal number of PTV1 match: %d',rowsize);
%fprintf(1,'\nMEAN PTV1: %6.1f',mean1a);
%mean1b = mean(datadose(idx4(ib1),5));
%[rowsize,colsize] = size(ib1);
%fprintf(1,'\nTotal number of Lt Cochlea match: %d',rowsize);
%fprintf(1,'\nMax Lt Cochlea: %6.1f',mean1b);
%rho = corr(datadose(idx8(ia1),4:7),datadose(idx4(ib1),4:7),'type','Kendall');
%display(rho);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%k-means analysis on the subset%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Display the k-means index values for grouping the clusters%%%%%%%%%%%%%%%%
%4, 5, 6, 7 = Mean, Max, Min, volume
%1, 2, 3, 4 = Corrseponding cluster index
%8 - 17 = D100% - D10% (Absolute dose to X% of the structure volume)
%5 - 14 = Corresponding cluster index
fprintf(1,'\n###########################################################');
%datadose1 = datadose(idx8(:),4);
fprintf(1,'\nK-Means cluster analysis on the PTV DVH data using two clusters');
[idx,ctrs,sumd] = kmeans(datadose(idx8(:),4),2,'Distance','cityblock','Replicates',5);
%display(ctrs);
%Anova analysis of the clusters,anova1 assuming normal distribution
%Kruskal-Wallis is non-parametric version of anova1
[p,table,stats] = anova1(datadose(idx8(:),4),idx,'off');
[c,m,h,nms] = multcompare(stats,'display','off');
fprintf(1,'\nAnova1 anova analysis of the 2 clusters (PTV1 Mean Dose)');
fprintf(1,'\np value: %5.2e',p);
[p,table,stats] = kruskalwallis(datadose(idx8(:),4),idx,'off');
fprintf(1,'\nNon-parametric anova analysis of the 2 clusters (PTV1 Mean Dose)');
fprintf(1,'\np value: %5.2e',p);
[p,table,stats] = anova1(datadose(idx8(:),7),idx,'off');
[c,m,h,nms] = multcompare(stats,'display','off');
fprintf(1,'\nAnova1 anova analysis of the 2 clusters (PTV1 Volume)');
fprintf(1,'\np value: %5.2e',p);
[p,table,stats] = kruskalwallis(datadose(idx8(:),7),idx,'off');
fprintf(1,'\nNon-parametric anova analysis of the 2 clusters (PTV1 Volume)');
fprintf(1,'\np value: %5.2e',p);
[p,table,stats] = anova1(datadose(idx8(:),6),idx,'off');
[c,m,h,nms] = multcompare(stats,'display','off');
fprintf(1,'\nAnova1 anova analysis of the 2 clusters (PTV1 Min Dose)');
fprintf(1,'\np value: %5.2e',p);
[p,table,stats] = kruskalwallis(datadose(idx8(:),6),idx,'off');
fprintf(1,'\nNon-parametric anova analysis of the 2 clusters (PTV1 Min Dose)');
fprintf(1,'\np value: %5.2e',p);
[p,table,stats] = anova1(datadose(idx8(:),5),idx,'off');
[c,m,h,nms] = multcompare(stats,'display','off');
fprintf(1,'\nAnova1 anova analysis of the 2 clusters (PTV1 Max Dose)');
fprintf(1,'\np value: %5.2e',p);
[p,table,stats] = kruskalwallis(datadose(idx8(:),5),idx,'off');
fprintf(1,'\nNon-parametric anova analysis of the 2 clusters (PTV1 Max Dose)');
fprintf(1,'\np value: %5.2e',p);




fprintf(1,'\n###########################################################');
rho = corr(datadose(idx8(:),4),datadose(idx8(:),7),'type','Kendall');
fprintf(1,'\nK-T Correlation PTV1 Mean vs. Volume: %f',rho);
%intersect patient ID PTV1 dose values with the corresponding patient name in datatech
[c1, a1, b1] = intersect( datadose(idx8,1) , datatech(:,1) );
rho = corr(datadose(idx8(a1),4),datatech(b1,5),'type','Kendall'); %correlate PTV1 mean with Rx
fprintf(1,'\nK-T Correlation PTV1 Mean vs. Rx Dose: %f',rho);
%intersect patient ID Chiasm dose values with the corresponding patient name in datatech
[c1, a1, b1] = intersect( datadose(idx7,1) , datatech(:,1) );
rho = corr(datadose(idx7(a1),5),datatech(b1,8),'type','Kendall');
fprintf(1,'\nK-T Correlation Chiasm Max vs. TreatmentSite: %f',rho);
rho = corr(datadose(idx7(a1),5),datatech(b1,5),'type','Kendall');
fprintf(1,'\nK-T Correlation Chiasm Max vs. Rx Dose: %f',rho);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
plot(datadose(idx8,1),datadose(idx8,4),'ro','Markerfacecolor','r','MarkerSize',5)
hold on
plot(datadose(idx8,1),datadose(idx8,5),'bo','Markerfacecolor','b','MarkerSize',5)
hold on
plot(datadose(idx8,1),datadose(idx8,6),'go','Markerfacecolor','g','MarkerSize',5)
h = legend('Mean','Max','Min',3);
set(h,'Interpreter','none')
%plot(ctrs(:,1),ctrs(:,3),'kx','MarkerSize',12,'LineWidth',2)
%plot(ctrs(:,1),ctrs(:,3),'ko','MarkerSize',12,'LineWidth',2)
xlabel('Patient Index #'); ylabel('Dose to site of gross disease (cGy)');
saveas(gcf,'\\rbrofs1\phi\Shared\UCLARadoncRegistry\H&N\PTVDose.pdf')
hold off;
fprintf(1,'\n###########################################################');
fprintf(1,'\n###########################################################');




%fprintf(1,'\nMean # of weeks for arrest: %6.1f +/-
%%6.1f',mean(data(:,1)),std(data(:,1)));
%display(data(1:10,1:10));
%coxphfit(datadose(idx6(:),8:17),data(:,1),'censoring',~data(:,2));
%[b,logL,H,stats] = coxphfit(datadose(idx6(:),8:17),datadose(idx6(:),4));
%statname = {'BETA', 'SE', 'z', 'p'};
%fprintf(1,'\n\tD100\tD90\t\tD80\t\tD70\t\tD60\t\tD50\t\tD40\t\tD30\t\tD20\t\tD10',stats.beta(:),stats.se(:),stats.z(:),stats.p(:));
%fprintf(1,'\n\t%7.4f\t%7.4f\t%7.4f\t%7.4f\t%7.4f\t%7.4f\t%7.4f\t%7.4f\t%7.4f\t%7.4f',stats.beta(:),stats.se(:),stats.z(:),stats.p(:));
%fprintf(1,'\n%s',statname{:});
%stairs(H(:,1),exp(-H(:,2)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Create a subset array%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%psfdat1 = psfdat(:,4:10);
%fprintf(1,'\n\nK-Means cluster analysis on the subset array using two clusters');
%[idx,ctrs,sumd] = kmeans(psfdat1,3,'Distance','cityblock','Replicates',5);
%Display the k-means index values for grouping the clusters
%display(ctrs);
%[b,ix]=sort(psfdat(:,2));
%for i=1:rownum
%    fprintf(1,'\n%4d\t%d\t%6.1f\t%6.1f',psfdat(ix(i),2),idx(ix(i)),psfdat(ix(i),4),psfdat(ix(i),5));  
%end

clear datadose;




