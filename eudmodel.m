%Save this file in Matlab as eudmodel.m
%EUDMODEL(DVH), where DVH is a 2 column matrix corresponding to the cumulative, not
%differential, dose volume histogram. The 1st column corresponds to increasing absolute dose or 
%percentage dose values, and the 2nd column to the corresponding absolute or relative volume value.
%The matrix must have a minimum of two rows, and both columns must be of equal length.
%by Hiram A. Gay, MD
%Revised July 8 2007

function probability = eudmodel(dvh)
%user input section
clc; disp('Welcome to the Equivalent Uniform Dose (EUD)-Based Model Program'); disp(' ');
disp('Please note that: 1) the variable dvh should be a CUMULATIVE, not differential, DVH');
disp('                  2) the program assumes that all treatment fractions are equal');
disp(' '); disp(' ');
%end of user input section

%verifying that the cumulative DVH has at least 2 rows and columns
 [nb,N]=size(dvh);
if (nb < 2)
    disp('Error: Cumulative dvh must have at least 2 rows.'); return;
end
if (N < 2)
    disp('Error: Cumulative dvh must have at least 2 columns.'); return;
end
%verifying that the cumulative DVH has no negative numbers in the dose or volume columns
for i=1:nb
    if (dvh(i,1) < 0)
        message = sprintf('Error: Dose data error. dvh column 1, row %g is negative',i);
        disp(message); return;
    end
    if (dvh(i,2) < 0)
        message = sprintf('Error: Volume data error. dvh column 2, row %g is negative',i);
        disp(message); return;
    end
end
% Converting cumulative DVH to differential DVH, and checking for DVH errors
for i=2:nb
    dvh(i-1,1)=dvh(i-1,1)+(dvh(i,1)-dvh(i-1,1))/2;
    if (dvh(i,1)-dvh(i-1,1) <= 0)
        message = sprintf('Error: Dose data error. dvh column 1, row %g <= dvh column 1, row %g',i,i-1);
        disp(message); return;
    end
    dvh(i-1,2)=(dvh(i-1,2)-dvh(i,2));
    if (dvh(i-1,2) < 0)
        message = sprintf('Error: Volume bin < 0. Verify dvh column 2, rows %g and %g',i-1,i);
        disp(message); return;
    end
end
dvh(nb,:)=[];
[nb,N]=size(dvh);
nf=input('Enter the number of treatment fractions: '); disp(' '); disp(' ');
disp('Is the DVH dose data in: ');
disp('     1. percentage dose format');
disp('     2. absolute dose format');
dose_type=input('Enter 1 or 2: '); disp(' '); disp(' ');
%if DVH dose data is in percentage dose format
if (dose_type==1)
    normalized_fraction=input('Enter the dose in Gy (not cGy) corresponding to the 100% dose for ONE fraction: ');
    disp(' '); disp(' ');
   %converting percentage dose bins into absolute dose bins
    for i=1:nb
        dvh(i,1)=dvh(i,1)*nf*normalized_fraction/100;
    end
    message = sprintf('The maximum dose was %g Gy. Is this number reasonable?',dvh(nb,1));
    disp(message);
    disp('     1. yes');
    disp('     2. no');
    answer=input('Enter 1 or 2: '); disp(' '); disp(' ');
%if DVH dose data is in absolute dose format
    if (answer == 2 )
        disp('Error: if the maximum dose was too high: ');
        disp('         1) the dose data could be in ABSOLUTE, not percentage, dose format.');
        disp('         2) the 100% dose entered was for more than 1 fraction.'); return;
    elseif (answer == 1)
    else
        disp('Error: Invalid choice. Exiting program.'); return;
    end
elseif (dose_type==2)
    disp('Is the DVH absolute dose data in: ');
    disp('     1. Gy');
    disp('     2. cGy');
    answer2 = input('Enter 1 or 2: ');
%if DVH dose data is in cGy it is converted to Gy
    if (answer2 == 2)
        for i=1:nb
            dvh(i,1)=dvh(i,1)/100;
        end
    elseif (answer2 == 1)
    else
        disp('Error: Invalid choice. Exiting program.'); return;
    end
else
    disp('Error: Invalid choice. Exiting program.'); return;
