clear all 
close all
clc

%format short

% new algorithm for CACTI using TV denoising for each frame
% Xin Yuan; Bell Labs, Alcatel-Lucent
% xyuan@bell-labs.com
% initial date: 2015-7-02
fname = 'Traffic';
addpath(genpath('./funs'));
load(fname);
row = 256;
col = 256;
Xtst = X(1:row,1:col,1:1:end);  % original video

CodeFrame = 1;  % How many coded images, measurement
ColT = 8;  % How many frames are collasped into one measurement
[Row, Col, Frame] = size(Xtst);


% generate binary code
% Phi = rand(Row, Col,ColT);
 
% Phi(:,:,1) = binornd(1,0.5,[Row, Col]);
Phi = binornd(1,0.5,[Row, Col, ColT]);
Phi(:,:,1) = binornd(1,0.5,[Row, Col]);
 shift = 1;  % we use shift code
 for t=2:ColT
     Phi(1+(t-1)*shift:Row,:,t) = Phi(1+(t-2)*shift:Row-shift,:,t-1);    % mask is moving from  up to down
 end

 % generate measurement
 y = zeros(Row,Col,CodeFrame);
for t = 1:CodeFrame
   y(:,:,t) = sum(Xtst(:,:,(t-1)*ColT+(1:ColT)).*Phi,3);
end

%% set parameters
para.row = row;
para.col = col;
para.iter = 200;
para.lambda = 0.2;  
para.TVweight = 0.07;

A = @(z) A_xy(z, Phi);
%At = @(z) At_xy(z, Phi,Phi_sum);
At = @(z) At_xy_nonorm(z, Phi);

 Phi_sum = sum(Phi.^2,3);
Phi_sum(Phi_sum==0)=1;
 para.lambda = 1;
 para.Phi_sum = Phi_sum;
 para.iter =150;
 para.acc= 1;
 para.mu = 0.25;
 
 TV_m_all = {'ATV_ClipA', 'ATV_ClipB','ATV_cham','ATV_FGP','ITV2D_cham','ITV2D_FGP','ITV3D_cham','ITV3D_FGP'};
 
for k=1:CodeFrame        
        fprintf('----- Reconstructing frame-block %d of %d\n',k,CodeFrame);
        para.ori_im = Xtst(:,:,(k-1)*ColT+(1:ColT));
        y_use = y(:,:,k);
        %theta    =   DCT_CACTI_weight( y_use, para, A,At);
        
        %% Following algorithms are ATV
         para.iter =150;
         para.TVweight = 0.05;
        theta    =   TV_GAP_CACTI( y_use,1, para, A,At);  % GAP-ATV clipA
        
        para.TVweight = .05;
        para.iter =40;
        thetaATV_clipB    =   ATV_ClipB_GAP_CACTI( y_use,1, para, A,At); % GAP-ATV clipB
        %
        para.TVweight = 20;
        para.iter =50;
        thetaATV_cham    =   TV_GAP_CACTI_cham_ATV2D( y_use,1, para, A,At); % GAP-ATV-Cham
        
        %
        para.TVweight = 0.05;
        para.iter =50;
        thetaATV_FGP    =   TV_GAP_CACTI_FGP_ATV2D( y_use,1, para, A,At); % GAP-ATV-FGP
        
        %% Now we are doing ITV2D
        %
        para.TVweight = 10;
        para.iter =50;
        thetaITV2D_cham    =   TV_GAP_CACTI_cham_ITV2D( y_use,1, para, A,At); % GAP-ATV-Cham
        
         para.TVweight = 0.05;
        para.iter =50;
        thetaITV2D_FGP    =   TV_GAP_CACTI_FGP_ITV2D( y_use,1, para, A,At); % GAP-ATV-FGP
        
        %% Now we are doing ITV3D
        para.TVweight = 20;
        para.iter =150;
        thetaITV3D_cham    =   TV_GAP_CACTI_cham_ITV3D( y_use,1, para, A,At); % GAP-ATV-Cham
        
         para.TVweight = 0.05;
        para.iter =150;
        thetaITV3D_FGP    =   TV_GAP_CACTI_FGP_ITV3D( y_use,1, para, A,At); % GAP-ATV-FGP
        
        %%
        para.eta = 0.5;
        para.iter =150;
        theta_Admm    =   TV_ADMM_CACTI( y_use,1, para, A,At);  % GAP-ATV clipA
        
          para.TVweight = 0.05;
           para.iter =40;
         theta_FISTA    =   TV_FISTA_CACTI( y_use,1, para, A,At); 
         
         para.TVweight = 0.05;
           para.iter =500;
         theta_TwIST    =   TV_TwIST_CACTI( y_use,1, para, A,At); 
         
         for nm  =1:length(TV_m_all)
             para.TVweight = 0.05;
             para.iter =100;
                para.eta = 0.5;
             para.TVm = TV_m_all{nm};
             if(strcmp(para.TVm,'ATV_ClipB'))
                 para.iter = 40;
             end
             theta_admm{nm} = TV_ADMM_CACTI_all( y_use, para,A,At); 
         end
         
         for nm  =1:length(TV_m_all)
             para.TVweight = 0.05;
             para.iter =100;
             para.TVm = TV_m_all{nm};
             if(strcmp(para.TVm,'ATV_ClipB'))
                 para.iter = 40;
             end
             theta_gap{nm} = TV_GAP_CACTI_all( y_use, para,A,At); 
         end
         
         for nm  =1:length(TV_m_all)
             para.TVweight = 0.05;
             para.iter =30;
             para.TVm = TV_m_all{nm};
             if(strcmp(para.TVm,'ATV_ClipB'))
                 para.iter = 20;
             end
             theta_gap{nm} = TV_FISTA_CACTI_all( y_use, para,A,At); 
         end
         
         for nm  =1:length(TV_m_all)
             para.TVweight = 0.05;
             para.iter =300;
             para.TVm = TV_m_all{nm};
             if(strcmp(para.TVm,'ATV_ClipB'))
                 para.iter = 150;
             end
             theta_gap{nm} = TV_TwIST_CACTI_all( y_use, para,A,At); 
         end
  %  theta_tv_cham = TV_GAP_CACTI_cham( y_use,1, para, A,At);
