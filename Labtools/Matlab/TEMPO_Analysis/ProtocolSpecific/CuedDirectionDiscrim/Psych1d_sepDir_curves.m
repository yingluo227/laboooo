%-----------------------------------------------------------------------------------------------------------------------
%-- Psych1d_sepDir_curves.m -- Plots psychometric curve sorted by cue validity but collapsed across direction
%--	VR, 9/19/05
%-----------------------------------------------------------------------------------------------------------------------
function Psych1d_sepDir_curves(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

TEMPO_Defs;		
Path_Defs;
ProtocolDefs;	%needed for all protocol specific functions - contains keywords - BJP 1/4/01

%parameters for bootstrapping to get confidence intervals
nboot = 100;
alpha = .05;

%get the column of values of directions in the dots_params matrix
direction = data.dots_params(DOTS_DIREC,BegTrial:EndTrial,PATCH1);
unique_direction = munique(direction');
Pref_direction = data.one_time_params(PREFERRED_DIRECTION);
if unique_direction(1)~=Pref_direction
    unique_direction = [unique_direction(2) unique_direction(1)];
end
   
%get the motion coherences
coherence = data.dots_params(DOTS_COHER, BegTrial:EndTrial, PATCH1);
unique_coherence = munique(coherence');
signed_coherence = coherence.*(-1+2.*(direction==Pref_direction));
unique_signed_coherence = [-unique_coherence' unique_coherence'];

%get the cue validity: -1=Invalid; 0=Neutral; 1=Valid; 2=CueOnly
cue_val = data.cue_params(CUE_VALIDITY,BegTrial:EndTrial,PATCH2);
unique_cue_val = munique(cue_val');
cue_val_names = {'NoCue','Invalid','Neutral','Valid','CueOnly'};

%get the cue directions
cue_direc = data.cue_params(CUE_DIREC, BegTrial:EndTrial, PATCH1);
cue_direc = squeeze_angle(cue_direc);
unique_cue_direc = munique(cue_direc');

%compute cue types - 0=neutral, 1=directional, 2=cue_only
cue_type = abs(cue_val); %note that invalid(-1) and valid(+1) are directional
unique_cue_type = munique(cue_type');

%classifies each trial based on the cue direction: 1=PrefDir, -1=NullDir, 0=Neutral, 2=CueOnly (both cue directions)
cue_dir_type = cue_val;
for i=1:length(cue_dir_type)
    if abs(cue_dir_type(i))==1
        cue_dir_type(i) = -1+2*(squeeze_angle(Pref_direction)==squeeze_angle(cue_direc(i)));
    end
end
unique_cue_dir_type = munique(cue_dir_type');
cue_dir_type_names = {'NoCue','NullDir','Neutral','PrefDir','CueOnly'};
cue_dir_type_names2 = {'NoCue','Nc','Neu','Pc','CueOnly'};

%get the firing rates for all the trials
spike_rates = data.spike_rates(SpikeChan, :);

%get outcome for each trial: 0=incorrect, 1=correct
trials_outcomes = logical (data.misc_params(OUTCOME,BegTrial:EndTrial) == CORRECT);

%get indices of any NULL conditions (for measuring spontaneous activity)
null_trials = logical( (coherence == data.one_time_params(NULL_VALUE)) );

%now, select trials that fall between BegTrial and EndTrial
trials = 1:length(coherence);
%a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

OPTIONS = OPTIMSET('MaxIter', 1000000,'MaxFunEvals',200000);

TempMarkers = {'bo','r*','g>','rd','g<','g>'};
TempLines = {'b-','r:','g-','r:','g-','g:'};
TempShamLines = {'bo-','r*--','g>:','rd:','g<-','g>:'};
TempColors = {'b','b','r','r','g','g'};
NeuroMarkers = TempMarkers;
NeuroLines = TempLines;
NeuroShamLines = TempShamLines;
NeuroColors = TempColors;
PsychoMarkers = TempMarkers;
PsychoMarkers2 = {'bo','r*','g>','r*','go','g*'};
PsychoLines = TempLines;
PsychoLines2 = {'b-','r--','g:'};
PsychoShamLines = TempShamLines;
PsychoShamLines2 = {'bo-' 'r*--', 'g>:'};
names = {'NoCue','NullDir','Neutral','PrefDir','CueOnly'};

hlist=figure; 
set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Psychometric Function',FILE));
subplot(3, 1, 2); hold on;

% %% ********* NEUROMETRIC ANALYSIS ********************
% %loop through each coherence level per cue val, and do ROC analysis for each
% ROC_values = []; N_obs = []; neuron_bootlog_CI = [];
% neuron_legend_str = '';
% tic
% 
% for j=1:sum(unique_cue_dir_type~=2) %exclude CueOnly condition from plot
% %     for i=1:length(unique_coherence)
% %         CORRECT_FOR_SLOW_SPIKE_RATE_CHANGE = 0;
% %         if (CORRECT_FOR_SLOW_SPIKE_RATE_CHANGE)
% %             %Do a regression of spike rates against trial number for each coherence.
% %             trial_temp = trials((coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(j)) & select_trials);
% %             trial_temp = [trial_temp; ones(1,length(trial_temp))];
% %             spike_temp = spike_rates((coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(j)) & select_trials);
% %             [b, bint, r, rint, stats] = regress(spike_temp', trial_temp');
% %             spike_rates((coherence == unique_coherence(i)) & select_trials) = r';
% %         end
% %         pref_trials = ( (direction == Pref_direction) & (coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(j)) );
% %         pref_dist{i} = spike_rates(pref_trials & select_trials);
% %         null_trials = ( (direction ~= Pref_direction) & (coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(j)) );
% %         null_dist{i} = spike_rates(null_trials & select_trials);
% %         ROC_values{j}(i) = rocN(pref_dist{i}, null_dist{i}, 100);
% %         N_obs{j}(i) = length(pref_dist{i}) + length(null_dist{i});
% %         
% %         %data for logistic fit - For negative coherences, i'm using 1-ROC(coher); this unfortunately enforces symmetry
% %         fit_neuron_data{j}(i,1) = -unique_coherence(i);
% %         fit_neuron_data{j}(i+length(unique_coherence),1) = unique_coherence(i);
% %         fit_neuron_data{j}(i,2) = 1-ROC_values{j}(i);
% %         fit_neuron_data{j}(i+length(unique_coherence),2) = ROC_values{j}(i);
% %         fit_neuron_data{j}(i,3) = N_obs{j}(i);
% %         fit_neuron_data{j}(i+length(unique_coherence),3) = N_obs{j}(i);
% %     end
%     for i=1:length(unique_signed_coherence)
%         CORRECT_FOR_SLOW_SPIKE_RATE_CHANGE = 0;
%         if (CORRECT_FOR_SLOW_SPIKE_RATE_CHANGE)
%             %Do a regression of spike rates against trial number for each coherence.
%             trial_temp = trials((coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(j)) & select_trials);
%             trial_temp = [trial_temp; ones(1,length(trial_temp))];
%             spike_temp = spike_rates((coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(j)) & select_trials);
%             [b, bint, r, rint, stats] = regress(spike_temp', trial_temp');
%             spike_rates((coherence == unique_coherence(i)) & select_trials) = r';
%         end
%         %compare the firing rates for all non-zero signed-coherences with the
%         %firing rates on 0% coherent trials.
%         if unique_signed_coherence(i)~=0
%             var_trials = ( (signed_coherence == unique_signed_coherence(i)) & (cue_dir_type == unique_cue_dir_type(j)) );
%             var_dist{i} = spike_rates(var_trials & select_trials);
%             ctrl_trials = ( (coherence == 0) & (cue_dir_type == unique_cue_dir_type(j)) );
%             ctrl_dist{i} = spike_rates(ctrl_trials & select_trials);
%             ROC_values{j}(i) = rocN(var_dist{i}, ctrl_dist{i}, 100);
%             N_obs{j}(i) = length(var_dist{i}) + length(ctrl_dist{i});
%             %data for logistic fit
%             fit_neuron_data{j}(i,1) = unique_signed_coherence(i);
%             fit_neuron_data{j}(i,2) = ROC_values{j}(i);
%             fit_neuron_data{j}(i,3) = N_obs{j}(i);
%         end
%     end
%     
%     %Plot stuff
%     plot(fit_neuron_data{j}(:,1), fit_neuron_data{j}(:,2), NeuroMarkers{j}, 'MarkerFaceColor', NeuroColors{j});
%     %plot([unique_bin_corr(1) unique_bin_corr(length(unique_bin_corr))],[0.5 0.5], 'k-.');   %make a line across the plot at y=0.5
%     
%     [neuron_alpha(j) neuron_beta(j)] = logistic_fit(fit_neuron_data{j});
%     neuron_thresh(j) = get_logistic_threshold([neuron_alpha(j) neuron_beta(j)]);
%     fit_x = -max(unique_coherence):0.1:max(unique_coherence);
%     neuron_fit_y{j} = logistic_curve(fit_x, [neuron_alpha(j) neuron_beta(j)]);
%     plot(fit_x, neuron_fit_y{j}, NeuroLines{j});
%     n_Handl(j)=plot([-1 1],[-1 -1],NeuroShamLines{j},'MarkerFaceColor',NeuroColors{j}); %note this won't appear on plot
%     YLim([0 1]);
%     neuron_legend_str = strcat(neuron_legend_str,',''Neuron:',cue_dir_type_names{unique_cue_dir_type(j)+3},'''');
%     
%     %Bootstrap to generate new roc values for each coherence to generate logistic thresholds
%     boot_roc = [];
%     for i = 1:nboot
%         for k = 1:length(unique_signed_coherence)
%             if unique_signed_coherence(k)~=0
%                 var_select_boot{j,i,k} = find( select_trials & (cue_dir_type == unique_cue_dir_type(j)) & ...
%                     (signed_coherence == unique_signed_coherence(k)) );
%                 ctrl_select_boot{j,i,k} = find( select_trials & (cue_dir_type == unique_cue_dir_type(j)) & (signed_coherence == 0) );
%                 for m = 1:length(var_select_boot{j,i,k})
%                     var_boot_shuffle = var_select_boot{j,i,k}(randperm(length(var_select_boot{j,i,k})));
%                     var_boot{j,i,k}(m) = var_boot_shuffle(1);
%                 end
%                 for m = 1:length(ctrl_select_boot{j,i,k})
%                     ctrl_boot_shuffle = ctrl_select_boot{j,i,k}(randperm(length(ctrl_select_boot{j,i,k})));
%                     ctrl_boot{j,i,k}(m) = ctrl_boot_shuffle(1);
%                 end
%                 boot_roc(i,k) = rocN(spike_rates(var_boot{j,i,k}), spike_rates(ctrl_boot{j,i,k}), 100);
%                 n_obs(i,k) = length(var_boot{j,i,k})+length(ctrl_boot{j,i,k});
%             end
%         end
%         [neuron_bootlog_params{j,i}(1) neuron_bootlog_params{j,i}(2)] = logistic_fit([unique_signed_coherence' boot_roc(i,:)' n_obs(i,:)']);
%         neuron_bootlog_thresh(j,i) = get_logistic_threshold(neuron_bootlog_params{j,i}); 
%         neuron_bootlog_bias(j,i) = neuron_bootlog_params{j,i}(2);
% 
%     end
%     %now compute confidence intervals
%     sorted_thresh = sort(neuron_bootlog_thresh(j,:));
%     neuron_bootlog_CI(j,:) = [sorted_thresh(floor( nboot*alpha/2 )) ...
%         sorted_thresh(ceil( nboot*(1-alpha/2) ))];
%     sorted_bias = sort(neuron_bootlog_bias(j,:));
%     neuron_bootlog_bias_CI(j,:) = [sorted_bias(floor( nboot*alpha/2 )) ...
%         sorted_bias(ceil( nboot*(1-alpha/2) ))];
%     
% end
% 
% xlabel('Coherence x Direction');
% ylabel(sprintf('Fraction Choices in\nPreferred Direction'));
% neuron_legend_str = strcat('legend(n_Handl',neuron_legend_str, ', ''Location'', ''SouthEast'');');
% eval(neuron_legend_str); legend(gca,'boxoff');
% 
% toc

%%% ********* PSYCHOMETRIC ANALYSIS - FOLDED ********************

pct_correct = []; n_obs = []; fold_fit_data = []; monkey_fold_legend_str='';
subplot(312); hold on;
ind = 0; %counter for markers and lines
for i=1:sum(unique_cue_val~=2)
    %first get pct correct across appropriate trial types
    for j=1:length(unique_coherence)
        ok_values = logical( (coherence == unique_coherence(j)) & (cue_val == unique_cue_val(i)) );
        pct_correct(i,j) = sum(ok_values & trials_outcomes)/sum(ok_values);
    end
    ind = ind+1;
    %now plot the raw data
    plot(unique_coherence,squeeze(pct_correct(i,:)),PsychoMarkers2{ind});

    %now fit the raw data from both directions to a logistic function and plot the fits
    n_obs = sum(cue_val == unique_cue_val(i))./length(unique_coherence).*ones(length(unique_coherence),1);
    [monkey_fold_alpha(i) monkey_fold_beta(i)] = logistic_fit([unique_coherence squeeze(pct_correct(i,:))' n_obs]);
    fold_fit_x = [min(xlim):.1:max(xlim)];
    fold_fit_data(i,:) = logistic_curve(fold_fit_x, [monkey_fold_alpha(i),monkey_fold_beta(i)]);
    zero_pct_correct(i) = fold_fit_data(i,1); %performance at 0% coherence
    monkey_fold_thresh(i) = get_logistic_threshold([monkey_fold_alpha(i) monkey_fold_beta(i)]);
    plot(fold_fit_x, fold_fit_data(i,:), PsychoLines2{i});
    fold_handl(i) = plot([0 1], [-i -i], PsychoShamLines{i});
    monkey_fold_legend_str = strcat(monkey_fold_legend_str,',''',cue_val_names{unique_cue_val(i)+3},'''');
end
% for i=1:sum(unique_cue_val~=2)
%     for j=1:length(unique_direction)
%         %first get pct correct across appropriate trial types
%         for k=1:length(unique_coherence)
%             ok_values = logical( (direction == unique_direction(j)) & (coherence == unique_coherence(k)) ...
%                 & (cue_val == unique_cue_val(i)) );
%             pct_correct(i,j,k) = sum(ok_values & trials_outcomes)/sum(ok_values);
%         end
%         ind = ind+1;
%         %now plot the raw data
%         plot(unique_coherence,squeeze(pct_correct(i,j,:)),PsychoMarkers2{ind});
%     end
%     %now fit the raw data from both directions to a logistic function and plot the fits
%     n_obs = sum(cue_val == unique_cue_val(i))./length(unique_direction)./length(unique_coherence).*ones(2*length(unique_coherence),1);
%     [monkey_fold_alpha(i) monkey_fold_beta(i)] = logistic_fit([[unique_coherence; unique_coherence] [squeeze(pct_correct(i,1,:)); squeeze(pct_correct(i,2,:))] n_obs]);
%     fit_x = [min(xlim):1:max(xlim)];
%     fit_data{i} = logistic_curve(fit_x, [monkey_fold_alpha(i),monkey_fold_beta(i)]);
%     zero_pct_correct(i) = fit_data{i}(1); %performance at 0% coherence
%     fold_handl(i) = plot(fit_x, fit_data{i}, PsychoLines2{i});
%     monkey_fold_legend_str = strcat(monkey_fold_legend_str,',''M:',cue_val_names{unique_cue_val(i)+3},'''');
% end

xlabel('Coherence (%)');
ylabel('Percent Correct');
ylim([0 1]);
monkey_fold_legend_str = strcat('legend(fold_handl',monkey_fold_legend_str, ', ''Location'', ''SouthEast'');'); 
eval(monkey_fold_legend_str); legend(gca,'boxoff');
    
% keyboard;

%BOOTSTRAP to get 95%CI around zero_pct_correct
%note that in this bootstrap i'm going to combine the data from both directions.
for i=1:sum(unique_cue_val~=2)
    for j=1:nboot
        for k = 1:length(unique_coherence)
            select_boot{i,j,k} = logical( (cue_val == unique_cue_val(i)) & (coherence == unique_coherence(k)) );
            behav_select{i,j,k} = trials_outcomes(select_boot{i,j,k});
            for m = 1:length(behav_select)    %loop to generate bootstrap
                boot_shuffle = behav_select{i,j,k}(randperm(length(behav_select{i,j,k})));
                boot_outcomes{i,j,k}(m) = boot_shuffle(1);
            end
            boot_pct(j,k) = sum(boot_outcomes{i,j,k})./length(boot_outcomes{i,j,k});
            n_obs(j,k) = length(boot_outcomes{i,j,k});
        end
        [fold_bootlog_params{i,j}(1) fold_bootlog_params{i,j}(2)] = logistic_fit([unique_coherence boot_pct(j,:)' n_obs(j,:)']);
        boot_zero_pct_correct(i,j) = logistic_curve([0],fold_bootlog_params{i,j});
    end
    %now compute confidence intervals
    sorted_zpc = sort(boot_zero_pct_correct(i,:));
    fold_bootzpc_CI(i,:) = [sorted_zpc(floor( nboot*alpha/2 )) sorted_zpc(ceil( nboot*(1-alpha/2) ))];
end

%now do glm to look for significant interactions of coherence and validity
i=1; %compute parameters for all three cue direction types
yy{i}=[]; count=1;
for j = 1:length(unique_coherence)
    for k = 1:sum(unique_cue_val~=2)
        yy{i}(count,1) = unique_coherence(j);
        yy{i}(count,2) = unique_cue_val(k);
        yy{i}(count,3) = sum(trials_outcomes & (coherence == unique_coherence(j)) & (cue_val == unique_cue_val(k)) );  % # correct decisions
        yy{i}(count,4) = sum((coherence == unique_coherence(j)) & (cue_val == unique_cue_val(k)) ); % # trials
        count = count + 1;
    end
end
[fold_b{i}, fold_dev(i), fold_stats{i}] = glmfit([yy{i}(:,1) yy{i}(:,2) yy{i}(:,1).*yy{i}(:,2)],[yy{i}(:,3) yy{i}(:,4)],'binomial');
i = i+1;
[fold_b{i}, fold_dev(i), fold_stats{i}] = glmfit([yy{i-1}(:,1) yy{i-1}(:,2)],[yy{i-1}(:,3) yy{i-1}(:,4)],'binomial');
fold_anodev_test = 1-chi2cdf(fold_dev(i)-fold_dev(i-1),1);
%P_p_bias(i) = fold_stats{i}.p(3);  % P value for bias
%P_p_slope(i) = fold_stats{i}.p(4);	% P value for slope - well, an interaction between validity and signed_coherence

% keyboard

%%% ********* PSYCHOMETRIC ANALYSIS - UNFOLDED ********************

pct_pd = []; N_obs = []; fit_data = [];
monkey_bootlog_CI = []; monkey_legend_str = '';
subplot(3,1,3); hold on;
%this computes the percent of responses in the preferred direction
%combining across redundant conditions within each cue validity.
for i=1:sum(unique_cue_dir_type~=2)
    ind = 0;
    for j=length(unique_direction):-1:1
        for k=1:length(unique_coherence)
%             ind = k + (j-1)*length(unique_coherence);
            ind = ind+1;
            ok_values = logical( (direction == unique_direction(j)) & (coherence == unique_coherence(k)) ...
                & (cue_dir_type == unique_cue_dir_type(i)) & select_trials );
            pct_pd(i,ind) = sum(ok_values & trials_outcomes)/sum(ok_values);
            if (unique_direction(j) ~= Pref_direction)
                pct_pd(i,ind) = 1-pct_pd(i,ind);
            end
        end
    end
    plot(unique_signed_coherence, pct_pd(i,:), PsychoMarkers2{i});
end

% %plot the raw data
% for i=1:sum(unique_cue_dir_type~=2) %loop through cue val
%     [sorted_coherence{i}, I{i}] = sort(unique_signed_coherence);
%     plot(sorted_coherence{i}, pct_pd(i,I{i}), PsychoMarkers2{i});
% end
%keyboard
%now fit these data to logistic function and plot fits
for i=1:sum(unique_cue_dir_type~=2)
    n_obs = sum((cue_dir_type == unique_cue_dir_type(i)))./length(unique_coherence).*ones(size(unique_signed_coherence));
    [monkey2_alpha(i) monkey2_beta(i)] = logistic_fit([unique_signed_coherence' pct_pd(i,:)' n_obs']);
    monkey_thresh(i) = get_logistic_threshold([monkey2_alpha(i) monkey2_beta(i)]);
    str = sprintf('%s cue: alpha(slope) = %5.3f, beta(bias) = %5.3f', cue_dir_type_names{unique_cue_dir_type(i)+3}, monkey2_alpha(i), monkey2_beta(i));
    unfold_fit_x = [min(xlim):0.2:max(xlim)];
    unfold_fit_data(i,:) = logistic_curve(unfold_fit_x,[monkey2_alpha(i) monkey2_beta(i)]);
    plot(unfold_fit_x, unfold_fit_data(i,:), PsychoLines2{i});
    m_Handl(i) = plot([-1 1], [-1 -1], PsychoShamLines{i});
    monkey_legend_str = strcat(monkey_legend_str,',''',cue_dir_type_names{unique_cue_dir_type(i)+3},'''');
end

xlabel('Coherence x Direction');
ylabel(sprintf('Fraction Choices in\nPreferred Direction'));
monkey_legend_str = strcat('legend(m_Handl',monkey_legend_str, ', ''Location'', ''SouthEast'');');
eval(monkey_legend_str); legend(gca,'boxoff');
ylim([0 1]);

subplot(312); eval(monkey_fold_legend_str); legend(gca, 'boxoff');

% keyboard
% pct_pd = []; n_obs = []; fit_data = [];
% monkey_bootlog_CI = []; monkey_legend_str = '';
% subplot(313); hold on;
% %this computes the percent of responses in the preferred direction
% %combining across redundant conditions within each cue validity.
% for i=1:sum(unique_cue_dir_type~=2)
%     for j=1:length(unique_direction)
%         n_obs = [];
%         for k=1:length(unique_coherence)
%             ok_values = logical( (direction == unique_direction(j)) & (coherence == unique_coherence(k)) ...
%                 & (cue_dir_type == unique_cue_dir_type(i)) );
%             pct_pd(i,j,k) = sum(ok_values & (data.misc_params(OUTCOME, BegTrial:EndTrial) == CORRECT))/sum(ok_values);
%             if (unique_direction(j) ~= Pref_direction)
%                 pct_pd(i,j,k) = 1-pct_pd(i,j,k);
%             end
%             n_obs = [n_obs; sum(ok_values)];
%         end
%         %plot the raw data
%         plot(unique_coherence.*2.*((unique_direction(j)==Pref_direction)-0.5), squeeze(pct_pd(i,j,:)),PsychoMarkers{(i-1)*length(unique_direction)+j});
%         %now fit these data to logistic functions and plot fits
%         %n_obs = sum((cue_dir_type == unique_cue_dir_type(i))&(direction == unique_direction(j)))./length(unique_coherence).*ones(size(unique_coherence));
%         [monkey_alpha(i,j) monkey_beta(i,j)] = logistic_fit([unique_coherence.*2.*((unique_direction(j)==Pref_direction)-0.5)  squeeze(pct_pd(i,j,:)) n_obs]);
%         monkey_thresh(i,j) = get_logistic_threshold([monkey_alpha(i,j) monkey_beta(i,j)]);
%         if (unique_direction(j) == Pref_direction)
%             plot([0:1:max(xlim)],logistic_curve([0:1:max(xlim)],[monkey_alpha(i,j) monkey_beta(i,j)]), PsychoLines{(i-1)*length(unique_direction)+j});
%             dirstr = 'PrSt';
%         else
%             plot([-max(xlim):1:0],logistic_curve([-max(xlim):1:0],[monkey_alpha(i,j) monkey_beta(i,j)]), PsychoLines{(i-1)*length(unique_direction)+j});
%             dirstr = 'NuSt';
%         end
%         m_Handl((i-1)*length(unique_direction)+j) = plot([-1 1], [-1 -1], PsychoShamLines{(i-1)*length(unique_direction)+j});
%         monkey_legend_str = strcat(monkey_legend_str,',''M:',cue_dir_type_names2{unique_cue_dir_type(i)+3},dirstr,'''');
% %         keyboard
%     end
% end

% %plot the raw data
% for i=1:sum(unique_cue_dir_type~=2) %loop through cue val
%     for j=1:length(unique_direction)
%         plot(unique_coherence,pct_pd(i,j,:),PsychoMarkers{i});
%     end
% end
% %keyboard
% %now fit these data to logistic function and plot fits
% for i=1:sum(unique_cue_dir_type~=2)
%     n_obs = sum(select_trials & (cue_dir_type == unique_cue_dir_type(i)))./length(unique_coherence).*ones(size(sorted_coherence{i}));
%     [monkey_alpha(i) monkey_beta(i)] = logistic_fit([sorted_coherence{i}' pct_pd(i,I{i})' n_obs']);
%     monkey_thresh(i) = get_logistic_threshold([monkey_alpha(i) monkey_beta(i)]);
%     str = sprintf('%s cue: alpha(slope) = %5.3f, beta(bias) = %5.3f', cue_dir_type_names{unique_cue_dir_type(i)+3}, monkey_alpha(i), monkey_beta(i));
%     plot([min(xlim):1:max(xlim)],logistic_curve([min(xlim):1:max(xlim)],[monkey_alpha(i) monkey_beta(i)]), PsychoLines{i});
%     m_Handl(i) = plot([-1 1], [-1 -1], PsychoShamLines{i});
%     monkey_legend_str = strcat(monkey_legend_str,',''Monkey:',cue_dir_type_names{unique_cue_dir_type(i)+3},'''');
% end
% 
% xlabel('Coherence x Direction');
% ylabel(sprintf('Fraction Choices in\nPreferred Direction'));
% monkey_legend_str = strcat('legend(m_Handl',monkey_legend_str, ', ''Location'', ''NorthWest'');');
% eval(monkey_legend_str); legend(gca,'boxoff','FontSize',6);
% ylim([0 1]);

% keyboard
% 
% % Bootstrap to get 95%CI around threshold behavior 
% boot_outcomes = []; 
% for i=1:sum(unique_cue_dir_type~=2) %exclude CueOnly condition from plot
%     for j=1:nboot
%         for k = 1:length(unique_signed_coherence)
%             if (k <= length(unique_signed_coherence)/2) %get direction
%                 direc = Pref_direction - 180;
%             else
%                 direc = Pref_direction;
%             end
%             select_boot{i,j,k} = logical( select_trials & (cue_dir_type == unique_cue_dir_type(i)) & ...
%                 (signed_coherence == unique_signed_coherence(k)) );
%             behav_select{i,j,k} = trials_outcomes(select_boot{i,j,k});
%             for m = 1:length(behav_select)    %loop to generate bootstrap
%                 boot_shuffle = behav_select{i,j,k}(randperm(length(behav_select{i,j,k})));
%                 boot_outcomes{i,j,k}(m) = boot_shuffle(1);
%             end
%             boot_pct(j,k) = sum(boot_outcomes{i,j,k})./length(boot_outcomes{i,j,k});
%             if (direc ~= Pref_direction) %for null use 1-ROC
%                 boot_pct(j,k) = 1-boot_pct(j,k);
%             end
%             n_obs(j,k) = length(boot_outcomes{i,j,k});
%         end
%         [monkey_bootlog_params{i,j}(1) monkey_bootlog_params{i,j}(2)] = logistic_fit([unique_signed_coherence' boot_pct(j,:)' n_obs(j,:)']);
%         monkey_bootlog_thresh(i,j) = get_logistic_threshold(monkey_bootlog_params{i,j});
%         monkey_bootlog_bias(i,j) = monkey_bootlog_params{i,j}(2);
%     end
%     %now compute confidence intervals
%     sorted_thresh = sort(monkey_bootlog_thresh(i,:));
%     monkey_bootlog_CI(i,:) = [sorted_thresh(floor( nboot*alpha/2 )) ...
%             sorted_thresh(ceil( nboot*(1-alpha/2) ))];
%     sorted_bias = sort(monkey_bootlog_bias(i,:));
%     monkey_bootlog_bias_CI(i,:) = [sorted_bias(floor( nboot*alpha/2 )) ...
%         sorted_bias(ceil( nboot*(1-alpha/2) ))];
% end
% 
% %for each combination of validities, use glm to find whether there is a
% %significant interaction of cue_validity and coherence
% %note that matlab's logistic uses a slightly different parameterization than the one in logistic_func
% cuedir_combo = [ 1 0; 1 -1; 0 -1 ];
% for i = 1:size(cuedir_combo,1)
%     yy{i}=[];
%     count = 1;
%     pref_choices = trials_outcomes;
%     pref_choices(direction~=Pref_direction) = 1-pref_choices(direction~=Pref_direction);
%     for j = 1:length(unique_signed_coherence)
%         for k = 1:length(cuedir_combo(i,:))
%             yy{i}(count,1) = unique_signed_coherence(j);
%             yy{i}(count,2) = cuedir_combo(i,k);
%             yy{i}(count,3) = sum((pref_choices == 1) & (signed_coherence == unique_signed_coherence(j)) & (cue_dir_type == cuedir_combo(i,k)) & select_trials);  % # preferred decisions
%             yy{i}(count,4) = sum((signed_coherence == unique_signed_coherence(j)) & (cue_dir_type == cuedir_combo(i,k)) & select_trials);		% # trials
%             count = count + 1;
%         end
%     end
%     [p_b(i,:), p_dev(i), p_stats{i}] = glmfit([yy{i}(:,1) yy{i}(:,2) yy{i}(:,1).*yy{i}(:,2)],[yy{i}(:,3) yy{i}(:,4)],'binomial');
%     P_p_bias(i) = p_stats{i}.p(3);  % P value for bias
%     P_p_slope(i) = p_stats{i}.p(4);	% P value for slope - well, an interaction between validity and signed_coherence
% end
% i=i+1; %now compute parameters for all three cue direction types
% yy{i}=[]; count=1;
% for j = 1:length(unique_signed_coherence)
%     for k = 1:sum(unique_cue_dir_type~=2)
%         yy{i}(count,1) = unique_signed_coherence(j);
%         yy{i}(count,2) = unique_cue_dir_type(k);
%         yy{i}(count,3) = sum((pref_choices == 1) & (signed_coherence == unique_signed_coherence(j)) & (cue_dir_type == unique_cue_dir_type(k)) & select_trials);  % # preferred decisions
%         yy{i}(count,4) = sum((signed_coherence == unique_signed_coherence(j)) & (cue_dir_type == unique_cue_dir_type(k)) & select_trials); % # trials
%         count = count + 1;
%     end
% end
% [p_b(i,:), p_dev(i), p_stats{i}] = glmfit([yy{i}(:,1) yy{i}(:,2) yy{i}(:,1).*yy{i}(:,2)],[yy{i}(:,3) yy{i}(:,4)],'binomial');
% P_p_bias(i) = p_stats{i}.p(3);  % P value for bias
% P_p_slope(i) = p_stats{i}.p(4);	% P value for slope - well, an interaction between validity and signed_coherence

%now perform glm analysis on validity-sorted unfolded psych data 
pref_choices = trials_outcomes;
pref_choices(direction~=Pref_direction) = 1-pref_choices(direction~=Pref_direction);
cueval_combo = [ 1 0; 1 -1; 0 -1 ];
for i = 1:size(cueval_combo,1)
    yy{i}=[];
    count = 1;
    for j = 1:length(unique_signed_coherence)
        for k = 1:length(cueval_combo(i,:))
            yy{i}(count,1) = unique_signed_coherence(j);
            yy{i}(count,2) = cueval_combo(i,k);
            yy{i}(count,3) = sum((pref_choices == 1) & (signed_coherence == unique_signed_coherence(j)) & (cue_val == cueval_combo(i,k)) & select_trials);  % # preferred decisions
            yy{i}(count,4) = sum((signed_coherence == unique_signed_coherence(j)) & (cue_val == cueval_combo(i,k)) & select_trials);		% # trials
            count = count + 1;
        end
    end
    [p_b(i,:), p_dev(i), p_stats{i}] = glmfit([yy{i}(:,1) yy{i}(:,2) yy{i}(:,1).*yy{i}(:,2)],[yy{i}(:,3) yy{i}(:,4)],'binomial');
    unfolded_val_p_bias(i) = p_stats{i}.p(3);  % P value for bias
    unfolded_val_p_slope(i) = p_stats{i}.p(4);	% P value for slope - well, an interaction between validity and signed_coherence
end
i=4;
yy{i}=[]; count=1;
for j = 1:length(unique_signed_coherence)
    for k = 1:sum(unique_cue_val~=2)
        yy{i}(count,1) = unique_signed_coherence(j);
        yy{i}(count,2) = unique_cue_val(k);
        yy{i}(count,3) = sum((pref_choices == 1) & (signed_coherence == unique_signed_coherence(j)) & (cue_val == unique_cue_val(k)) & select_trials);  % # preferred decisions
        yy{i}(count,4) = sum((signed_coherence == unique_signed_coherence(j)) & (cue_val == unique_cue_val(k)) & select_trials); % # trials
        count = count + 1;
    end
end
[p_b(i,:), p_dev(i), p_stats{i}] = glmfit([yy{i}(:,1) yy{i}(:,2) yy{i}(:,1).*yy{i}(:,2)],[yy{i}(:,3) yy{i}(:,4)],'binomial');
unfolded_val_p_bias(i) = p_stats{i}.p(3);  % P value for bias
unfolded_val_p_slope(i) = p_stats{i}.p(4);	% P value for slope - well, an interaction between validity and signed_coherence



%compute fraction correct on cue_only trials
cue_only_trials = (cue_val==2);
cue_only_correct = (cue_only_trials & trials_outcomes );
cue_only_pct_corr = sum(cue_only_correct)/sum(cue_only_trials);

for i = 1:length(unique_cue_val)
    validity_pct_correct(i) = sum(trials_outcomes(cue_dir_type(select_trials)==unique_cue_dir_type(i))) ./ sum(cue_dir_type(select_trials)==unique_cue_dir_type(i));
end
% 
% %classify cell as good-bad-ugly based only on slope p-values from glm fits
% cell_class_names = {'Good','Bad','Ugly','NoBehav'};
% GOOD=1; BAD=2; UGLY=3; NB=4;
% if ~sum(P_p_slope<.05) %if no significant differences in behavioral slopes
%     cell_class_sl = NB;
% elseif ~sum(P_n_slope<.05) %if no significant differences in neurometric slopes
%     cell_class_sl = BAD;
% else
%     diff_pairs = find( (P_p_slope<.05) & (P_n_slope<.05) ); %indices of comparisons with significant differences
%     if length(diff_pairs)==0  %when different comparisons show differences among neural and behavioral thresholds.
%         [dummy, ind_n] = sort(neuron_thresh);
%         [dummy, ind_p] = sort(monkey_thresh);
%         if isequal(ind_p,ind_n) %in this case, only call it good if the order of all 3 validities are the same for monkey/neuron
%             cell_class_sl = GOOD;
%         else
%             cell_class_sl = BAD;
%         end
%     else
%         cell_class_sl = GOOD; %default
%         for i = 1:length(diff_pairs)
%             cuedir1 = find(unique_cue_dir_type==cuedir_combo(i,1));
%             cuedir2 = find(unique_cue_dir_type==cuedir_combo(i,2));
%             n_threshes = [neuron_thresh(cuedir1) neuron_thresh(cuedir2)];
%             p_threshes = [monkey_thresh(cuedir1) monkey_thresh(cuedir2)];
%             if xor(n_threshes(1)>n_threshes(2),p_threshes(1)>p_threshes(2)) %if the bigger value does NOT belong to the same validity,
%                 cell_class_sl = UGLY;                                       %then call the cell ugly
%             end
%         end
%     end
% end
% cell_class_names{cell_class_sl};
% %classify cell as good-bad-ugly based on BIAS p-values from glm fits
% cell_class_names = {'Good','Bad','Ugly','NoBehav'};
% GOOD=1; BAD=2; UGLY=3; NB=4;
% if ~sum(P_p_bias<.05) %if no significant differences in behavioral slopes
%     cell_class_bi = NB;
% elseif ~sum(P_n_bias<.05) %if no significant differences in neurometric slopes
%     cell_class_bi = BAD;
% else
%     diff_pairs = find( (P_p_bias<.05) & (P_n_bias<.05) ); %indices of comparisons with significant differences
%     if length(diff_pairs)==0  %when different comparisons show differences among neural and behavioral thresholds.
%         [dummy, ind_n] = sort(neuron_beta);
%         [dummy, ind_p] = sort(monkey_beta);
%         if isequal(ind_p,ind_n) %in this case, only call it good if the order of all 3 validities are the same for monkey/neuron
%             cell_class_bi = GOOD;
%         else
%             cell_class_bi = BAD;
%         end
%     else
%         cell_class_bi = GOOD; %default
%         for i = 1:length(diff_pairs)
%             cuedir1 = find(unique_cue_dir_type==cuedir_combo(i,1));
%             cuedir2 = find(unique_cue_dir_type==cuedir_combo(i,2));
%             n_biases = [neuron_beta(cuedir1) neuron_beta(cuedir2)];
%             p_biases = [monkey_beta(cuedir1) monkey_beta(cuedir2)];
%             if xor(n_biases(1)>n_biases(2),p_biases(1)>p_biases(2)) %if the bigger value does NOT belong to the same validity,
%                 cell_class_bi = UGLY;                                       %then call the cell ugly
%             end
%         end
%     end
% end
% cell_class_names{cell_class_bi};
% keyboard;

%% ********************** PRINT INFO *****************************
%now, print out some useful information in the upper subplot
subplot(3, 1, 1);
PrintGeneralData(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);


%now, print out some specific useful info.
xpos = -10; ypos = 25;
font_size = 8;
bump_size = 6;
for j = 1:sum(unique_cue_val~=2)
    line = sprintf('CueStatus = %s, alpha = %6.2f, beta = %6.2f%%', ...
        cue_val_names{unique_cue_val(j)+3}, monkey_fold_alpha(j), monkey_fold_beta(j) );
    text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
    line = sprintf('   Zero coher pct corr: %6.2f [%6.2f,%6.2f]',...
        100.*zero_pct_correct(j), 100.*fold_bootzpc_CI(j,:) );
    text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
end
line = sprintf('Analysis of Deviance: p=%6.4f',fold_anodev_test);
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('  Full model p\_vals: %6.4f, %6.4f, %6.4f, %6.4f', fold_stats{1}.p);
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('  Partial model p\_vals: %6.4f, %6.4f, %6.4f', fold_stats{2}.p);
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = sprintf(FILE);
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% for j = 1:sum(unique_cue_dir_type~=2)
% %     line = sprintf('Neuron: CueDir = %s, bias = %6.2f%%, thresh = %6.2f%%, %d%% CI = [%6.2f%% %6.2f%%]', ...
% %         cue_dir_type_names{unique_cue_dir_type(j)+3}, neuron_beta(j), neuron_thresh(j), 100*(1-alpha), neuron_bootlog_CI(j,1), neuron_bootlog_CI(j,2));
%     line = sprintf('Neuron: CueDir = %s, bias = %6.2f%% [%6.2f%%,%6.2f%%], thresh = %6.2f%% [%6.2f%%,%6.2f%%]', ...
%         cue_dir_type_names{unique_cue_dir_type(j)+3}, neuron_beta(j), neuron_bootlog_bias_CI(j,1), neuron_bootlog_bias_CI(j,2), neuron_thresh(j), neuron_bootlog_CI(j,1), neuron_bootlog_CI(j,2));
%     text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% end
% % line = sprintf('Monkey Thresholds:');
% % text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% for j = 1:sum(unique_cue_dir_type~=2)
% %     line = sprintf('Monkey: CueDir = %s, bias = %6.2f%%, thresh = %6.2f%%, %d%% CI = [%6.2f%% %6.2f%%]', ...
% %         cue_dir_type_names{unique_cue_dir_type(j)+3}, monkey_beta(j), monkey_thresh(j), 100*(1-alpha), monkey_bootlog_CI(j,1), monkey_bootlog_CI(j,2));
%     line = sprintf('Monkey: CueDir = %s, bias = %6.2f%% [%6.2f%%,%6.2f%%], thresh = %6.2f%% [%6.2f%%,%6.2f%%]', ...
%         cue_dir_type_names{unique_cue_dir_type(j)+3}, monkey_beta(j), monkey_bootlog_bias_CI(j,1), monkey_bootlog_bias_CI(j,2), monkey_thresh(j), monkey_bootlog_CI(j,1), monkey_bootlog_CI(j,2));
%     text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% end
% line = sprintf('Pct Correct:');
% for j = 1:length(unique_cue_val)
%     line = strcat(line, sprintf(' %s = %4.2f%%;',names{unique_cue_val(j)+3},pct_correct(j)*100));
% end
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('Directions tested: %6.3f, %6.3f deg', unique_direction(1), unique_direction(2) );
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
% line = pct_str;
% text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;


%compute unfolded RTs
for i = 1:length(trials)
    rt(i) = find(data.event_data(1,:,i)==SACCADE_BEGIN_CD) - find(data.event_data(1,:,i)==TARGS_ON_CD);
end
for i = 1:length(unique_signed_coherence)
    for k = 1:length(unique_cue_dir_type)
        if unique_cue_dir_type(k) == 2, select = select_trials & (cue_dir_type == 2); %kluge to combine across coher for cueonly 
        else, select = select_trials & (signed_coherence == unique_signed_coherence(i)) & (cue_dir_type == unique_cue_dir_type(k));
        end
        mean_rt(i,k) = mean(rt(select));
        std_rt(i,k) = std(rt(select));
    end
    select = select_trials & (signed_coherence == unique_signed_coherence(i));
    mean_rt(i,k+1) = nanmean(rt(select));
    std_rt(i,k+1) = nanstd(rt(select));
end
for i = 1:length(unique_coherence)
    for k = 1:length(unique_cue_dir_type)
        if unique_cue_dir_type(k) == 2, select = select_trials & (cue_dir_type == 2); %kluge to combine across coher for cueonly 
        else, select = select_trials & (coherence == unique_coherence(i)) & (cue_dir_type == unique_cue_dir_type(k));
        end
        unsigned_mean_rt(i,k) = mean(rt(select));
        unsigned_std_rt(i,k) = std(rt(select));
    end
    select = select_trials & (coherence == unique_coherence(i));
    unsigned_mean_rt(i,k+1) = nanmean(rt(select));
    unsigned_std_rt(i,k+1) = nanstd(rt(select));
end

output = 0; %folded fit data
output2 = 0; %unfolded validity-based glm data
output3 = 1; %unfolded cuedir based raw data
output4 = 0;

if (output)
    %------------------------------------------------------------------------
    %write out all relevant parameters to a cumulative text file, VR 11/21/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\Psycho_FoldedValidity_Curve_summary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t InvPct\t NeuPct\t ValPct\t CuePct\t 0%%Inv\t 0%%Neu\t 0%%Val\t 0%%InvCI\t\t 0%%NeuCI\t\t 0%%ValCI\t\t AnoDev\t F1p1\t F1p2\t F1p3\t F1p4\t F2p1\t F2p2\t F2p3\t InvAlpha\t InvBeta\t NeuAlpha\t NeuBeta\t ValAlpha\t ValBeta\t ');
%         fprintf(fid, 'FILE\t PrDir\t PrSpd\t PrHDsp\t RFX\t RFY\t RFDiam\t PdPct\t NeuPct\t NdPct\t CuePct\t P_PdTh\t P_NeuTh\t P_NdTh\t P_PdThCILo\t P_PdThCIHi\t P_NeuThCILo\t P_NeuThCIHi\t P_NdThCILo\t P_NdThCIHi\t P_PdSl\t P_PdBi\t P_PdBiCILo\t P_PdBiCIHi\t P_NeuSl\t P_NeuBi\t P_NeuBiCILo\t P_NeuBiCIHi\t P_NdSl\t P_NdBi\t P_NdBiCILo\t P_NdBiCIHi\t N_PdTh\t N_NeuTh\t N_NdTh\t N_PdThCILo\t N_PdThCIHi\t N_NeuThCILo\t N_NeuThCIHi\t N_NdThCILo\t N_NdThCIHi\t N_PdSl\t N_PdBi\t N_PdBiCILo\t N_PdBiCIHi\t N_NeuSl\t N_NeuBi\t N_NeuBiCILo\t N_NeuBiCIHi\t N_NdSl\t N_NdBi\t N_NdBiCILo\t N_NdBiCIHi\t MaxCoher\t Ntrials\t');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %6.1f\t %6.1f\t %6.1f\t %6.1f\t %6.1f\t %6.1f\t %6.1f\t %6.1f\t %6.1f\t %6.1f\t %6.1f\t %6.1f\t %6.1f\t %6.6f\t %6.6f\t %6.6f\t %6.6f\t %6.6f\t %6.6f\t %6.6f\t %6.6f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t ',...
        FILE, 100.*validity_pct_correct, 100.*zero_pct_correct, 100.*fold_bootzpc_CI', ...
        fold_anodev_test, fold_stats{1}.p, fold_stats{2}.p, [monkey_fold_alpha; monkey_fold_beta]);
%     pd = find(unique_cue_dir_type==1);  neu = find(unique_cue_dir_type==0);
%     nd = find(unique_cue_dir_type==-1); cue = find(unique_cue_dir_type==2);
%     buff = sprintf('%s\t %6.1f\t %6.2f\t %6.3f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.2f\t %6.1f\t %4d\t',...
%         FILE, data.neuron_params(PREFERRED_DIRECTION, 1), data.neuron_params(PREFERRED_SPEED, 1), data.neuron_params(PREFERRED_HDISP, 1), data.neuron_params(RF_XCTR, 1), data.neuron_params(RF_YCTR, 1), data.neuron_params(RF_DIAMETER, 1),...
%         pct_correct(pd)*100,pct_correct(neu)*100,pct_correct(nd)*100,pct_correct(cue)*100,...
%         monkey_thresh(pd),monkey_thresh(neu),monkey_thresh(nd), monkey_bootlog_CI(pd,1),monkey_bootlog_CI(pd,2),...
%         monkey_bootlog_CI(neu,1),monkey_bootlog_CI(neu,2),monkey_bootlog_CI(nd,1),monkey_bootlog_CI(nd,2),...
%         monkey_alpha(pd),monkey_beta(pd),monkey_bootlog_bias_CI(pd,1),monkey_bootlog_bias_CI(pd,2),...
%         monkey_alpha(neu),monkey_beta(neu),monkey_bootlog_bias_CI(neu,1),monkey_bootlog_bias_CI(neu,2),...
%         monkey_alpha(nd),monkey_beta(nd),monkey_bootlog_bias_CI(nd,1),monkey_bootlog_bias_CI(nd,2),...
%         neuron_thresh(pd),neuron_thresh(neu),neuron_thresh(nd), neuron_bootlog_CI(pd,1),neuron_bootlog_CI(pd,2),...
%         neuron_bootlog_CI(neu,1),neuron_bootlog_CI(neu,2),neuron_bootlog_CI(nd,1),neuron_bootlog_CI(nd,2),...
%         neuron_alpha(pd),neuron_beta(pd),neuron_bootlog_bias_CI(pd,1),neuron_bootlog_bias_CI(pd,2),...
%         neuron_alpha(neu),neuron_beta(neu),neuron_bootlog_bias_CI(neu,1),neuron_bootlog_bias_CI(neu,2),...
%         neuron_alpha(nd),neuron_beta(nd),neuron_bootlog_bias_CI(nd,1),neuron_bootlog_bias_CI(nd,2),...
%         max(unique_coherence),(1+EndTrial-BegTrial) );
%     %buff = sprintf('%s\t %6.1f\t %6.2f\t %6.3f\t %6.2f\t %6.2f\t %6.2f\t %6.3f\t %6.4f\t %6.3f\t %6.3f\t %4d\t %6.3f\t %5d\t', ...
    %    FILE, data.neuron_params(PREFERRED_DIRECTION, 1), data.neuron_params(PREFERRED_SPEED, 1), data.neuron_params(PREFERRED_HDISP, 1), data.neuron_params(RF_XCTR, 1), data.neuron_params(RF_YCTR, 1), data.neuron_params(RF_DIAMETER, 1),...
    %    monkey_alpha,monkey_beta,unique_direction(1), unique_direction(2), (1+ EndTrial - BegTrial), unique_coherence(length(unique_coherence)), stim_duration );
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
    %------------------------------------------------------------------------
end

if (output2)
    %------------------------------------------------------------------------
    %write out all relevant parameters to a cumulative text file, VR 11/21/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\Psycho_UnfoldedValidity_logreg.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t CueOnly\t uVN_pBi\t uVN_pSl\t uVI_pBi\t uVI_pSl\t uNI_pBi\t uNI_pSl\t uAll_pBi\t uAll_pSl');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %4.2f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t', ...
        FILE, cue_only_pct_corr, [unfolded_val_p_bias; unfolded_val_p_slope]);
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
    %------------------------------------------------------------------------
end

if output3
    savename = sprintf('Z:\\Data\\Tempo\\Baskin\\Analysis\\Unfolded-Psychophysics\\ShortDurDelayCells\\Psy2D-%s.txt',FILE);
    temp = [unique_signed_coherence' pct_pd'];
    temp = [mean([temp(1,:); temp(6,:)],1); temp([2:5,7:10],:)]'; 
    %the first row are the values of the signed coherence
    %the next 3 rows are the pct preferred direction chioces for null, neutral and pref dir cues respectively.
    %note that the two zero pct coherence conditions are averaged.  
    save(savename, 'temp', '-ascii'); 
    subplot(313);
    temp = [min(xlim):0.5:max(xlim)];
    save(savename, 'temp', '-ascii', '-append'); %this saves the x-values of the best fit logistic curves
    for i = 1:3
        temp = logistic_curve([min(xlim):.5:max(xlim)],[monkey2_alpha(i) monkey2_beta(i)]);
        save(savename, 'temp', '-ascii', '-append'); %this saves the three lines (one for each cuedir) of y-values of the best fit logistic curves
    end
    temp = monkey2_beta;
    save(savename, 'temp', '-ascii', '-append'); %this saves the bias parameter of the best fits
    temp = monkey_thresh;
    save(savename, 'temp', '-ascii', '-append'); %this saves the logistic thresholds of the best fits
end

if (output4)
    %------------------------------------------------------------------------
    %write out all relevant parameters to a cumulative text file, VR 11/21/05
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\lip_sdd_psychFoldUnfolded.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fid, 'FILE\t CueOnly\t uPr_Bi\t uNe_Bi\t uNl_Bi\t fVl_0x\t fNe_0x\t fNl_0x\t fVl_th\t fNe_th\t fNl_th\t');
        fprintf(fid, '\r\n');
        printflag = 0;
    end
    buff = sprintf('%s\t %4.2f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t %6.5f\t',...
        FILE, cue_only_pct_corr, monkey2_beta, zero_pct_correct, monkey_fold_thresh); 
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
    fclose(fid);
    %------------------------------------------------------------------------
end

order = [5:-1:1 7:10];
save_rt = 1;
if save_rt
    savename = sprintf('Z:\\Data\\Tempo\\Baskin\\Analysis\\CuedDirecDiscrim_Unfolded_RT\\ShortDurDelayCells\\RT-%s.txt',FILE(1:8));
    temp = unique_signed_coherence(order);
    save(savename, 'temp', '-ascii'); %this saves a row containing the values of unique_coherence
    temp = mean_rt(order,:)';
    save(savename, 'temp', '-ascii', '-append'); %this saves 5 lines - mean RT given signed coherence for null, neutral, pref, cueonly, and group avg
    temp = std_rt(order,:)';
    save(savename, 'temp', '-ascii', '-append'); %this saves 5 lines - std RT given signed coherence for null, neutral, pref, cueonly, and group avg
    temp = unique_coherence';
    save(savename, 'temp', '-ascii', '-append'); %this saves a row containing the values of unique_coherence (unsigned)
    temp = unsigned_mean_rt';
    save(savename, 'temp', '-ascii', '-append'); %this saves 5 lines - mean RT given coherence for invalid, neutral, valid, cueonly, and group avg
    temp = unsigned_std_rt';
    save(savename, 'temp', '-ascii', '-append'); %this saves 5 lines - std RT given coherence for invalid, neutral, valid, cueonly, and group avg
end

save_fig_data = 0; %this saves the folded and unfolded psychophysical data for import into origin as an example figure
if save_fig_data
    savename = sprintf('Z:\\LabTools\\Matlab\\TEMPO_Analysis\\ProtocolSpecific\\CuedDirectionDiscrim\\figures\\%s_psychdata.txt',FILE);
    temp = unique_coherence';
    save(savename, 'temp', '-ascii'); %this saves a row containing the values of unique_coherence
    temp = pct_correct;
    save(savename, 'temp', '-ascii', '-append'); %this saves 3 rows containing the raw folded data
    temp = fold_fit_x;
    save(savename, 'temp', '-ascii', '-append'); %this saves a row containing the x values for the data fits
    temp = fold_fit_data;
    save(savename, 'temp', '-ascii', '-append'); %this saves 3 rows containing the folded fit data
    temp = [unique_signed_coherence' pct_pd'];
    temp = [mean([temp(1,:); temp(6,:)],1); temp([2:5,7:10],:)]'; 
    save(savename, 'temp', '-ascii', '-append'); %this saves 4 rows containing unique_coherence and the raw unfolded data 
                                                 %averaging across the two 0% coh conditions
    temp = unfold_fit_x;
    save(savename, 'temp', '-ascii', '-append'); %this saves a row containing the x values for the unfolded data fits
    temp = unfold_fit_data;
    save(savename, 'temp', '-ascii', '-append'); %this saves 3 rows containing the unfolded fit data
end

SAVE_FIGS = 0;
if (SAVE_FIGS)
    saveas(hlist, sprintf('%s_NP_curves.fig',FILE),'fig');
end

return