end
%EUD mathematical model parameters input section
clc; disp('Does the DVH correspond to:');
disp('     1. tumor target');
disp('     2. normal tissue')
tissue_type=input('Enter 1 or 2: '); disp(' ');
if (tissue_type==1)
    clc
    disp('Structure (Source)                  End-point            a*'); disp(' ');
    disp('Breast (Brenner28)                    Local control        -7.2');
    disp('Melanoma (Brenner28)                  Local control       -10');
    disp('Squamous cc (Brenner28)               Local control       -13');
    disp('* = Niemierko'); disp(' ');
    a=input('Enter the value of parameter a: ' );
    gamma50=input('Enter the value of parameter gamma50 (recommend 2 if unknown): ' );
    tcd50=input('Enter the TCD50 (Gy): ');
    standard_fractionation=input('Enter the source data''s dose per fraction (Gy): ');
    ab=input('Enter the tumor alpha/beta ratio (Gy): ');
elseif (tissue_type==2)
    clc
    disp('Normal tissue EUD Parameters:'); disp(' ');
    disp('Structure (Source)    End-point                    a* / a**  g50**  TD50***  DPF****');
    disp(' ');
    disp('BRAIN (Emami)         Necrosis                        /  5    3      60      1.8 - 2');
    disp('Brainstem (Emami)     Necrosis                        /  7    3      65      1.8 - 2');
    disp('Optic chiasm (Emami)       Blindness                  / 25    3      65      1.8 - 2');
    disp('Colon (Emami)         Obstruction/perforation         /  6    4      55      1.8 - 2');
    disp('Ear(mid/ext) (Emami)  Acute serous otitis             / 31    3      40      1.8 - 2');
    disp('Ear(mid/ext) (Emami)  Chronic serous otitis           / 31    4      65      1.8 - 2');
    disp('Esophagus (Emami)     Perforation                     / 19    4      68      1.8 - 2');
    disp('Heart (Emami)         Pericarditis                    /  3    3      50      1.8 - 2');
    disp('Kidney (Emami)        Nephritis                       /  1    3      28      1.8 - 2');
    disp('Lens (Emami)          Cataract                        /  3    1      18      1.8 - 2');
    disp('Liver (Dawson29)        Liver failure               0.9 /');
    disp('Liver (Emami)         Liver failure                   /  3    3      40      1.8 - 2');
    disp('Liver (Lawrence30)      Liver failure               0.6 /');
    disp('Lung (Emami)          Pneumonitis                     /  1    2    24.5      1.8 - 2');
    disp('Lung (Kwa31)            Pneumonitis                 1.0 /');
    disp('Optic nerve (Emami)   Blindness                       / 25    3      65      1.8 - 2');
    disp('Parotids (Chao32)       Salivary function (<25%)    0.5 /');
    disp('Parotids (Eisbruch24)   Salivary function (<25%)   <0.5 /');
    disp('Retina (Emami)        Blindness                       / 15    2      65      1.8 - 2');
    disp('Spinal cord (Powers33)  White matter necrosis        13 /');
    disp('* = Niemierko / ** = Gay  / ***= Emami / **** = dose per fraction'); disp(' ');
    a=input('Enter the value of parameter a: ' );
    gamma50=input('Enter the value of parameter gamma50 (recommend 4 if unknown): ' );
    td50=input('Enter the TD50 (Gy): ');
    standard_fractionation=input('Enter the source data''s dose per fraction (Gy): ');
    ab=input('Enter the normal tissue alpha/beta ratio (Gy): ');
else
    disp('Error: Invalid choice. Exiting program.'); return;
end
%end of EUD mathematical model parameters input section
total_volume=0;
%calculating the biologically equivalent dose and the total volume
for i=1:nb
    bndvh(i,1)=dvh(i,1)*((ab+dvh(i,1)/nf))/(ab+standard_fractionation);
    total_volume=dvh(i,2)+total_volume;
end
%normalizing volume data to 1 (therefore, total volume corresponds to 1)
for i=1:nb
    dvh(i,2)=dvh(i,2)/total_volume;
    bndvh(i,2)=dvh(i,2);
end
eud=0;
%calculating the EUD
for i=1:nb
    eud=eud+(bndvh(i,2))*(bndvh(i,1))^a;
end
eud=eud^(1/a);
disp(' '); disp(' ');
message = sprintf('The equivalent uniform dose = %g Gy',eud);
disp(message); disp(' ');
%Results section
if (tissue_type==1)
    %calculating tumor contol probability
    tcp=1/(1+((tcd50/eud)^(4*gamma50)));
    tcp=tcp*100;
    message = sprintf('The tumor control probability = %10.10f %%',tcp);
    disp(message); disp(' ');
elseif (tissue_type==2)
    %calculating normal tissue complication probability
    ntcp=1/(1+((td50/eud)^(4*gamma50)));
    ntcp=ntcp*100;
    message = sprintf('The normal tissue complication probability = %10.10f %%',ntcp);
    disp(message); disp(' ');
end
%end of results section
