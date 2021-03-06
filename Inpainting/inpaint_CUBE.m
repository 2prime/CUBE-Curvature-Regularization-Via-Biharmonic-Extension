function u_image=inpaint_weight_BiH(f,id_matrix,local_scale,px_h,py_h,f_gt)



[n1,n2]=size(f);
n=n1*n2;





x1=[1:1:n1];
x2=[1:1:n2];
[X,Y]=meshgrid(x1,x2); 

X1=reshape(X,[],1);
X2=reshape(Y,[],1);

id_p=image2patch(id_matrix,X1,X2,1,1);

id=find(id_p);
id_c=find(~id_p);



uf=image2patch(f,X1,X2,1,1);
u=uf(id_c); 
g=uf(id);   


max_ite=10;

u_image=f;


X1_c=X1*max(abs(g))/n1;
X2_c=X2*max(abs(g))/n2;




for step=1:max_ite
    up1=image2patch_center(u_image,X1,X2,px_h,py_h);
    up=[up1,local_scale*X1_c,local_scale*X2_c];
    
    
    
    W = weight_ann(up');
    W_Laplace_full=W+(W');
    LAP = diag(sum(W_Laplace_full,2))-W_Laplace_full;
    W_Laplace=W_Laplace_full(id_c,id_c);
    
    
    coe_matrix=diag(sum(W_Laplace_full(id_c,:),2))-W_Laplace;
    g1 = zeros(size(W_Laplace_full,1),1);
    g1(id) = g;
    g1 = -LAP*(LAP*g1);
    rhs = g1(id_c);
    L = ichol(coe_matrix);
    fprintf('step=%d, ',step);
    
    
    
    u=pcg(@BiH,rhs,1e-6,100,L,L',u);
   %u=pcg(@Lap,rhs,1e-6,100,[],[],u);
    uf(id_c)=u;
    u_image=reshape(uf,n2,n1)';
    imagesc(u_image)
    colormap('gray')
    pause(0.2)
    fprintf('local_scale=%d, px_h=%d, py_h=%d, PSNR=%f\n',local_scale,px_h,py_h,psnr(u_image/255,f_gt/255))
end

function y = BiH(u)
    u1 = zeros(size(LAP,1),1);
    u1(id_c) = u;
    u1 = LAP*(LAP*u1);
    y = u1(id_c);
end
end