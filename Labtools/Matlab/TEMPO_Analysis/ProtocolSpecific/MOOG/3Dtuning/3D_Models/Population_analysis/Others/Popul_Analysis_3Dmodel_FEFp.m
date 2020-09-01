% Population analysis for 3D model
% 101# Best model fit distribution according to BIC
% 102# R_squared distribution of each model
% 103# Partial R_squared distribution
% LBY 20171205

%% load data & pack data
clear all;
cd('Z:\Data\TEMPO\BATCH\FEFp_3DTuning');
load('Z:\Data\TEMPO\BATCH\FEFp_3DTuning\PSTH3DModel_T_OriData.mat');
Monkey = 'Que';
models = {'VO','AO','VA','VJ','AJ','VAJ'};
%% analysis

colorDefsLBY;
T_vestiSig = cat(1,T_model.vestiSig);
% T_visSig = cat(1,T_model.visSig);
% R_vestiSig = cat(1,R_model.vestiSig);
% R_visSig = cat(1,R_model.visSig);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% basic infos.%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% disp(' ');
% disp([Monkey,':']);
% disp('Total cells for Translation 3D model: ');
% disp(['[ vestibular: ',num2str(T_vestiNo),' ]   [  visual: ',num2str(T_visNo),' ]']);
% disp('Total cells for Rotation 3D model: ');
% disp(['[ vestibular: ',num2str(R_vestiNo),' ]   [  visual: ',num2str(R_visNo),' ]']);

%%%%%%%%%%%%%%%%%%%% Best model fit according to BIC %%%%%%%%%%%%%%%%%%%%%%

[~,T_BIC_min_inx_vesti] = min(squeeze(cell2mat(struct2cell(T_BIC_vesti))));
% [~,T_BIC_min_inx_vis] = min(squeeze(cell2mat(struct2cell(T_BIC_vis))));
% [~,R_BIC_min_inx_vesti] = min(squeeze(cell2mat(struct2cell(R_BIC_vesti))));
% [~,R_BIC_min_inx_vis] = min(squeeze(cell2mat(struct2cell(R_BIC_vis))));

T_BIC_min_inx_vesti(T_vestiSig==0) = nan;
% T_BIC_min_inx_vis(T_visSig==0) = nan;
% R_BIC_min_inx_vesti(R_vestiSig==0) = nan;
% R_BIC_min_inx_vis(R_visSig==0) = nan;

T_BIC_min_vesti_hist = hist(T_BIC_min_inx_vesti,length(models));
% T_BIC_min_vis_hist = hist(T_BIC_min_inx_vis,length(models));
% R_BIC_min_vesti_hist = hist(R_BIC_min_inx_vesti,length(models));
% R_BIC_min_vis_hist = hist(R_BIC_min_inx_vis,length(models));

% % figures
% figure(101);set(gcf,'pos',[300 200 1000 600]);clf;
% BestFitModel = [T_BIC_min_vesti_hist;T_BIC_min_vis_hist;R_BIC_min_vesti_hist;R_BIC_min_vis_hist]';
% h = bar(BestFitModel,'grouped');
% xlabel('Models');ylabel('Cell Numbers (n)');
% set(gca,'xticklabel',models);
% set(h(1),'facecolor',colorDBlue,'edgecolor',colorDBlue);
% set(h(2),'facecolor',colorDRed,'edgecolor',colorDRed);
% set(h(3),'facecolor',colorLBlue,'edgecolor',colorLBlue);
% set(h(4),'facecolor',colorLRed,'edgecolor',colorLRed);
% title('Best model fit');
% h_l = legend(['Translation (Vestibular), n = ',num2str(T_vestiNo)],['Translation (Visual), n = ',num2str(T_visNo)],['Rotation (Vestibular), n = ',num2str(R_vestiNo)],['Rotation (Visual), n = ',num2str(R_visNo)],'location','NorthWest');
% set(h_l,'fontsize',15);
% SetFigure(15);
% set(gcf,'paperpositionmode','auto');
% saveas(101,'Z:\LBY\Population Results\BestFitModel','emf');

%%%%%%%%%%%%%%%%%  R_squared distribution of each model %%%%%%%%%%%%%%%%%%%

