% % AZIMUTH_TUNING_1D.m -- Plots response as a function of azimuth for
% % heading task
% %--	YG, 07/12/04
% %     HH, 2013
% %     LBY, 20200319
% %-----------------------------------------------------------------------------------------------------------------------
function DirectionTuningPlot_1D_HH(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE, batch_flag);

Path_Defs;
ProtocolDefs; %contains protocol specific keywords - 1/4/01 BJP

monkey_inx = FILE(strfind(FILE,'m')+1:strfind(FILE,'c')-1);

switch monkey_inx
    case '5'
        monkey = 'Polo';
    case '6'
        monkey = 'Qiaoqiao';
    case '4'
        monkey = 'Whitefang';
end

stimType{1}='Vestibular';
stimType{2}='Visual';
stimType{3}='Combined';

%get the column of values for azimuth and elevation and stim_type
temp_azimuth = data.moog_params(AZIMUTH,:,MOOG);
temp_elevation = data.moog_params(ELEVATION,:,MOOG);
temp_stim_type = data.moog_params(STIM_TYPE,:,MOOG);
temp_amplitude = data.moog_params(AMPLITUDE,:,MOOG);
temp_motion_coherence = data.moog_params(COHERENCE,:,MOOG);
temp_interocular_dist = data.moog_params(INTEROCULAR_DIST,:,MOOG);
temp_num_sigmas = data.moog_params(NUM_SIGMAS,:,MOOG);

%now, get the firing rates for all the trials
temp_spike_rates = data.spike_rates(SpikeChan, :);

