

% �����Զ�ͣ�ڳ���ĵط�
dbstop if error
% �����ϲ�workspace
dbup
% �����ϲ�workspace
dbdown

% link axes

ax(1) = subplot(1,2,1);
plot(x,y1);
ax(2) = subplot(1,2,2);
plot(x,y2);
linkaxes(ax,'x');


% ���ұߵ�axisչʾ (������2016a��
plot(x,y1);
yyaxis right;
plot(a,y2);

% ��ͼ�ŵ�����Ļһ����
fig = figure;
set(fig,'position',get(0,'screensize'));

% ȥ�������е�NaN/inf
a(isnan(a)) = [];

% ������ض�����֮������б���
% clearvars -except ax, h

% ����򵥻�

function r = fmat2(x)
if x>0
    r = x.^2;
else
    r = 1./x;
end

fmat3 = @(x)x.^2.*(x>0)+1./x.*(x<=0);

% �ж���ȫҲ����������

a = 1*(b>0)+2*(b == 0)+3*(b<0);

% ��ʾ������
waitbar 