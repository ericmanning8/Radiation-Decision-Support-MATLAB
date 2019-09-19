% imrotate_3D rotates image volume A by angle degrees in a counterclockwise direction around its center point in the x,y-plane

function [OutMat]=imrotate_3D(InMat,degree)
    if (nargin<1) || (isempty(InMat)),
        disp('At least one input image');
        return;
    end
    
    if nargin<2, degree=0; end

    [nrow,ncol,slno]=size(InMat);
    
    if degree==180
        OutMat=zeros(nrow,ncol,slno);
    else
        OutMat=zeros(ncol,nrow,slno);
    end
    
    for nn=1:slno
        OutMat(:,:,nn)=imrotate(InMat(:,:,nn),degree);
    end
end