%get indices of any NULL conditions (for measuring spontaneous activity
trials = 1:length(temp_azimuth);

% If length(BegTrial) > 1 and all elements are positive, they are trials to be included.
% Else, if all elements are negative, they are trials to be excluded.
% This enable us to exclude certain trials ** DURING ** the recording more easily. HH20150410
select_trials = false(size(trials));
if length(BegTrial) == 1 && BegTrial > 0 % Backward compatibility
    select_trials(BegTrial:EndTrial) = true;
elseif all(BegTrial > 0) % To be included
    select_trials(BegTrial) = true;
elseif all(BegTrial < 0) % To be excluded
    select_trials(-BegTrial) = true;
    select_trials = ~ select_trials;
else
    disp('Trial selection error...');
    keyboard;
end

null_trials = logical( (temp_azimuth == data.one_time_params(NULL_VALUE)) );
azimuth = temp_azimuth(~null_trials & select_trials);
elevation = temp_elevation(~null_trials & select_trials);
stim_type = temp_stim_type(~null_trials & select_trials);
amplitude = temp_amplitude(~null_trials & select_trials);
spike_rates = temp_spike_rates(~null_trials & select_trials);
% motion_coherence = temp_motion_coherence(~null_trials & select_trials);
interocular_dist = temp_interocular_dist(~null_trials & select_trials);
num_sigmas = temp_num_sigmas(~null_trials & select_trials);

unique_azimuth = munique(azimuth');

unique_elevation = munique(elevation');
unique_stim_type = munique(stim_type');
unique_amplitude = munique(amplitude');
% unique_motion_coherence = munique(motion_coherence');
unique_interocular_dist = munique(interocular_dist');
unique_num_sigmas = munique(num_sigmas');

% descide whether loop is stim_type or num_sigmas (and it's the vestibular only condition)

if length(unique_num_sigmas)>1
    condition_num = num_sigmas;
else
    condition_num = stim_type;
end

unique_condition_num = munique(condition_num');

% time marks for each trial
event_in_bin = squeeze(data.event_data(:,:,trials));
stimOnT = find(event_in_bin == VSTIM_ON_CD);
stimOffT = find(event_in_bin == VSTIM_OFF_CD);
FPOnT = find(event_in_bin == FP_ON_CD);
FixInT = find(event_in_bin == IN_FIX_WIN_CD);

% calculate spontaneous firing rate
spon_found = find(null_trials==1);
spon_resp = mean(temp_spike_rates(spon_found));

% Add "length(unique_elevation)" to make it compatible with 3D-tuning
% Now I change the code to cope with situations where different angles have different repetitions (unbalanced ANOVA).
% So this "repetitionN" is no longer important. HH20150704
mean_repetitionN = floor( length(spike_rates) / (length(unique_azimuth) * length(unique_elevation)* length(unique_stim_type)*length(unique_condition_num)) ); % take minimum repetition

% creat basic matrix represents each response vector
resp = [];
for c=1:length(unique_condition_num)  % different sigmas
    
    resp{c} = nan(length(unique_azimuth),length(unique_stim_type));
    resp_std{c} = resp{c};
    resp_err{c} = resp{c};
    
    for c=1:length(unique_stim_type)
        
        resp_trial{c,c} = nan(100,length(unique_azimuth)); % A large enough matrix (if you're not TOO CRAZY). HH20150704
        
        for i=1:length(unique_azimuth)
            
            select = logical( azimuth==unique_azimuth(i) & elevation == 0 & stim_type==unique_stim_type(c) & condition_num==unique_condition_num(c) );
            
            % Cope with situations where different angles have different numbers of repetition (unbalanced ANOVA).  HH20150704
            rep_this = sum(select);
            repetitions(c,c,i) = rep_this; % Save it
            
            if (rep_this > 0)  % there are situations where visual/combined has >2 coherence and vestibular only has one coherence
                resp{c}(i, c) = mean(spike_rates(select));
                resp_std{c}(i,c) = std(spike_rates(select));
                resp_err{c}(i,c) = std(spike_rates(select)) / sqrt(rep_this);
                
                spike_temp = spike_rates(select);
                try
                    resp_trial{c,c}(1:rep_this,i) = spike_temp;
                catch
                    keyboard
                end
            else     % actually duplicate vestibular condition
                resp{c}(i, c) = resp{1}(i, c);
                resp_std{c}(i,c) = resp_std{1}(i,c);
                resp_err{c}(i,c) = resp_err{1}(i,c);
                
                resp_trial{c,c}(1:rep_this,i) = resp_trial{1,c}(1:rep_this,i);
            end
        end
        
        resp_trial{c,c}(all(isnan(resp_trial{c,c}),2),:) = []; % Trim the large matrix by removing unnecessary NaNs. HH20150704
        
    end
    
    % vectorsum and calculate preferred direction
    % vectors must be symetric, otherwise there will be a bias both on
    % preferred direction and the length of resultant vector
    % the following is to get rid off non-symetric data, hard code temporally
    
    %%{
    if length(unique_azimuth) > 999   % HH20130421 (Why the hell doing this? I did it in 'vectorsumAngle'.)
        pause;
        resp_s{c}(1,:) = resp{c}(1,:);
        resp_s{c}(2,:) = resp{c}(2,:);
        resp_s{c}(3,:) = resp{c}(4,:);
        resp_s{c}(4,:) = resp{c}(6,:);
        resp_s{c}(5,:) = resp{c}(7,:);
        resp_s{c}(6,:) = resp{c}(8,:);
        resp_s{c}(7,:) = resp{c}(9,:);
        resp_s{c}(8,:) = resp{c}(10,:);
    else
        resp_s{c}(:,:) = resp{c}(:,:);
    end
    %}
end

unique_rep = unique(repetitions);
unique_rep = unique_rep(unique_rep>0);

unique_azimuth_s = unique_azimuth;      % HH20130826
%unique_azimuth_s(1:16) = [0:22.5:350];     % HH20130421
unique_elevation_s(1:length(unique_azimuth)) = 0;
% unique_azimuth_plot = [unique_azimuth',360]; What's this for????

% If this is a discrimination protocol, Transferred from azimuth to heading. HH20140415
% aziToHeading = @(x)(mod(270-x,360)-180); % Transferred from azimuth to heading

% if Protocol == AZIMUTH_TUNING_1D
%     unique_azimuth_plot_heading = unique_azimuth';
%     [unique_azimuth_plot_heading, ~] = sort(unique_azimuth_plot_heading);
%     aziToHeadingSort = [7 6 5 4 3 2 1 8 7];
%     unique_azimuth_plot_heading = unique_azimuth_plot_heading(aziToHeadingSort);
% else
unique_azimuth_plot_heading = aziToHeading(unique_azimuth');
[unique_azimuth_plot_heading, aziToHeadingSort] = sort(unique_azimuth_plot_heading);

if sum(abs(unique_azimuth_plot_heading) == 180) > 0 % Make it circular
    unique_azimuth_plot_heading = [unique_azimuth_plot_heading unique_azimuth_plot_heading(1)+360];
    aziToHeadingSort = [aziToHeadingSort aziToHeadingSort(1)];
else % Don't make it circular
end

% end


for c=1:length(unique_condition_num)
    for c = 1: length(unique_stim_type)
        if length(resp_s{c}) >= length(unique_azimuth_s)
            [az(c,c), el(c,c), amp(c,c)] = vectorsumAngle(resp_s{c}(:,c), unique_azimuth_s, unique_elevation_s);
            % az(c,k) = 999; el(c,k) = 999; amp(c,k) = 999;
        else
            az(c,c) = NaN;   % this hard-coded method cannot handle < 8 azims  -CRF
        end
        
        % Modulation Index
        % DDI(c,k) = ( max(resp{c}(:,k))-min(resp{c}(:,k)) ) / ( max(resp{c}(:,k))-min(resp{c}(:,k))+mean(resp_std{c}(:,k)) );
        non_nan = ~isnan(resp{c}(:,c));
        non_nan_resp = resp{c}(non_nan,c);
        non_nan_resp_std = resp_std{c}(non_nan,c);
        non_nan_unique_azimuth = unique_azimuth(non_nan);
        
        DDI(c,c) = ( max(non_nan_resp)-min(non_nan_resp) ) / ( max(non_nan_resp)-min(non_nan_resp)+ ...
            2 * sqrt( sum(non_nan_resp_std.^2 / sum(non_nan)))) ;    % delta / (delta + 2 * sqrt(SSE/(N-M))) = delta / (delta + 2 * sqrt(SSE/(rep-1)/M)))
        
        % HTI_(c,k) = HTI(resp{c}(:,k)', spon_resp) % For 1-D tuning, the raw data should be in a row
        HTI_(c,c) = amp(c,c)/sum(abs(non_nan_resp-spon_resp));
        % HTI_(c,k) = amp(c,k)/sum(abs(resp{c}(:,k)))
        
        % HH20140425 Dprime: rightward is positive!
        % Find the neareast non-nan values to the dead ahead
        
        index_90 = find(non_nan_unique_azimuth == 90);
        Dprime(c,c) = - (non_nan_resp(index_90+1)-non_nan_resp(index_90-1)) / sqrt( (non_nan_resp_std(index_90+1)^2 + non_nan_resp_std(index_90-1)^2)/2 );
        
        % HH20130827
        index_270 = find(non_nan_unique_azimuth == 270);
        if ~isempty (index_270)
            Dprime_270(c,c) = (non_nan_resp(index_270+1) - non_nan_resp(index_270-1)) / sqrt( (non_nan_resp_std(index_270+1)^2 + non_nan_resp_std(index_270-1)^2)/2 );
        else
            Dprime_270(c,c) = NaN;
        end
        
        p_1D(c,c) = anova1(resp_trial{c,c},'','off');
        
    end
end


% % ------------------------------------------------------------------
% Define figure
xoffset=0;
yoffset=-0.010;

figure(2); clf;
set(gcf,'color','white');
set(2,'Position', [10,50 1500,700], 'Name', '1D Direction Tuning');

if ~isempty(batch_flag); set(2,'visible','off'); end
orient landscape;

% Transferred from azimuth to heading. HH20140415
% spon_azimuth = min(unique_azimuth_plot) : 1 : max(unique_azimuth_plot);
spon_azimuth = min(unique_azimuth_plot_heading) : 1 : max(unique_azimuth_plot_heading);

% temporarily hard coded, will be probematic if there are more than 3*3 conditions
% repetitions -GY
f{1,1}='bo-'; f{1,2}='ro-'; f{1,3}='go-';
f{2,1}='bo-'; f{2,2}='ro-'; f{2,3}='go-';
f{3,1}='bo-'; f{3,2}='ro-'; f{3,3}='go-';


for c=1: length(unique_stim_type)
    if( xoffset > 0.5)          % now temperarily 2 pictures one row and 2 one column
        yoffset = yoffset-0.45;
        xoffset = 0;
    end
    axes('position',[xoffset+0.07 0.65+yoffset 0.25 0.3]);
    
    for c=1:length(unique_condition_num)
        % Transferred from azimuth to heading. HH20140415
        non_nan = ~isnan(resp{c}(aziToHeadingSort,c));
        set(errorbar(unique_azimuth_plot_heading(non_nan), resp{c}(aziToHeadingSort(non_nan),c), resp_err{c}(aziToHeadingSort(non_nan),c), f{c,unique_stim_type(c)} ),'linewidth',2);
        hold on;
        
        % Fitting
        fitOK = 0;
        if sum(abs(unique_azimuth_plot_heading) == 180) > 0
            fo_ = fitoptions('method','NonlinearLeastSquares','Robust','On','Algorithm','T',...
                'StartPoint',[10 10 3.1400000000000001   1.4284],'Lower',[0 0 0 0],'Upper',[Inf 500   Inf Inf],'MaxFunEvals',5000);
            ft_ = fittype('a*exp(-2*(1-cos(x-pref))/sigma^2)+b',...
                'dependent',{'y'},'independent',{'x'},...
                'coefficients',{'a', 'b', 'pref', 'sigma'});
            
            not_nan = ~isnan(resp{c}(:,c));
            [cf_, goodness, output]= fit(unique_azimuth(not_nan)*pi/180,resp{c}(not_nan,c),ft_,fo_);
            
            if output.exitflag > 0 && cf_.sigma >= 0.3
                fitOK = 1;
            else
                fitOK = 0;
            end
            cf_
            goodness
            % Transferred from azimuth to heading. HH20140415
            if fitOK
                xx = 0:360;
                yy = feval(cf_,[0:360]/180*pi);
                [xx,sortxx] = sort(aziToHeading(xx));
                plot(xx,yy(sortxx),[f{c,unique_stim_type(c)}(1) '--'],'linewidth',2);
            end
        end
        
    end
    
    % Transferred from azimuth to heading. HH20140415
    plot([ min(unique_azimuth_plot_heading)  max(unique_azimuth_plot_heading)] ,[ spon_resp spon_resp], 'k--');
    
    % Forward and backward
    y_limits = ylim;
    axis manual;
    
    % Transferred from azimuth to heading. HH20140415
    plot([0 0], y_limits,'k--');
    
    % Preferred
    % Transferred from azimuth to heading. HH20140415
    line([aziToHeading(az(c,c)) aziToHeading(az(c,c))],y_limits,'Color',f{c,unique_stim_type(c)}(1),'linestyle','-','LineWidth',2); % VectorSum
    
    if fitOK
        prefGauss(c,c) = cf_.pref/pi*180;
        prefGauss(c,c) = mod(prefGauss(c,c) ,360);
        widGauss(c,c) = abs(2*acos(abs(1-cf_.sigma^2*log(2)/2))/pi*180);
    else
        prefGauss(c,c) = nan;
        widGauss(c,c) = nan; % HH20140425
    end
    
    % Transferred from azimuth to heading. HH20140415
    line([aziToHeading(prefGauss(c,c)) aziToHeading(prefGauss(c,c))],y_limits,'color',f{c,unique_stim_type(c)}(1),'linestyle','--','linewidth',2);       % Gaussian fitting
    
    if c == 1 ;ylabel('spikes/s'); end
    xlabel('Heading');
    
    % Transferred from azimuth to heading. HH20140415
    xlim( [min(unique_azimuth_plot_heading), max(unique_azimuth_plot_heading)] );
    title(sprintf('%sunit%g, %g, p = %.2e',FILE, SpikeChan,unique_stim_type(c),p_1D(c,c)));
    set(gca,'xtick',min(unique_azimuth_plot_heading):45:max(unique_azimuth_plot_heading));
    
    
    %% HH20130421 Plot in polar coordinates
    
    axes('position',[0.07+xoffset 0.15+yoffset 0.25 0.35]);
    
    non_nan = ~isnan(resp{c}(:,c));
    polarwitherrorbar([unique_azimuth(non_nan)/180*pi; unique_azimuth(1)/180*pi], [resp{c}(non_nan,c); resp{c}(1,c)],[resp_err{c}(non_nan,c) ;resp_err{c}(1,c)],f{c,unique_stim_type(c)}(1));
    hold on;
    
    h_p = polar((0:20:360)/180*pi, spon_resp * ones(1,length(0:20:360)),'k');
    set(h_p,'LineWidth',2.5);
    h_p = polar([az(c,c) az(c,c)]/180*pi,[0 amp(c,c)],f{c,unique_stim_type(c)}(1));
    set(h_p,'LineWidth',2.5);
    
    title(sprintf('%sunit%g, %g, p = %.2e',FILE, SpikeChan,unique_stim_type(c),p_1D(c,c)));
    
    set(findall(gcf,'fontsize',10),'fontsize',15);
    
    
    
    %%   HH20130421 MT neuron
    %{
    %%{   Transfer MST to MT   HH20130421
    
    RF = [-2.9, -5.1, 5.8, 10.1];


    MT_RF_x = RF(1) ;  % degree
    MT_RF_y = RF(2);  % degree
    unique_direction_MT = MSTazi2MTdir(MT_RF_x, MT_RF_y, unique_azimuth);
    
  
    
    if ishandle(101); close (101); end;
    figure(101);
    subplot(1,2,2); set(gcf,'color','white');
    polarwitherrorbar([unique_direction_MT/180*pi; unique_direction_MT(1)/180*pi], [resp{c}(:,k); resp{c}(1,k)],[resp_err{c}(:,k) ;resp_err{c}(1,k)]);
    %set(h_p,'LineWidth',3);
    hold on;
    h_p = polar((0:20:360)/180*pi, spon_resp * ones(1,length(0:20:360)),'k');
    set(h_p,'LineWidth',4);

    [az_MT(c,k), ~, amp_MT(c,k)] = vectorsumAngle(resp_s{c}(:,k), unique_direction_MT, unique_elevation_s);

    h_p = polar([az_MT(c,k) az_MT(c,k)]/180*pi,[0 amp_MT(c,k)],'r');
    set(h_p,'LineWidth',4);
    title(['p = ' num2str(p_1D) ', pref = ' num2str(az_MT(c,k))]);
    
    subplot(1,2,1);
    axis equal; box on; axis([-45 45 -45 45]);
    line([-45 45],[0 0],'color','k','LineStyle',':'); hold on;
    line([0 0],[-45 45],'color','k','LineStyle',':');
    set(gca,{'xtick','ytick'},{-40:20:40,-40:20:40});
    xlabel('degree');
    title([FILE ', MT RF x = ' num2str(MT_RF_x) '^o, y = ' num2str(MT_RF_y) '^o']);
    rectangle('position',[RF(1)-RF(3)/2 RF(2)-RF(4)/2, RF(3) RF(4)],...
        'Curvature',[0.2 0.2],'EdgeColor','r','LineWidth',1.5);
    figure(2);

    %}
    
    xoffset=xoffset+0.3;
    %     yoffset = yoffset -0.4;
    
end

fprintf('\n');
SetFigure(15);

%show file name and some values in text

axes('position',[0.1,0, 0.4,0.12] );
xlim( [0,100] );
ylim( [0,length(unique_stim_type)*length(unique_condition_num)+2] );
text(0, length(unique_stim_type)*length(unique_condition_num)+2, FILE);
text(40, length(unique_stim_type)*length(unique_condition_num)+2, 'SpikeChan=');
text(60, length(unique_stim_type)*length(unique_condition_num)+2, num2str(SpikeChan));
text(80, length(unique_stim_type)*length(unique_condition_num)+2, sprintf('rep = %s',num2str(unique_rep')));
text(0,length(unique_stim_type)*length(unique_condition_num)+1.5,['stim     coherence' repmat(' ',1,15) 'prefer', repmat(' ',1,10), 'DDI',repmat(' ',1,10), 'd''@90',repmat(' ',1,10),'d''@270',repmat(' ',1,10),'p', repmat(' ',1,10),'half-width']);

count=-0.5;
for c=1:length(unique_stim_type)
    for c=1:length(unique_condition_num)
        count=count+.7;
        text(0,length(unique_stim_type)*length(unique_condition_num)-(count-1),num2str(unique_stim_type(c)));
        text(20,length(unique_stim_type)*length(unique_condition_num)-(count-1), num2str(unique_condition_num(c)) );
        
        % Transferred from azimuth to heading. HH20140415
        text(40,length(unique_stim_type)*length(unique_condition_num)-(count-1), num2str(aziToHeading(az(c,c))) );
        text(60,length(unique_stim_type)*length(unique_condition_num)-(count-1), num2str(DDI(c,c)) );
        text(80,length(unique_stim_type)*length(unique_condition_num)-(count-1), num2str(HTI_(c,c)) );
        text(100,length(unique_stim_type)*length(unique_condition_num)-(count-1), num2str(Dprime(c,c)) );
        text(120,length(unique_stim_type)*length(unique_condition_num)-(count-1), num2str(Dprime_270(c,c)) );
        text(140,length(unique_stim_type)*length(unique_condition_num)-(count-1), num2str(p_1D(c,c)) );
        text(160,length(unique_stim_type)*length(unique_condition_num)-(count-1), num2str(widGauss(c,c)) );
    end
end
axis off;

str = [FILE,' Ch ',num2str(SpikeChan)];
ss = [str,'_1D tuning'];
saveas(gcf,['Z:\LBY\Recording data\',monkey,'\1D_Tuning\' ss], 'emf');


%% Data Saving
%{
% Reorganized. HH20141124
config.batch_flag = batch_flag;

%%%%%%%%%%%%%%%%%%%%% Change here %%%%%%%%%%%%%%%%%%%%%%%%%%%%
result = PackResult(FILE, SpikeChan, mean_repetitionN, unique_stim_type, ... % Obligatory!!
                    unique_azimuth_plot, unique_azimuth_plot_heading, aziToHeadingSort ,spike_rates,resp,resp_err,...
                    az,amp, DDI,HTI_,p_1D,Dprime,Dprime_270,prefGauss,widGauss);

config.suffix = 'AzimuthTuning';
config.xls_column_begin = 'Pref_vest';
config.xls_column_end = 'err_comb';

% Figures to save
config.save_figures = gcf;

% Only once
config.sprint_once_marker = '';
config.sprint_once_contents = '';
% Loop across each stim_type
config.sprint_loop_marker = {'ggggggggss'};
config.sprint_loop_contents = {strcat('aziToHeading(result.az(1,k)), result.DDI(1,k), result.HTI_(1,k), result.p_1D(1,k),',...
                        'result.Dprime(1,k), result.Dprime_270(1,k), aziToHeading(result.prefGauss(1,k)),',...
                        'result.widGauss(1,k), num2str(result.resp{1}(:,k)''), num2str(result.resp_err{1}(:,k)'')')};
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SaveResult(config, result);



% %%%%%%%%%%%%%%%%%%%%%%%  Output   HH20140510 / HH20140621 %%%%%%%%%%%%%%%%%
%
% if ~isempty(batch_flag)  % Figures
%
%     %%%%%%%%%%%%%%%%%%%%% Change here %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     suffix = ['AzimuthTuning'];
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     outpath = ['Z:\Data\Tempo\Batch\' batch_flag(1:end-2) '\'];
%
%     if ~exist(outpath,'dir')
%         mkdir(outpath);
%     end
%
%     % Save figures
%     orient landscape;
%     savefilename = [outpath [FILE '_' num2str(SpikeChan)] '_' suffix '.png'];
%
%     if exist(savefilename,'file')
%         delete(savefilename);
%     end
%     saveas(gcf,savefilename,'png');
%
% end
%
%
% % Print results
%
% %%%%%%%%%%%%%%%%%%%%% Change here %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Only once
% sprint_once_marker_temp = '';
% sprint_once_contents = '';
% % Loop across each stim_type
% sprint_loop_marker_temp = 'ggggggggss';  % For each stim_type
% sprint_loop_contents = ['aziToHeading(az(c,k)), DDI(c,k), HTI_(c,k), p_1D(c,k), Dprime(c,k), Dprime_270(c,k), ' ,...
%         'aziToHeading(prefGauss(c,k)), widGauss(c,k), num2str(resp{c}(:,k)''), num2str(resp_err{c}(:,k)'')'];
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% sprint_once_marker = [];
% for i = 1:length(sprint_once_marker_temp)
%     sprint_once_marker = [sprint_once_marker '%' sprint_once_marker_temp(i) '\t '];
% end
%
% sprint_loop_marker = [];
% for i = 1:length(sprint_loop_marker_temp)
%     sprint_loop_marker = [sprint_loop_marker '%' sprint_loop_marker_temp(i) '\t '];
% end
%
% if ~isempty(batch_flag)  % Print to file
%
%     outfile = [outpath suffix '.dat'];
%     printHead = 0;
%     if (exist(outfile, 'file') == 0)   % file does not yet exist
%         printHead = 1;
%     end
%
%     fid = fopen(outfile, 'a');
%     % This line controls the output format
%
%     if (printHead)
%         fprintf(fid, ['FILE\t ' sprint_once_contents '\t' sprint_loop_contents]);
%         fprintf(fid, '\r\n');
%     end
%
%     fprintf(fid,'%s\t',[FILE '_' num2str(SpikeChan)]);
%
% else  % Print to screen
%     fid = 1;
% end
%
% toClip = [];
%
% % Print once
% if ~isempty(sprint_once_marker_temp)
%     eval(['buff = sprintf(sprint_once_marker,' sprint_once_contents ');']);
%     fprintf(fid, '%s', buff);
%     toClip = [toClip sprintf('%s', buff)];
% end
%
% % Print loops
% for conditions = 1:3 % Always output 3 conditions (if not exist, fill with NaNs)
%     if sum(unique_stim_type == conditions)==0
%         buff = sprintf(sprint_loop_marker,ones(1,sum(sprint_loop_marker=='%'))*NaN);
%     else
%         k = find(unique_stim_type == conditions);
%         eval(['buff = sprintf(sprint_loop_marker,' sprint_loop_contents ');']);
%     end
%     fprintf(fid, '%s', buff);
%     toClip = [toClip sprintf('%s', buff)];
% end
%
% fprintf(fid, '\r\n');
% toClip = [toClip sprintf('\r\n')];
% clipboard('copy',toClip);
%
% if ~isempty(batch_flag)  % Close file
%     fclose(fid);
% end


% %% ---------------------------------------------------------------------------------------
% % Also, write out some summary data to a cumulative summary file
% sprint_txt = ['%s\t'];
% for i = 1 : 200
%      sprint_txt = [sprint_txt, ' %1.3f\t'];
% end
% if length(unique_stim_type)==1
%     buff = sprintf(sprint_txt, FILE, unique_stim_type, unique_condition_num, resp{1}(:,1) );
% elseif length(unique_stim_type)==2
%     buff = sprintf(sprint_txt, FILE, unique_stim_type, unique_condition_num, resp{1}(:,1), resp{1}(:,2) );
% elseif length(unique_stim_type)==3
%     buff = sprintf(sprint_txt, FILE, unique_stim_type, unique_condition_num, resp{1}(:,1), resp{1}(:,2), resp{1}(:,3) );
% end
% outfile = ['Z:\Users\Yong_work\Tuning1D.dat'];
%
% printflag = 0;
% if (exist(outfile, 'file') == 0)    %file does not yet exist
%     printflag = 1;
% end
% fid = fopen(outfile, 'a');
% if (printflag)
%     fprintf(fid, 'FILE\t');
%     fprintf(fid, '\r\n');
% end
% fprintf(fid, '%s', buff);
% fprintf(fid, '\r\n');
% fclose(fid);
% %---------------------------------------------------------------------------------------
% %--------------------------------------------------------------------------
% % SaveTrials(FILE,BegTrial,EndTrial,p_1D)
%}
return;
end

function dir = MSTazi2MTdir(x,y,azi)
for i = 1 : length(azi)
    if azi(i) >= 180 && azi(i) <= 360
        dir(i,1) = cart2pol(1/tand(azi(i)-180)-tand(x),-tand(y))/pi*180;
    elseif azi (i) < 180 && azi(i) >= 0
        dir(i,1) = cart2pol(1/tand(azi(i))-tand(x),-tand(y))/pi*180 + 180;
    end
end
end