RSquared_T_vesti = squeeze(cell2mat(struct2cell(T_Rsquared_vesti)))';
% RSquared_T_vis = squeeze(cell2mat(struct2cell(T_Rsquared_vis)))';
% RSquared_R_vesti = squeeze(cell2mat(struct2cell(R_Rsquared_vesti)))';
% RSquared_R_vis = squeeze(cell2mat(struct2cell(R_Rsquared_vis)))';

RSquared_T_vesti(T_vestiSig==0) = nan;
% RSquared_T_vis(T_vestiSig==0) = nan;
% RSquared_R_vesti(R_vestiSig==0) = nan;
% RSquared_R_vis(R_vestiSig==0) = nan;

% % figures
% figure(102);set(gcf,'pos',[60 70 1500 800]);clf;
% [~,h_subplot] = tight_subplot(2,3,0.1,0.15);
% 
% axes(h_subplot(1));
% text(0.9,-0.3,'R^2','Fontsize',30,'rotation',90);
% text(1.1,0.1,'Translation','Fontsize',25,'rotation',90);
% text(1.1,-1.1,'Rotation','Fontsize',25,'rotation',90);
% axis off;
% 
% axes(h_subplot(2));
% hold on;
% plot(RSquared_T_vesti','-o','color',colorLGray,'markeredgecolor',colorDBlue);
% axis on;
% xlim([0.5 6.5]);ylim([-0.5 1]);
% set(gca,'xTick',1:6,'xticklabel',models);
% title('Vestibular');
% 
% axes(h_subplot(3));
% hold on;
% plot(RSquared_T_vis','-o','color',colorLGray,'markeredgecolor',colorDRed);
% axis on;
% xlim([0.5 6.5]);ylim([-0.5 1]);
% set(gca,'xTick',1:6,'xticklabel',models);
% title('Visual');
% 
% axes(h_subplot(5));
% hold on;
% plot(RSquared_R_vesti','-o','color',colorLGray,'markeredgecolor',colorLBlue);
% axis on;
% xlim([0.5 6.5]);ylim([-0.5 1]);
% set(gca,'xTick',1:6,'xticklabel',models);
% xlabel('Models');
% 
% axes(h_subplot(6));
% hold on;
% plot(RSquared_R_vis','-o','color',colorLGray,'markeredgecolor',colorLRed);
% axis on;
% xlim([0.5 6.5]);ylim([-0.5 1]);
% set(gca,'xTick',1:6,'xticklabel',models);
% xlabel('Models');
% 
% 
% SetFigure(20);
% set(gcf,'paperpositionmode','auto');
% saveas(102,'Z:\LBY\Population Results\RSquared_Distribution','emf');
% 
% %%%%%%%%%%%%%%%%%%%% Partial R_squared distribution  %%%%%%%%%%%%%%%%%%%%%%
% 
% 
% PartR2_T_vesti = squeeze(cell2mat(struct2cell(T_PartR2_vesti)))';
% PartR2_T_vis = squeeze(cell2mat(struct2cell(T_PartR2_vis)))';
% PartR2_R_vesti = squeeze(cell2mat(struct2cell(R_PartR2_vesti)))';
% PartR2_R_vis = squeeze(cell2mat(struct2cell(R_PartR2_vis)))';
% 
% PartR2_T_vesti(T_vestiSig==0) = nan;
% PartR2_T_vis(T_vestiSig==0) = nan;
% PartR2_R_vesti(R_vestiSig==0) = nan;
% PartR2_R_vis(R_vestiSig==0) = nan;
% 
% % figures
% figure(103);set(gcf,'pos',[60 70 1500 800]);clf;
% [~,h_subplot] = tight_subplot(2,3,0.1,0.15);
% 
% axes(h_subplot(1));
% text(0.9,-0.3,'Partial R^2','Fontsize',30,'rotation',90);
% text(1.1,0.1,'Translation','Fontsize',25,'rotation',90);
% text(1.1,-1.1,'Rotation','Fontsize',25,'rotation',90);
% axis off;
% 
% axes(h_subplot(2));
% hold on;
% plot(PartR2_T_vesti','-o','color',colorLGray,'markeredgecolor',colorDBlue);
% axis on;
% xlim([0.5 3.5]);ylim([-0.5 1]);
% set(gca,'xTick',1:3,'xticklabel',{'V/AJ','A/VJ','J/VA'});
% title('Vestibular');
% 
% axes(h_subplot(3));
% hold on;
% plot(PartR2_T_vis','-o','color',colorLGray,'markeredgecolor',colorDRed);
% axis on;
% xlim([0.5 3.5]);ylim([-0.5 1]);
% set(gca,'xTick',1:3,'xticklabel',{'V/AJ','A/VJ','J/VA'});
% title('Visual');
% 
% axes(h_subplot(5));
% hold on;
% plot(PartR2_R_vesti','-o','color',colorLGray,'markeredgecolor',colorLBlue);
% axis on;
% xlim([0.5 3.5]);ylim([-0.5 1]);
% set(gca,'xTick',1:3,'xticklabel',{'V/AJ','A/VJ','J/VA'});
% xlabel('Models');
% 
% axes(h_subplot(6));
% hold on;
% plot(PartR2_R_vis','-o','color',colorLGray,'markeredgecolor',colorLRed);
% axis on;
% xlim([0.5 3.5]);ylim([-0.5 1]);
% set(gca,'xTick',1:3,'xticklabel',{'V/AJ','A/VJ','J/VA'});
% xlabel('Models');
% 
% SetFigure(20);
% set(gcf,'paperpositionmode','auto');
% saveas(103,'Z:\LBY\Population Results\Partial_RSquared_Distribution','emf');

%%%%%%%%%%%%%%%%%%%%  R_squared distribution  %%%%%%%%%%%%%%%%%%%%%%

% models = {'VO','AO','VA','VJ','AJ','VAJ'};
% xR2 = 0.05:0.1:0.85;
% 
% % figures
% figure(104);set(gcf,'pos',[60 70 1500 800]);clf;
% [~,h_subplot] = tight_subplot(2,4,0.1,0.15);
% 
% for ii = 1:6
%     
% axes(h_subplot(ii));
% hold on;
% [nelements, ncenters] = hist(RSquared_T_vesti(:,ii),xR2);
% h1 = bar(ncenters, nelements, 0.8,'k','edgecolor','k');
% set(h1,'linewidth',1.5);
% % text(170,max(max(nelements),max(nelements)),['n = ',num2str(length(T_vestiSPeakT_plot))]);
% plot(nanmedian(RSquared_T_vesti(:,ii)),max(nelements)*1.1,'kv');
% text(nanmedian(RSquared_T_vesti(:,ii))*1.1,max(nelements)*1.2,num2str(nanmedian(RSquared_T_vesti(:,ii))));
% % set(gca,'xtick',[0 500 1000 1500],'xticklabel',[],'xlim',[0 1600]);
% % xlabel('Single-peaked');
% title([models{ii},' model']);
% axis on;
% hold off;
%           
% end
% 
% suptitle('Translation - vestibular');
% SetFigure(15);
% 
% figure(105);set(gcf,'pos',[60 70 1500 800]);clf;
% [~,h_subplot] = tight_subplot(2,4,0.1,0.15);
% 
% for ii = 1:6
%     
% axes(h_subplot(ii));
% hold on;
% [nelements, ncenters] = hist(RSquared_T_vis(:,ii),xR2);
% h1 = bar(ncenters, nelements, 0.8,'k','edgecolor','k');
% set(h1,'linewidth',1.5);
% % text(170,max(max(nelements),max(nelements)),['n = ',num2str(length(T_visSPeakT_plot))]);
% plot(nanmedian(RSquared_T_vis(:,ii)),max(nelements)*1.1,'kv');
% text(nanmedian(RSquared_T_vis(:,ii))*1.1,max(nelements)*1.2,num2str(nanmedian(RSquared_T_vis(:,ii))));
% % set(gca,'xtick',[0 500 1000 1500],'xticklabel',[],'xlim',[0 1600]);
% % xlabel('Single-peaked');
% title([models{ii},' model']);
% axis on;
% hold off;
%           
% end
% 
% suptitle('Translation - visual');
% SetFigure(15);
% 
% 
% % figures
% figure(106);set(gcf,'pos',[60 70 1500 800]);clf;
% [~,h_subplot] = tight_subplot(2,4,0.1,0.15);
% 
% for ii = 1:6
%     
% axes(h_subplot(ii));
% hold on;
% [nelements, ncenters] = hist(RSquared_R_vesti(:,ii),xR2);
% h1 = bar(ncenters, nelements, 0.8,'k','edgecolor','k');
% set(h1,'linewidth',1.5);
% % text(170,max(max(nelements),max(nelements)),['n = ',num2str(length(R_vestiSPeakR_plot))]);
% plot(nanmedian(RSquared_R_vesti(:,ii)),max(nelements)*1.1,'kv');
% text(nanmedian(RSquared_R_vesti(:,ii))*1.1,max(nelements)*1.2,num2str(nanmedian(RSquared_R_vesti(:,ii))));
% % set(gca,'xtick',[0 500 1000 1500],'xticklabel',[],'xlim',[0 1600]);
% % xlabel('Single-peaked');
% title([models{ii},' model']);
% axis on;
% hold off;
%           
% end
% 
% suptitle('Rotation - vestibular');
% SetFigure(15);
% 
% figure(107);set(gcf,'pos',[60 70 1500 800]);clf;
% [~,h_subplot] = tight_subplot(2,4,0.1,0.15);
% 
% for ii = 1:6
%     
% axes(h_subplot(ii));
% hold on;
% [nelements, ncenters] = hist(RSquared_R_vis(:,ii),xR2);
% h1 = bar(ncenters, nelements, 0.8,'k','edgecolor','k');
% set(h1,'linewidth',1.5);
% % text(170,max(max(nelements),max(nelements)),['n = ',num2str(length(R_visSPeakR_plot))]);
% plot(nanmedian(RSquared_R_vis(:,ii)),max(nelements)*1.1,'kv');
% text(nanmedian(RSquared_R_vis(:,ii))*1.1,max(nelements)*1.2,num2str(nanmedian(RSquared_R_vis(:,ii))));
% % set(gca,'xtick',[0 500 1000 1500],'xticklabel',[],'xlim',[0 1600]);
% % xlabel('Single-peaked');
% title([models{ii},' model']);
% axis on;
% hold off;
%           
% end
% 
% suptitle('Rotation - visual');
% SetFigure(15);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% weight %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(105);set(gcf,'pos',[60 70 1500 800]);clf;
[~,h_subplot] = tight_subplot(2,3,[0.1 0.02],0.15);

axes(h_subplot(2));
T_vesti_w = squeeze(cell2mat(struct2cell(T_wVAJ_vesti)))';
%-- Plot the axis system
[h,hg,htick]=terplot(5);
%-- Plot the data ...
hter=ternaryc(T_vesti_w(:,3),T_vesti_w(:,1),T_vesti_w(:,2));
%-- ... and modify the symbol:
set(hter,'marker','o','markerfacecolor',colorDBlue,'markersize',7,'markeredgecolor','w');
terlabel('wJ','wV','wA');
% view(180,-90);
title('T - vestibular');
% axis off;

% axes(h_subplot(3));
% T_vis_w = squeeze(cell2mat(struct2cell(T_wVAJ_vis)))';
% %-- Plot the axis system
% [h,hg,htick]=terplot(5);
% %-- Plot the data ...
% hter=ternaryc(T_vis_w(:,3),T_vis_w(:,1),T_vis_w(:,2));
% %-- ... and modify the symbol:
% set(hter,'marker','o','markerfacecolor',colorDRed,'markersize',7,'markeredgecolor','w');
% terlabel('wJ','wV','wA');
% 
% title('T - visual');
% % axis off;
% 
% axes(h_subplot(5));
% R_vesti_w = squeeze(cell2mat(struct2cell(R_wVAJ_vesti)))';
% %-- Plot the axis system
% [h,hg,htick]=terplot(5);
% %-- Plot the data ...
% hter=ternaryc(R_vesti_w(:,3),R_vesti_w(:,1),R_vesti_w(:,2));
% %-- ... and modify the symbol:
% set(hter,'marker','o','markerfacecolor',colorLBlue,'markersize',7,'markeredgecolor','w');
% terlabel('wJ','wV','wA');
% 
% title('R - vestibular');
% % axis off;
% 
% axes(h_subplot(6));
% R_vis_w = squeeze(cell2mat(struct2cell(R_wVAJ_vis)))';
% %-- Plot the axis system
% [h,hg,htick]=terplot(5);
% %-- Plot the data ...
% hter=ternaryc(R_vis_w(:,3),R_vis_w(:,1),R_vis_w(:,2));
% %-- ... and modify the symbol:
% set(hter,'marker','o','markerfacecolor',colorLRed,'markersize',7,'markeredgecolor','w');
% terlabel('wJ','wV','wA');
% 
% title('R - visual');
% % axis off;

SetFigure(15);

