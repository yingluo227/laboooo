

Dir=dir('��\*.jpg');%ĳ��·�������е�jpg
for i =1:length(Dir)    
    eval(['!rename ','...\',Dir(i).name,' ',int2str(i),'.jpg'])
    %��ߵĿո�������٣���·���µ�ĳ�ļ��滻������Ҫ������
end
