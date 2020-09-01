function Delayed_Saccade_Analysis_HH(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE, batch_flag);

TEMPO_Defs;
Path_Defs;
ProtocolDefs;

%% Commented by HH201310123
%{
tic;

temp_azimuth = data.moog_params(AZIMUTH,:,MOOG);
temp_elevation = data.moog_params(ELEVATION,:,MOOG);
temp_stim_type = data.moog_params(STIM_TYPE,:,MOOG);
temp_heading   = data.moog_params(HEADING,:,MOOG);
temp_amplitude = data.moog_params(AMPLITUDE,:,MOOG);
temp_num_sigmas = data.moog_params(NUM_SIGMAS,:,MOOG);
temp_total_trials = data.misc_params(OUTCOME,:);
temp_spike_data = data.spike_data(SpikeChan,:);
temp_event_data = data.spike_data(2,:);
temp_spike_rates = data.spike_rates(SpikeChan,:);
% temp_accel = data.eye_data(5,:,:);
% temp_diode = data.eye_data(8,:,:);
temp_eyex = data.eye_data(3,:,:);
temp_eyey = data.eye_data(4,:,:);
% accel = reshape(temp_accel, 1000, length(temp_total_trials));
% diode = reshape(temp_diode, 1000, length(temp_total_trials));
eyex=reshape(temp_eyex, 1000, length(temp_total_trials));
eyey=reshape(temp_eyey, 1000, length(temp_total_trials));

%now, remove trials from direction and spike_rates that do not fall between BegTrial and EndTrial
trials = 1:length(temp_azimuth);		% vector of trial indices
% select_trials = ((trials >= BegTrial) & (trials <= EndTrial));

stim_type = temp_stim_type(trials);
heading = temp_heading(trials);
amplitude= temp_amplitude(trials);
num_sigmas= temp_num_sigmas(trials);
total_trials = temp_total_trials(trials);
spike_rates = temp_spike_rates(trials);
% unique_stim_type = munique(stim_type');
unique_heading = munique(heading');
unique_amplitude = munique(amplitude');
unique_num_sigmas = munique(num_sigmas');




timebin=40;
% sample frequency depends on test duration
frequency=length(temp_spike_data)/length(total_trials);
% length of x-axis
x_length = frequency/timebin;
% x-axis for plot PSTH
x_time=1:(frequency/timebin);

time_step=1;

%Realign data to target onset and saccade onset
for k=1: length(unique_amplitude)
    for i=1:length(unique_heading)
        
        select = logical( (heading==unique_heading(i)) & (amplitude==unique_amplitude(k)) );
        act_found = find( select==1 );
        temp_count = [];

        for repeat=1:length(act_found)
            for n=1:(x_length)
                temp_count(repeat,n)=sum(temp_spike_data(1,(frequency*(act_found(repeat)-1)+time_step):(frequency*(act_found(repeat)-1)++n*timebin)));
                time_step=time_step+timebin;
            end
            time_step=1;
        end
        count_y_trial{i,k}(:,:) = temp_count;  % align to the target onset
        count_y_mean{i,k}(1,:) = mean(temp_count);
        max_count(i) = max(count_y_mean{i,k}(1,:));
    end
end

% plot figures
figure(2);
set(2,'Position', [5,5 1000,700], 'Name', 'PSTH','color','w');
orient landscape;
%title(FILE);

stim_start_moog = find(data.event_data(1,:,1) == 4);
stim_over_moog = find(data.event_data(1,:,1) == 5);

x_time = x_time - stim_start_moog/timebin*ones(1,length(x_time));  % in x_time

% x_start = [stim_start_moog/timebin, stim_start_moog/timebin];
% x_stop =  [stim_over_moog/timebin,  stim_over_moog/timebin];

x_start = [0 0];
x_stop =  [(stim_over_moog-stim_start_moog)/timebin,  (stim_over_moog-stim_start_moog)/timebin];
y_marker=[0,max(max_count)];

x_time = x_time * (5 / timebin); % in s (total length 5s, hard coded temporarily. HH20130908)
x_stop = x_stop * (5 / timebin);

positions = [6,3,2,1,4,7,8,9];

for i = 1:8
    
    subplot(3,3,positions(i)); % saccade to right/0
    bar( x_time,count_y_mean{i,1}(1,:) );
    hold on;
    plot( x_start , y_marker, 'r-');
    plot( x_stop,  y_marker, 'r-');
    xlim([-1,5]);
    ylim([0,max(max_count)]);
    box on;
       
end
toc;

%}

%% Added by HH20131023
%%{

% tic;

% Trial information
heading_per_trial = data.moog_params(HEADING,:,MOOG);
unique_heading = munique(heading_per_trial');
unique_heading(isnan(unique_heading))=[];
repetitionN = length(heading_per_trial) /length(unique_heading) ;

% Spike data
spike_in_bin = squeeze(data.spike_data(SpikeChan,:,:));   % 5000 * TrialNum for default
spikeN_trial = sum(spike_in_bin,1);
spikeN_cum_trial = [0 cumsum(spikeN_trial)];   % Find the start & end spikes number of each trial (for later indexing use)
spikeT_raw = mod(find(spike_in_bin>0),size(spike_in_bin,1));  % Fast way to find spike times

% Event data
events_in_bin = squeeze(data.event_data(1,:,:));
align_markers = [4 7];  % Desired markers: visual onset & sac onset
for j = 1:length(align_markers)    % For each desired marker
    align_offsets(:,j) = mod(find(events_in_bin == align_markers(j)),size(events_in_bin,1));  % Fast way to find offsets of each trial
end

% numBins = 50; % Fixed bin numbers

% Fixed bin size = 50 ms
% SPEED should be 1000 in TEMPO!!

timeBinSize = 25; % in ms
spikeSum = sum(spike_in_bin,2);
spikeBeginTime = find(spikeSum>0,1,'first');
spikeEndTime = find(spikeSum>0,1,'last');
numBins = round((spikeEndTime-spikeBeginTime)/timeBinSize);

% Defint temporal slices = [ beginT endT alignTo Marker color]
temporal_Slice = {
    %     -500 -200 04 'Background' 'k';          % Background: -500 ~ -100 ms (04)
    %     75 275 04 'LS' 'm';               % LS: 75 ~ 275 ms (04);
    -485 0 04 'FP On' 'm';
    -800 -200 07 'Sustained'  'g';          % Sustained: 200 ~ 800 ms (04);
    -200 -25 07 'pre-S' 'b';         %  pre-S: -200 ~ 0 (07);
    %     -50 50 07 'S-Co' 'c';  % Saccade-coincident: -25 ~ 75 (07)
    50 400 07 'post-S' 'r';     % post-S: 50 ~ 500 (07)
    };

% Preallocating
result_PSTH = cell(length(align_markers),length(unique_heading));

% Now we align spike time to each marker, for different conditions
for i = 1:length(unique_heading)  % For each heading (delayed-saccade direction)
    select_binary = logical(heading_per_trial == unique_heading(i));
    select_trialN = find(select_binary == 1);
    
    spike_cache = NaN(spikeN_cum_trial(end),length(align_markers));       % Pre-allocation for speed
    spike_cache_numbers = 0;   % Number of spikes already in the cache
    
    for rep = 1: repetitionN  % For each repeats
        this_trialN = select_trialN(rep);
        
        % Put spike times of this trial into cache (with desired offsets)
        spike_cache_thisTrial  ...
            = repmat(spikeT_raw(spikeN_cum_trial(this_trialN)+1 : spikeN_cum_trial(this_trialN+1)),1,length(align_markers)) ...   % Raw spike time for this trial
            - repmat(align_offsets(this_trialN,:),spikeN_trial(this_trialN),1); % Minus time offsets for j'th marker
        
        spike_cache(spike_cache_numbers+1 : spike_cache_numbers+spikeN_trial(this_trialN) , :) = spike_cache_thisTrial;
        
        spike_cache_numbers = spike_cache_numbers + spikeN_trial(this_trialN);
        
        % Put spike counts during different phases into cache
        for sliceN = 1:size(temporal_Slice,1)
            resp_trial{sliceN}(rep,i) = sum(spike_cache_thisTrial(:, align_markers==temporal_Slice{sliceN,3}) >= temporal_Slice{sliceN,1} & ...
                spike_cache_thisTrial(:,align_markers==temporal_Slice{sliceN,3}) <= temporal_Slice{sliceN,2}) ...
                / (temporal_Slice{sliceN,2}-temporal_Slice{sliceN,1}) * 1000; % in Hz
        end
        
    end
    
    % PSTH
    for j = 1:length(align_markers)    % For each desired marker
        [result_PSTH{j,i}, x(:,j)] = hist(spike_cache(:,j),numBins);
        result_PSTH{j,i} = result_PSTH{j,i} / repetitionN / timeBinSize * 1000;  % in Hz
    end
    
end

vectSum = cell(size(temporal_Slice,1),1);
vectAmp = cell(size(temporal_Slice,1),1);

for sliceN = 1:size(temporal_Slice,1)
    % --- Calculating spatial selectivity ---
    % Statistics
    resp{sliceN} = mean(resp_trial{sliceN},1);
    resp_err{sliceN} = std(resp_trial{sliceN},0,1) / sqrt(repetitionN);
    p{sliceN} =  anova1(resp_trial{sliceN},'','off');
    
    % Vector Sum
    [vectSum{sliceN}, ~ , vectAmp{sliceN}] = vectorsumAngle(resp{sliceN}, unique_heading);
    
    % DDI
    % HTI{sliceN} = vectAmp{sliceN} / sum(abs( resp{sliceN} - mean(resp{1})))
    DDI{sliceN} = ( max(resp{sliceN})-min(resp{sliceN}) ) / ( max(resp{sliceN})-min(resp{sliceN})+ ...
        2 * sqrt( sum(resp_err{sliceN}.^2 * repetitionN * (repetitionN-1))/(length(heading_per_trial) - length(unique_heading))));    % delta / (delta + 2 * sqrt(SSE/(N-M)))
    
    % --- Calculating activity index (Barash, et al 1991) ---
    if sliceN == 1
        background = mean(resp{1});
        activityIndex{1} = 0;
        continue; % No activity index for background
    end
    
    if background >= 1
        if max(resp{sliceN}) >= 1.2 * background % Excitatory
            activityIndex{sliceN} = (max(resp{sliceN})-background)/sqrt(background);
        else  % Inhibitory
            activityIndex{sliceN} = (min(resp{sliceN})-background)/sqrt(background);
        end
    else
        if max(resp{sliceN}) >= 1.2 * background % Excitatory
            activityIndex{sliceN} = (max(resp{sliceN})-background);
        else  % Inhibitory
            activityIndex{sliceN} = (min(resp{sliceN})-background);
        end
    end
end


% Plotting
set(0,'DefaultAxesXTickMode','auto');

% PSTHs
for j = 1:length(align_markers)
    
    figure(4+j-1); clf;
    set(4+j-1,'Position', [5,5 900,800], 'Name', 'PSTH','color','w');
    orient landscape;
    positions = [6,3,2,1,4,7,8,9];
    maxPSTH = 0;
    
    for i = 1:length(unique_heading)
        subplot(3,3,positions(i)); % saccade to right/0
        set(bar(x(:,j), result_PSTH{j,i},1),'FaceColor','k','EdgeColor','none');
        maxPSTH = max(maxPSTH, max(result_PSTH{j,i}));
        hold on;
        set(gca,'xtick',0);
        if align_markers(j) == 4 % Vis On
            set(gca,'xticklabel',{'Stim On'});
        elseif align_markers(j) == 7 % Sac On
            set(gca,'xticklabel',{'Sac On'});
        end
        set(gca,'yticklabel',[]);
        box off;
    end
    %     toc;
    
    
    if align_markers(j) == 4 % Vis On
        plotXLim = [-500 1500];
    elseif align_markers(j) == 7 % Sac On
        plotXLim = [-1500 500];
    end
    
    for i = 1:length(unique_heading)
        subplot(3,3,positions(i));
        xlim(plotXLim);
        ylim([0, maxPSTH*1.1]);
        plot([0 0],[0 maxPSTH*1.1],'r-','LineWidth',2);
        axis off;
        %         plot( sum(plotXLim) * [1 1],[0 maxPSTH*1.1],'r:','LineWidth',2);
        
        % Annotating temporal slice windows
        for sliceN = 1:size(temporal_Slice,1)
            if temporal_Slice{sliceN,3} == align_markers(j)
                p_ = patch([temporal_Slice{sliceN,1} temporal_Slice{sliceN,1} temporal_Slice{sliceN,2} temporal_Slice{sliceN,2}],[0 maxPSTH*1.1 maxPSTH*1.1 0],temporal_Slice{sliceN,5});
                set(p_,'FaceAlpha',0.4,'EdgeAlpha',0);
                
            end
        end
        
    end
    % SetFigure
    
    set(gcf,'color','w');
    set(findall(gcf,'fontsize',10),'fontsize',6);
    set(findall(gcf,'tickdir','i'),'tickdir','o');
    
    % set(findall(gcf,'type','axes','linewidth',0.5),'linewidth',1);
    %     box off;
    
    if align_markers(j) == 4 % Vis On
        suptitle([FILE(1:end-4) '  Visual On (04)']);
    elseif align_markers(j) == 7 % Sac On
        suptitle([FILE(1:end-4) '   Saccade On (07)']);
    end
    
    FileNameTemp = num2str(FILE);
    FileNameTemp =  FileNameTemp(1:end-4);
    str = [FileNameTemp,'_Ch' num2str(SpikeChan)];
    ss = [str,'_DS_',num2str(j)];
    saveas(gcf,['Z:\LBY\Recording data\Qiaoqiao\Delay_saccade\' ss], 'emf');
    
end



% % Statistics
% figure(3); clf;
% set(3,'Position', [5,5 600,700], 'Name', 'PSTH','color','w');
%
% axis_plot = axes('Position',[0.05 0.05 0.9 0.6]);
% axis_typing = axes('Position',[0.05 0.66 0.9 0.27]);
%
% % The largest goes first in the polar plot
% [~, polarOrder] = sort(max(cell2mat(resp'),[],2),1,'descend');
%
% for sliceN = polarOrder(:)'
%
%     axes(axis_plot);
%     if strcmp(temporal_Slice{sliceN,5},''); continue; end
%
%     if p{sliceN} < 0.05
%         sigMarker = '-'; wid = 3;
%     else
%         sigMarker = ':'; wid = 1.5;
%     end;
%
%     polarwitherrorbar([unique_heading/180*pi; unique_heading(1)/180*pi], ...
%         [resp{sliceN}'; resp{sliceN}(1)], (p{sliceN} < 0.05) * [resp_err{sliceN}' ; resp_err{sliceN}(1)],[temporal_Slice{sliceN,5} sigMarker],wid);
%     hold on;
%
%     if p{sliceN} < 0.05
% %         h_p = polar([vectSum{sliceN} vectSum{sliceN}]/180*pi,[0 vectAmp{sliceN}],[temporal_Slice{sliceN,5} '-']);
%         h_p = polar([vectSum{sliceN} vectSum{sliceN}]/180*pi,[max(cell2mat(vectAmp))*0.8 max(cell2mat(vectAmp))*0.9],[temporal_Slice{sliceN,5} '-']);
%         set(h_p,'LineWidth',5);
%     end
% %
%     axes(axis_typing); axis off;
%     text(0.2,- sliceN * 0.15+1.1,sprintf('%s:  \\itp_ = %6.4g',temporal_Slice{sliceN,4},p{sliceN}),'color',temporal_Slice{sliceN,5},'FontSize',20 * (p{sliceN} < 0.05) + 10 * (p{sliceN} >= 0.05));
%
%
% end
%
% title(FILE);
%
% % SetFigure
% box off;
% set(gcf,'color','w');
% set(findall(gcf,'fontsize',10),'fontsize',15);
% set(findall(gcf,'tickdir','i'),'tickdir','o');
% set(findall(gcf,'type','axes','linewidth',0.5),'linewidth',2);
%
% fprintf('%g\t%g\t%g\t',p{:}, DDI{:},activityIndex{:});   % HH20130827
% fprintf('\n');
%
%
% %}
% aziToHeading = @(x)(mod(270-x,360)-180); % Transferred from azimuth to heading
%
%
% %}


% %%%%%%%%%%%%%%%%%%%%%%%  Output   HH20140510 / HH20140621 %%%%%%%%%%%%%%%%%
%
% if ~isempty(batch_flag)  % Figures
%
%     %%%%%%%%%%%%%%%%%%%%% Change here %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     suffix = ['MemSac'];
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
% sprint_once_marker_temp = 'gggg';
% sprint_once_contents = ['p{:}, aziToHeading(cell2mat(vectSum)), DDI{:},activityIndex{:}'];
% % Loop across each stim_type
% sprint_loop_marker_temp = '''''';
% sprint_loop_contents = '''''';
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
% unique_stim_type = 2;
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
%
% %%
% return;
