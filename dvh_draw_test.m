di=dicominfo('UCLA_PR_1/dose.dcm');
x=di.DVHSequence.Item_5.DVHData;
%ex1 Item_5, ROI #9 is the PTV
dose=x(1:2:length(x));
volume=x(2:2:length(x));

mindose=dose(1)*100;
maxdose=sum(dose)*100;
maxvol=sum(volume);

k=1;
cumvol = zeros(length(volume),1);
cumdose=zeros(length(dose),1);

while k < length(dose)-1
            cumvol(k) = sum(volume(k:length(volume))); 
            cumdose(k) = sum(dose(1:k)); 
            k = k+1;
end

cumdose = cumdose*100;

figure, plot(cumvol);