%         para.mu = 1;
%         theta_tv_cham3d = TV_GAP_CACTI_cham3d( y_use,1, para, A,At);
%         
% %         para.TVweight = 1;
% %         theta_tv_dtdh_clip = TVDtDhv_clip_GAP_CACTI( y_use,1, para, A,At);
%         
%          para.mu = 0.15;
%         theta_tv_cham3d_mu15 = TV_GAP_CACTI_cham3d( y_use,1, para, A,At);
%         
%         para.mu = 1;
%         theta3    =   TVmm_GAP_CACTI( y_use,1, para, A,At);
%         
%         para.mu = 0.15;
%         theta_clip3d = TV3D_clip_GAP_CACTI( y_use,1, para, A,At);
        
%         para.mu = 0.10;
%         theta3 = TV3D_clip_GAP_CACTI( y_use,1, para, A,At);
  
        img_gap(:,:,(k-1)*ColT+(1:ColT)) = theta;
        img_gap3d(:,:,(k-1)*ColT+(1:ColT)) = theta2;
        img_gap3d_3(:,:,(k-1)*ColT+(1:ColT)) = theta3;
      
 end

    % show result
    %figure;
    
    figure;
for t=1:ColT
 subplot(5, ColT, t); imshow(theta(:,:,t)); title(['GAP-TV: psnr: ' num2str(psnr(theta(:,:,t), Xtst(:,:,t)))]);
 subplot(5, ColT, t+ColT); imshow(theta_tv_cham(:,:,t)); title(['GAP-TV-Cham: psnr: ' num2str(psnr(theta_tv_cham(:,:,t), Xtst(:,:,t)))]);
 %subplot(2, ColT, t+ColT); imshow(img_3dtv_hard(:,:,t)); title(['3DTV: psnr: ' num2str(PSNR_3dtv_hard(t)) ]);
 subplot(5, ColT, t+2*ColT); imshow(theta_tv_cham3d(:,:,t)); title(['3DTV-Cham: psnr: ' num2str(psnr(theta_tv_cham3d(:,:,t), Xtst(:,:,t))) ]);
  subplot(5, ColT, t+3*ColT); imshow(theta_clip3d (:,:,t)); title(['3DTV: psnr: ' num2str(psnr(theta_clip3d(:,:,t), Xtst(:,:,t))) ]);
  subplot(5, ColT, t+4*ColT); imshow(theta_tv_dtdh_clip(:,:,t)); title(['DtDh-Clip: psnr: ' num2str(psnr(theta_tv_dtdh_clip(:,:,t), Xtst(:,:,t))) ]);
end


 %% 
clear para 
para.row = row;
para.col = col;
para.T = ColT;
para.iter = 200;
para.Phi = Phi;
para.At = At;

% para.L1_3d = 0.008;
% para.L2_3d = 0.008;
para.L1_3d = 0.1; %.008;
para.L2_3d = 0.05; %.008;
para.L1_2d = 0.2;
para.L2_2d = 0.07;
 
for k=1:CodeFrame        
        fprintf('----- Reconstructing frame-block %d of %d\n',k,CodeFrame);
        para.ori_im = Xtst(:,:,(k-1)*ColT+(1:ColT));
        y_use = y(:,:,k);
        %theta    =   DCT_CACTI_weight( y_use, para, A,At);
        theta2    =   ATV_3D_CACTI( y_use,para);
        %theta3    =   ATV_3D_CACTI_Hard( y_use,para);
  
  
        img_3dtv(:,:,(k-1)*ColT+(1:ColT)) = theta2;
        %img_3dtv_hard(:,:,(k-1)*ColT+(1:ColT)) = theta3;
      
end
%  
 %save('traffic_3dtv.mat','-v7.3','img_3dtv','para','img_gap');
 
%  addpath(genpath('./SSTV_reference'))
%  theta    =   STTV_GAP_CACTI( y_use,1, para, A,At);
% 

for t=1:ColT*CodeFrame 
      PSNR_gap(t) = psnr(Xtst(:, :,t),img_gap(:,:,t));
      PSNR_3dtv(t) = psnr(Xtst(:, :,t),img_3dtv(:,:,t));
end

 figure;
for t=1:ColT
 subplot(2, ColT, t); imshow(img_gap(:,:,t)); title(['GAP-TV: psnr: ' num2str(PSNR_gap(t)) ]);
 %subplot(2, ColT, t+ColT); imshow(img_3dtv_hard(:,:,t)); title(['3DTV: psnr: ' num2str(PSNR_3dtv_hard(t)) ]);
  subplot(2, ColT, t+ColT); imshow(img_3dtv(:,:,t)); title(['SSTV: psnr: ' num2str(PSNR_3dtv(t)) ]);
end
