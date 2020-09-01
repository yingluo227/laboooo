% namelist = dir('Z:\Data\Tempo\Batch\testPCCcontrol\*.mat');
clear all;
% PATH=['Z:\Data\Tempo\Batch\testPCCdark\'];
% PATH=['Z:\Data\Tempo\Batch\testRSCdark\'];
% PATH=['Z:\Data\Tempo\Batch\testPCCsound\'];
PATH=['Z:\Data\Tempo\Batch\testRSCsound\'];
namelist = dir([PATH '*.mat']);
% controlPATH=['Z:\Data\Tempo\Batch\testPCCforControl\'];
controlPATH=['Z:\Data\Tempo\Batch\testRSCforControl\'];


% 读取后namelist 的格式为
% name -- filename
% date -- modification date
% bytes -- number of bytes allocated to the file
% isdir -- 1 if name is a directory and 0 if not
controlplotT=[];
controlplotR=[];
name={};
nameT={};
nameR={};
countT=0;countR=0;
stimtype=1;
% if PATH(28:31)==['soun']
%     stimtype=2;
% end
len = length(namelist);
for i = 1:len
    clear x;clear y;openfilename=[];openfilename={};
    file_name{i}=namelist(i).name;
    if isempty(strfind(file_name{i},'Error'))
        x= load([PATH file_name{i}]);
        name{i}=[x.result.FILE '_' num2str(x.result.SpikeChan)];
        if x.result.Protocol==100
            type=['_T'];
            countT=countT+1;
            nameT{countT}=name{i};
            controlplotT(2,countT)=x.result.PSTH.respon_sigTrue(stimtype);
            controlplotT(4,countT)=x.result.DDI(stimtype);
            controlplotT(6,countT)=x.result.p_anova_dire(stimtype);
            namelen=length(name{i});
            openfilename = [controlPATH name{i}(1:namelen-3) '*' name{i}(namelen-1:namelen) '_PSTH' type '.mat'];
            openfilename2=dir(openfilename);
            y=load([controlPATH openfilename2.name]);
            if ~isempty(y)
                controlplotT(1,countT)=y.result.PSTH.respon_sigTrue(1);
                controlplotT(3,countT)=y.result.DDI(1);
                controlplotT(5,countT)=y.result.p_anova_dire(1);
            else
                keyborad;
            end
            
        elseif x.result.Protocol==112
            type=['_R'];
            countR=countR+1;
            nameR{countR}=name{i};
            controlplotR(2,countR)=x.result.PSTH.respon_sigTrue(stimtype);
            controlplotR(4,countR)=x.result.DDI(stimtype);
            controlplotR(6,countR)=x.result.p_anova_dire(stimtype);
            namelen=length(name{i});
            openfilename = [controlPATH name{i}(1:namelen-3) '*' name{i}(namelen-1:namelen) '_PSTH' type '.mat'];
            openfilename2=dir(openfilename);
            y=load([controlPATH openfilename2.name]);
            if ~isempty(y)
                controlplotR(1,countR)=y.result.PSTH.respon_sigTrue(1);
                controlplotR(3,countR)=y.result.DDI(1);
                controlplotR(5,countR)=y.result.p_anova_dire(1);
            else
                keyborad;
            end
        else
            keyborad;
        end
        %     openfilename = [outpath [result.FILE '_' num2str(result.SpikeChan)] '_' config.suffix '.mat'];
    end
end
savefilename=['Z:\Data_analyses\Recording_data\DDIcontrol\' PATH(25:31) 'ddi.mat'];
if PATH(25:27)==['PCC']
    pccDDI={};
    pccDDI={'nameT',nameT;'nameR',nameR;'controlplotT',controlplotT;'controlplotR',controlplotR;};
save(savefilename,'pccDDI');
elseif PATH(25:27)==['RSC']
    rscDDI={};
    rscDDI={'nameT',nameT;'nameR',nameR;'controlplotT',controlplotT;'controlplotR',controlplotR;};
    save(savefilename,'rscDDI');
end
