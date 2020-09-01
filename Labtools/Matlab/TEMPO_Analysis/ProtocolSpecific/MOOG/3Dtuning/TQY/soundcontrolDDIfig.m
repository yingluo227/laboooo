load('Z:\Data_analyses\Recording_data\DDIcontrol\RSCsounddi.mat')
load('Z:\Data_analyses\Recording_data\DDIcontrol\PCCsounddi.mat')
num1=[];num2=[]
% numT1=find(pccDDI{3,2}(1,:)==1);
% numT2=find(rscDDI{3,2}(1,:)==1);
% numR2=find(rscDDI{4,2}(1,:)==1);
numT1=find(pccDDI{3,2}(5,:)<=0.1);
numT2=find(rscDDI{3,2}(5,:)<=0.1);
numR2=find(rscDDI{4,2}(5,:)<=0.1);

if ~isempty(numT1)
    scatter(pccDDI{3,2}(3,numT1),pccDDI{3,2}(4,numT1),'r','*');
    hold on;
end
if ~isempty(numT2)
    scatter(rscDDI{3,2}(3,numT2),rscDDI{3,2}(4,numT2),'b','*');
    hold on;
end
if ~isempty(numR2)
    scatter(rscDDI{4,2}(3,numR2),rscDDI{4,2}(4,numR2),'b','o');
    hold on;
end
plot([0 1],[0 1],'k');
legend('PPC T','RSC T','RSC R','location','eastoutside');
xlim([0.3,0.8]);
ylim([0.3,0.8]);
xlabel('DDI');
ylabel('DDI for soundcontrol');