%-----------------------------------------------------------------------------------------------------------------------
%-- CP_CuedDirec -- Uses ROC analysis to compute a choice probability for each different stimulus level
%-- under each cue type and compute a grand choice probability for each cue type.
%--	modified from Compute_ChoiceProb.m
%-- VR 9/23/05
%-----------------------------------------------------------------------------------------------------------------------
function [grandCP, grandPval] = CP_CuedDirec(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);
tic;
TEMPO_Defs;
Path_Defs;
ProtocolDefs;

global cum_grand_Zpref cum_grand_Znull cum_0_Zpref cum_0_Znull;
SAVE_GLOBAL_DATA = 0;

%get the column of values of directions in the dots_params matrix
direction = data.dots_params(DOTS_DIREC,BegTrial:EndTrial,PATCH1);
unique_direction = munique(direction');
Pref_direction = data.one_time_params(PREFERRED_DIRECTION);

%get the motion coherences
coherence = data.dots_params(DOTS_COHER, BegTrial:EndTrial, PATCH1);
unique_coherence = munique(coherence');

%get the cue validity: -1=Invalid; 0=Neutral; 1=Valid; 2=CueOnly
cue_val = data.cue_params(CUE_VALIDITY, BegTrial:EndTrial, PATCH2);
unique_cue_val = munique(cue_val');
cue_val_names = {'NoCue','Invalid','Neutral','Valid','CueOnly'};

%get the cue directions
cue_direc = data.cue_params(CUE_DIREC, BegTrial:EndTrial, PATCH1);
unique_cue_direc = munique(cue_direc');

%compute cue types - 0=neutral, 1=directional, 2=cue_only
cue_type = abs(cue_val); %note that invalid(-1) and valid(+1) are directional
unique_cue_type = munique(cue_type');
cue_type_names = {'Neutral','Directional','CueOnly'};

%now, get the firing rates for all the trials
spike_rates = data.spike_rates(SpikeChan, BegTrial:EndTrial);

% get the firing rates and lfp during delay and stim for all the selected trials
for i = 1:length(coherence)
    %note that lfp is sampled at half the frequency as spikes, so divide bins by 2
    start_stim(i) = ceil(find(data.event_data(1,:,i) == VSTIM_ON_CD)/2);
    end_stim(i) = floor(find(data.event_data(1,:,i) == VSTIM_OFF_CD)/2);
    stim_lfp(i) = sqrt(mean( data.lfp_data(1,start_stim(i):end_stim(i),i) .^2 ));
    %do the following to get the power of lfp between 50 and 150Hz 
    %(remove 120 Hz contribution as noise), 400 samples sampled at 500Hz
    band = find( (500*(0:200)./400 >= 50) & (500*(0:200)./400 <= 150) & (500*(0:200)./400 ~= 120) ); 
    lfp_stim_powerspect{i} = abs(fft(data.lfp_data(1,start_stim(i):end_stim(i),i+BegTrial-1),400)).^2 ./ 400;
    stim_lfp_bp(i) = sum(lfp_stim_powerspect{i}(band));
end

%get outcome for each trial: 0=incorrect, 1=correct
trials_outcomes = logical (data.misc_params(OUTCOME,:) == CORRECT);

%get indices of any NULL conditions (for measuring spontaneous activity)
null_trials = logical( (coherence == data.one_time_params(NULL_VALUE)) );

%now, select trials that fall between BegTrial and EndTrial
trials = 1:length(coherence);
%a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

%get signed coherences
sign = (direction == Pref_direction)*2 - 1;	%=1 if preferred direction, -1 if null direction
signed_coherence = coherence .* sign;
unique_signed_coherence = munique(signed_coherence');
%[h_disp' sign' binoc_corr' signed_bin_corr']

%get the random seed for each trial of the Patch1 dots
%check to see if there is a fixed seed and store this for later if there is.
if (size(data.dots_params,1) >= DOTS_BIN_CORR_SEED)  %for backwards compatibility with old files that lack this
    seeds = data.dots_params(DOTS_BIN_CORR_SEED, :, PATCH1);
    select_fixed_seeds = logical(seeds == data.one_time_params(FIXED_SEED));
else
    select_fixed_seeds = [];
end
if (sum(select_fixed_seeds) >= 1)
    fixed_seed = data.one_time_params(FIXED_SEED);
else
    fixed_seed = NaN;
end

%start_offset = -200; % start of calculation relative to stim onset, ms
%window_size = 200;  % window size, ms
%spike_rates = ComputeSpikeRates(data, length(h_disp), StartCode, StartCode, start_offset+30, start_offset+window_size+30);
%spike_rates = spike_rates(1,:);

hlist = []; %used to store figure handles for saving figure

%now, determine the choice that was made for each trial, PREFERRED or NULL
%by definition, a preferred choice will be made to Target1 and a null choice to Target 2
%thus, look for the events IN_T1_WIN_CD and IN_T2_WIN_CD.  GCD, 5/30/2000
num_trials = length(coherence);
PREFERRED = 1;
NULL = 2;
for i=1:num_trials
    temp = data.event_data(1,:,i);
    events = temp(temp>0);  % all non-zero entries
    if (sum(events == IN_T1_WIN_CD) > 0)
        choice(i) = PREFERRED;
    elseif (sum(events == IN_T2_WIN_CD) > 0)
        choice(i) = NULL;
    else
        disp('Neither T1 or T2 chosen.  This should not happen!.  File must be bogus.');
    end
end


CORRECT_FOR_SLOW_SPIKE_RATE_CHANGE = 0;
if (CORRECT_FOR_SLOW_SPIKE_RATE_CHANGE)
    %now, Z-score the spike rates for each bin_corr and disparity condition
    %These Z-scored responses will be used to remove the effects of slow spike rate change
    Z_Spikes = spike_rates;
    for i=1:length(unique_bin_corr)
        for j=1:length(unique_hdisp)
            select = (binoc_corr == unique_bin_corr(i)) & (h_disp == unique_hdisp(j));
            z_dist = spike_rates(select);
            z_dist = (z_dist - mean(z_dist))/std(z_dist);
            Z_Spikes(select) = z_dist;
        end
    end

    %Do a regression of Zspikes against trial number.
    trial_temp = [trials; ones(1,length(trials))];
    [b, bint, r, rint, stats] = regress(Z_Spikes', trial_temp');

    figure;
    set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [50 120 500 573], 'Name', 'Zspikes');
    subplot(2, 1, 1);
    hold on;
    Handl(1) = plot(trials(choice == PREFERRED)', Z_Spikes(choice == PREFERRED)', 'ko', 'MarkerFaceColor', 'k');
    hold on;
    Handl(2) = plot(trials(choice == NULL)', Z_Spikes(choice == NULL)', 'ko');
    xlabel('Trials');
    ylabel('Z-Scores');
    legend(Handl, 'Preferred', 'Null', 2);
    titl = sprintf('File: %s', FILE);
    title(titl);

    subplot(2, 1, 2);
    hold on;
    Handl(1) = plot(trials(choice == PREFERRED)', r(choice == PREFERRED)', 'ko', 'MarkerFaceColor', 'k');
    hold on;
    Handl(2) = plot(trials(choice == NULL)', r(choice == NULL)', 'ko');
    xlabel('Trials');
    ylabel('Z-Scores');
    legend(Handl, 'Preferred', 'Null', 2);

    spike_rates = r';
end

%now, plot the spike distributions, sorted by choice, for each coherence level, for the non-directional and directional cues.

for k = 1:sum(unique_cue_type~=2); %ignore CueOnly trials
    hlist(1+length(hlist)) = figure;
    set(gcf,'ColorMap',colormap([1 1 1; 0 0 0]));
    set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [50 120 500 573], 'Name', sprintf('%s: Choice Probabilities',FILE));
    num_coher = length(unique_coherence);
    choice_prob = [];

    for i=1:num_coher
        for j=1:length(unique_direction)
            subplot(num_coher, length(unique_direction), (i-1)*length(unique_direction) + j);
            pref_choices = ( (choice == PREFERRED) & (coherence == unique_coherence(i)) & (direction == unique_direction(j)) ...
                & (cue_type == unique_cue_type(k)) );
            pref_dist{k,i,j} = spike_rates(pref_choices);
            null_choices = ( (choice == NULL) & (coherence == unique_coherence(i)) & (direction == unique_direction(j)) ...
                & (cue_type == unique_cue_type(k)) );
            null_dist{k,i,j} = spike_rates(null_choices);

            %plot the distributions.  This uses a function (in CommonTools) that I wrote.  GCD
            PlotTwoHists(pref_dist{k,i,j}, null_dist{k,i,j});
            if (i==1)
                ttl = sprintf('direction = %5.1f', unique_direction(j) );
                title(ttl);
            end
            if (j==1)
                lbl = sprintf('%5.1f %%', unique_coherence(i) );
                ylabel(lbl);
            end
            if ( (length(pref_dist{k,i,j}) > 0) & (length(null_dist{k,i,j}) > 0) )
                [choice_prob(k,i,j), choice_prob_Pval(k,i,j)] = ROC_signif_test(pref_dist{k,i,j}, null_dist{k,i,j});
                cp = sprintf('%5.2f', choice_prob(k,i,j));
                xl = XLim; yl = YLim;
                text(xl(2), yl(2)/2, cp);
            end
        end
    end

    subplot(num_coher,length(unique_direction),num_coher*length(unique_direction)-1);
    str = sprintf('%s: CueType = %s ', FILE, cue_type_names{k});
    xlabel(str);
    subplot(num_coher,length(unique_direction),num_coher*length(unique_direction));
    str = sprintf('PrDirec=%5.3f  FixedSeed=%d', Pref_direction, fixed_seed );
    xlabel(str);
    

    %pref_dist{k,i,j} and null_dist{k,i,j} are cell arrays that hold the preferred and null choice
    %distributions for each correlation level and each disparity.
    %NOW, we want to Z-score the distributions (preferred and null choices together) and combine across
    %correlations and/or disparities.  GCD, 8/10/00
    for i=1:num_coher
        for j=1:length(unique_direction)
            %for each condition, combine the preferred and null choices into one dist., then find mean and std
            all_choices = [];
            all_choices = [pref_dist{k,i,j}  null_dist{k,i,j}];
            mean_val(k,i,j) = mean(all_choices);
            std_val(k,i,j) = std(all_choices);
            %now use the mean_val and std_val to Z-score the original distributions and store separately
            Z_pref_dist{k,i,j} = (pref_dist{k,i,j} - mean_val(k,i,j))/std_val(k,i,j);
            Z_null_dist{k,i,j} = (null_dist{k,i,j} - mean_val(k,i,j))/std_val(k,i,j);
        end
    end

    %Now, combine the data across direction at each coherence value and plot distributions again
    if (k==1)
        hlist(1+length(hlist)) = figure;
        set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [550 120 400 573], 'Name', ...
            sprintf('%s: Choice Probabilities combined across Direction',FILE));
        set(gcf,'ColorMap',colormap([1 1 1; 0 0 0]));
    else
        figure(hlist(2));
    end        
    for i=1:num_coher
        subplot(num_coher+1, sum(unique_cue_type~=2), (i-1)*sum(unique_cue_type~=2)+k);

        %now, combine z-scored data across direction at each coherence level
        Zpref{k,i} = []; Znull{k,i} = [];
        for j=1:length(unique_direction)
            %%only include this correlation value in grand if the monkey had less than a 3:1 ratio
            %%of choices to the two targets (avoid conditions where there are few errors or bad biases)
            %if (min(length(Z_pref_dist{k,i,j}),length(Z_null_dist{k,i,j})) / max(length(Z_pref_dist{k,i,j}),length(Z_null_dist{k,i,j})) >= (1/3) )
            if (min(length(Z_pref_dist{k,i,j}),length(Z_null_dist{k,i,j})) > 0);
                Zpref{k,i} = [Zpref{k,i} Z_pref_dist{k,i,j}];
                Znull{k,i} = [Znull{k,i} Z_null_dist{k,i,j}];
            end
        end

        %plot the distributions.  This uses a function (in CommonTools) that I wrote.  GCD
        PlotTwoHists(Zpref{k,i}, Znull{k,i});

        lbl = sprintf('%5.1f %%', unique_coherence(i) );
        ylabel(lbl);

        if ( (length(Zpref{k,i}) > 0) & (length(Znull{k,i}) > 0) )
            ch_prob(k,i) = rocN(Zpref{k,i}, Znull{k,i}, 100);
            cp = sprintf('%5.2f', ch_prob(k,i));
            xl = XLim; yl = YLim;
            text(xl(2), yl(2)/2, cp);
        end
        if (i == 1)
            titl = sprintf('%s: CueType = %s',FILE,cue_type_names{k});
            title(titl);
        end
        if (i == num_coher)
            set(gca,'XTickLabel',''); %make room for grand CP details
        end
        if ( (unique_coherence(i) == 0) & SAVE_GLOBAL_DATA)   %save out 0% coherence zscores for cumulative analysis
            cum_0_Zpref{k} = [cum_0_Zpref{k} Zpref{k,i}];
            cum_0_Znull{k} = [cum_0_Znull{k} Znull{k,i}];
        end
    end
    %Now, combine the data across correlation values for each disparity

    %now, combine z-scored data across direction at each correlation level
    Zpref_pdirec = []; Znull_pdirec = []; Zpref_ndirec = []; Znull_ndirec = [];
    for i=1:length(unique_direction)
        for j=1:num_coher
            if (unique_coherence(j) ~= 0)
%                 %only include this correlation value in grand if the monkey had less than a 3:1 ratio
%                 %of choices to the two targets (avoid conditions where there are few errors or bad biases)
%                 if (min(length(Z_pref_dist{k,j,i}),length(Z_null_dist{k,j,i})) / max(length(Z_pref_dist{k,j,i}),length(Z_null_dist{k,j,i})) >= (1/3) )
                %only include this correlation value in grand if monkey made at least one choice in each direction.
                if (min(length(Z_pref_dist{k,j,i}),length(Z_null_dist{k,j,i})) > 0 )
                    if (unique_direction(i) == Pref_direction)
                        Zpref_pdirec = [Zpref_pdirec Z_pref_dist{k,j,i}];
                        Znull_pdirec = [Znull_pdirec Z_null_dist{k,j,i}];
                    else
                        Zpref_ndirec = [Zpref_ndirec Z_pref_dist{k,j,i}];
                        Znull_ndirec = [Znull_ndirec Z_null_dist{k,j,i}];
                    end
                end
            end
        end
    end

    if ( (length(Zpref_pdirec) > 0) & (length(Znull_pdirec) > 0) )
        ch_prob_pdirec(k) = rocN(Zpref_pdirec, Znull_pdirec, 100);
    end
    if ( (length(Zpref_ndirec) > 0) & (length(Znull_ndirec) > 0) )
        ch_prob_ndirec(k) = rocN(Zpref_ndirec, Znull_ndirec, 100);
    end


    %get a significance value for the overall CP at zero coherence
    if ( (length(Zpref{k,1}) > 0) & (length(Znull{k,1}) > 0) )
        [zeroCP(k), zeroPval(k)] = ROC_signif_test(Zpref{k,1}, Znull{k,1});
    end
            

    %Now, combine data across correlation to get a grand choice probability, and plot distributions again
    %hlist(1+length(hlist)) = figure;
    %set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [600 20 400 300], 'Name', sprintf('%s: Grand Choice Probability',FILE));
    subplot(num_coher+1,sum(unique_cue_type~=2),num_coher*sum(unique_cue_type~=2)+k)
    Zpref_grand{k} = []; Znull_grand{k} = [];
    %combine data across correlations into grand distributions
    for i=1:num_coher
        Zpref_grand{k} = [Zpref_grand{k} Zpref{k,i}];
        Znull_grand{k} = [Znull_grand{k} Znull{k,i}];
    end
    PlotTwoHists(Zpref_grand{k}, Znull_grand{k});
    if (k==1)
        ylabel('Grand CP');
    end
    
    %save out grand distributions for cumulative analysis
    if (SAVE_GLOBAL_DATA)
        cum_grand_Zpref{k} = [cum_grand_Zpref{k} Zpref_grand{k}];
        cum_grand_Znull{k} = [cum_grand_Znull{k} Znull_grand{k}];
    end
    
    %do permutation test to get P value for grand CP
    [grandCP(k), grandPval(k)] = ROC_signif_test(Zpref_grand{k}, Znull_grand{k});
    titl = sprintf('CueType=%s\ngrand CP = %5.3f, P = %6.4f', cue_type_names{k},grandCP(k), grandPval(k));
    title(titl);

end %end loop over cue types

% Repeat these computations for just the valid trials
for k = 3; %ignore CueOnly trials
    %choice_prob = [];

    for i=1:num_coher
        for j=1:length(unique_direction)
            pref_choices = ( (choice == PREFERRED) & (coherence == unique_coherence(i)) & (direction == unique_direction(j)) ...
                & (cue_val == VALID) );
            pref_dist{k,i,j} = spike_rates(pref_choices);
            null_choices = ( (choice == NULL) & (coherence == unique_coherence(i)) & (direction == unique_direction(j)) ...
                & (cue_val == VALID) );
            null_dist{k,i,j} = spike_rates(null_choices);
            if ( (length(pref_dist{k,i,j}) > 0) & (length(null_dist{k,i,j}) > 0) )
                [choice_prob(k,i,j), choice_prob_Pval(k,i,j)] = ROC_signif_test(pref_dist{k,i,j}, null_dist{k,i,j});
            end
        end
    end

    %pref_dist{k,i,j} and null_dist{k,i,j} are cell arrays that hold the preferred and null choice
    %distributions for each correlation level and each disparity.
    %NOW, we want to Z-score the distributions (preferred and null choices together) and combine across
    %correlations and/or disparities.  GCD, 8/10/00
    for i=1:num_coher
        for j=1:length(unique_direction)
            %for each condition, combine the preferred and null choices into one dist., then find mean and std
            all_choices = [];
            all_choices = [pref_dist{k,i,j}  null_dist{k,i,j}];
            mean_val(k,i,j) = mean(all_choices);
            std_val(k,i,j) = std(all_choices);
            %now use the mean_val and std_val to Z-score the original distributions and store separately
            Z_pref_dist{k,i,j} = (pref_dist{k,i,j} - mean_val(k,i,j))/std_val(k,i,j);
            Z_null_dist{k,i,j} = (null_dist{k,i,j} - mean_val(k,i,j))/std_val(k,i,j);
        end
    end

    %Now, combine the data across direction at each coherence value and plot distributions again
    for i=1:num_coher
        %now, combine z-scored data across direction at each coherence level
        Zpref{k,i} = []; Znull{k,i} = [];
        for j=1:length(unique_direction)
            %%only include this correlation value in grand if the monkey had less than a 3:1 ratio
            %%of choices to the two targets (avoid conditions where there are few errors or bad biases)
            %if (min(length(Z_pref_dist{k,i,j}),length(Z_null_dist{k,i,j})) / max(length(Z_pref_dist{k,i,j}),length(Z_null_dist{k,i,j})) >= (1/3) )
            if (min(length(Z_pref_dist{k,i,j}),length(Z_null_dist{k,i,j})) > 0);
                Zpref{k,i} = [Zpref{k,i} Z_pref_dist{k,i,j}];
                Znull{k,i} = [Znull{k,i} Z_null_dist{k,i,j}];
            end
        end
        if ( (length(Zpref{k,i}) > 0) & (length(Znull{k,i}) > 0) )
            ch_prob(k,i) = rocN(Zpref{k,i}, Znull{k,i}, 100);
        end
        if ( (unique_coherence(i) == 0) & SAVE_GLOBAL_DATA)   %save out 0% coherence zscores for cumulative analysis
            cum_0_Zpref{k} = [cum_0_Zpref{k} Zpref{k,i}];
            cum_0_Znull{k} = [cum_0_Znull{k} Znull{k,i}];
        end
    end
    %Now, combine the data across correlation values for each disparity

    %now, combine z-scored data across direction at each correlation level
    Zpref_pdirec = []; Znull_pdirec = []; Zpref_ndirec = []; Znull_ndirec = [];
    for i=1:length(unique_direction)
        for j=1:num_coher
            if (unique_coherence(j) ~= 0)
%                 %only include this correlation value in grand if the monkey had less than a 3:1 ratio
%                 %of choices to the two targets (avoid conditions where there are few errors or bad biases)
%                 if (min(length(Z_pref_dist{k,j,i}),length(Z_null_dist{k,j,i})) / max(length(Z_pref_dist{k,j,i}),length(Z_null_dist{k,j,i})) >= (1/3) )
                %only include this correlation value in grand if monkey made at least one choice in each direction.
                if (min(length(Z_pref_dist{k,j,i}),length(Z_null_dist{k,j,i})) > 0 )
                    if (unique_direction(i) == Pref_direction)
                        Zpref_pdirec = [Zpref_pdirec Z_pref_dist{k,j,i}];
                        Znull_pdirec = [Znull_pdirec Z_null_dist{k,j,i}];
                    else
                        Zpref_ndirec = [Zpref_ndirec Z_pref_dist{k,j,i}];
                        Znull_ndirec = [Znull_ndirec Z_null_dist{k,j,i}];
                    end
                end
            end
        end
    end

    if ( (length(Zpref_pdirec) > 0) & (length(Znull_pdirec) > 0) )
        ch_prob_pdirec(k) = rocN(Zpref_pdirec, Znull_pdirec, 100);
    end
    if ( (length(Zpref_ndirec) > 0) & (length(Znull_ndirec) > 0) )
        ch_prob_ndirec(k) = rocN(Zpref_ndirec, Znull_ndirec, 100);
    end


    %get a significance value for the overall CP at zero coherence
    if ( (length(Zpref{k,1}) > 0) & (length(Znull{k,1}) > 0) )
        [zeroCP(k), zeroPval(k)] = ROC_signif_test(Zpref{k,1}, Znull{k,1});
    end
            

    %Now, combine data across correlation to get a grand choice probability, and plot distributions again
    Zpref_grand{k} = []; Znull_grand{k} = [];
    %combine data across correlations into grand distributions
    for i=1:num_coher
        Zpref_grand{k} = [Zpref_grand{k} Zpref{k,i}];
        Znull_grand{k} = [Znull_grand{k} Znull{k,i}];
    end
    
    %save out grand distributions for cumulative analysis
    if (SAVE_GLOBAL_DATA)
        cum_grand_Zpref{k} = [cum_grand_Zpref{k} Zpref_grand{k}];
        cum_grand_Znull{k} = [cum_grand_Znull{k} Znull_grand{k}];
    end
    
    %do permutation test to get P value for grand CP
    [grandCP(k), grandPval(k)] = ROC_signif_test(Zpref_grand{k}, Znull_grand{k});

end %end loop for valid trials


%now perform permutation test to test whether CPs are different between
%neutral and directional cues.
npermut = 2000; alpha = .05;
for i = 1:npermut
    %first perform test on zero coherence trials
    pd_zero_select_boot = [Zpref{1,1} Zpref{2,1}]; %concatenate neutral and directional cue responses
    pd_zero_boot_shuffle = pd_zero_select_boot(randperm(length(pd_zero_select_boot)));
    pd_zero_neu_boot = pd_zero_boot_shuffle(1:length(Zpref{1,1}));
    pd_zero_dir_boot = pd_zero_boot_shuffle(length(Zpref{1,1})+1:end);
    
    nd_zero_select_boot = [Znull{1,1} Znull{2,1}];
    nd_zero_boot_shuffle = nd_zero_select_boot(randperm(length(nd_zero_select_boot)));
    nd_zero_neu_boot = nd_zero_boot_shuffle(1:length(Znull{1,1}));
    nd_zero_dir_boot = nd_zero_boot_shuffle(length(Znull{1,1})+1:end);

    neu_zero_CP_boot(i) = rocN(pd_zero_neu_boot, nd_zero_neu_boot);
    dir_zero_CP_boot(i) = rocN(pd_zero_dir_boot, nd_zero_dir_boot);
    delta_zero_CP_boot(i) = dir_zero_CP_boot(i) - neu_zero_CP_boot(i);
    
    %now repeat on all trials used to compute grand CP
    pd_grnd_select_boot = [Zpref_grand{1} Zpref_grand{2}]; %concatenate neutral and directional cue responses
    pd_grnd_boot_shuffle = pd_grnd_select_boot(randperm(length(pd_grnd_select_boot)));
    pd_grnd_neu_boot = pd_grnd_boot_shuffle(1:length(Zpref_grand{1}));
    pd_grnd_dir_boot = pd_grnd_boot_shuffle(length(Zpref_grand{1})+1:end);
    
    nd_grnd_select_boot = [Znull_grand{1} Znull_grand{2}];
    nd_grnd_boot_shuffle = nd_grnd_select_boot(randperm(length(nd_grnd_select_boot)));
    nd_grnd_neu_boot = nd_grnd_boot_shuffle(1:length(Znull_grand{1}));
    nd_grnd_dir_boot = nd_grnd_boot_shuffle(length(Znull_grand{1})+1:end);

    neu_grnd_CP_boot(i) = rocN(pd_grnd_neu_boot, nd_grnd_neu_boot);
    dir_grnd_CP_boot(i) = rocN(pd_grnd_dir_boot, nd_grnd_dir_boot);
    delta_grnd_CP_boot(i) = dir_grnd_CP_boot(i) - neu_grnd_CP_boot(i);
end

delta_zero_CP_boot = sort(delta_zero_CP_boot);
delta_zero_CP_lo = delta_zero_CP_boot(floor(alpha*npermut/2));
delta_zero_CP_hi = delta_zero_CP_boot(ceil((1-alpha/2)*npermut));
delta_grnd_CP_boot = sort(delta_grnd_CP_boot);
delta_grnd_CP_lo = delta_grnd_CP_boot(floor(alpha*npermut/2));
delta_grnd_CP_hi = delta_grnd_CP_boot(ceil((1-alpha/2)*npermut));

for i = 1:npermut
    %first perform test on zero coherence trials
    pd_zero_select_boot = [Zpref{1,1} Zpref{3,1}]; %concatenate neutral and directional cue responses
    pd_zero_boot_shuffle = pd_zero_select_boot(randperm(length(pd_zero_select_boot)));
    pd_zero_neu_boot = pd_zero_boot_shuffle(1:length(Zpref{1,1}));
    pd_zero_val_boot = pd_zero_boot_shuffle(length(Zpref{1,1})+1:end);
    
    nd_zero_select_boot = [Znull{1,1} Znull{3,1}];
    nd_zero_boot_shuffle = nd_zero_select_boot(randperm(length(nd_zero_select_boot)));
    nd_zero_neu_boot = nd_zero_boot_shuffle(1:length(Znull{1,1}));
    nd_zero_val_boot = nd_zero_boot_shuffle(length(Znull{1,1})+1:end);

    neu_zero_CP_boot(i) = rocN(pd_zero_neu_boot, nd_zero_neu_boot);
    val_zero_CP_boot(i) = rocN(pd_zero_val_boot, nd_zero_val_boot);
    delta_zero_CP_val_boot(i) = val_zero_CP_boot(i) - neu_zero_CP_boot(i);
    
    %now repeat on all trials used to compute grand CP
    pd_grnd_select_boot = [Zpref_grand{1} Zpref_grand{3}]; %concatenate neutral and valid cue responses
    pd_grnd_boot_shuffle = pd_grnd_select_boot(randperm(length(pd_grnd_select_boot)));
    pd_grnd_neu_boot = pd_grnd_boot_shuffle(1:length(Zpref_grand{1}));
    pd_grnd_val_boot = pd_grnd_boot_shuffle(length(Zpref_grand{1})+1:end);
    
    nd_grnd_select_boot = [Znull_grand{1} Znull_grand{3}];
    nd_grnd_boot_shuffle = nd_grnd_select_boot(randperm(length(nd_grnd_select_boot)));
    nd_grnd_neu_boot = nd_grnd_boot_shuffle(1:length(Znull_grand{1}));
    nd_grnd_val_boot = nd_grnd_boot_shuffle(length(Znull_grand{1})+1:end);

    neu_grnd_CP_boot(i) = rocN(pd_grnd_neu_boot, nd_grnd_neu_boot);
    val_grnd_CP_boot(i) = rocN(pd_grnd_val_boot, nd_grnd_val_boot);
    delta_grnd_CP_val_boot(i) = val_grnd_CP_boot(i) - neu_grnd_CP_boot(i);
end

delta_zero_CP_val_boot = sort(delta_zero_CP_val_boot);
delta_zero_CP_val_lo = delta_zero_CP_val_boot(floor(alpha*npermut/2));
delta_zero_CP_val_hi = delta_zero_CP_val_boot(ceil((1-alpha/2)*npermut));
delta_grnd_CP_val_boot = sort(delta_grnd_CP_boot);
delta_grnd_CP_val_lo = delta_grnd_CP_val_boot(floor(alpha*npermut/2));
delta_grnd_CP_val_hi = delta_grnd_CP_val_boot(ceil((1-alpha/2)*npermut));

% %time course of choice probability
% figure;
% set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', 'Time Course of Choice Probability');
% subplot(2, 1, 1);
%
% start_offset = -100; % start of calculation relative to stim onset, ms
% window_size = 100;  % window size, ms
% window_step = 20; % step of sliding window, ms
% start_time = start_offset: window_step: 1500;
% choice_prob_tc = [];
% for j = 1:length(start_time) %calculate spike rates for different window
%     Zpref_tc = []; Znull_tc = [];
%     spike_rates = ComputeSpikeRates(data, length(direction), StartCode, StartCode, start_time(j)+30, start_time(j)+window_size+30);
%     spike_rates = spike_rates(1,:);
%
%     for i=1:length(unique_coherence)%loop through each binocular correlation levels, and calculate CPs for each
%         for k=1:length(unique_direction)%loop through each disparity level.
%             pref_choices = ( (choice == PREFERRED) & (coherence == unique_coherence(i)) & (direction == unique_direction(k)) );
%             pref_dist_tc{j,i,k} = spike_rates(pref_choices & select_trials);
%             null_choices = ( (choice == NULL) & (coherence == unique_coherence(i)) & (direction == unique_direction(k)) );
%             null_dist_tc{j,i,k} = spike_rates(null_choices & select_trials);
%
%             if ( (length(pref_dist_tc{j,i,k}) > 0) & (length(null_dist_tc{j,i,k}) > 0) )
%                 choice_prob_tc(j,i,k) = rocN(pref_dist_tc{j,i,k}, null_dist_tc{j,i,k}, 100);
%             end
%
%             %Z-score using means and variances calculated from the whole 1.5sec visual stimulation period
%             %Z_pref_dist_tc{j,i,k} = (pref_dist_tc{j,i,k} - mean_val(i,k))/std_val(i,k);
%             %Z_null_dist_tc{j,i,k} = (null_dist_tc{j,i,k} - mean_val(i,k))/std_val(i,k);
%             %for each condition, combine the preferred and null choices into one dist., then find mean and std
%             all_choices = [];
%             all_choices = [pref_dist_tc{j,i,k}  null_dist_tc{j,i,k}];
%             mean_val(i,k) = mean(all_choices);
%             std_val(i,k) = std(all_choices);
%             Z_pref_dist_tc{j,i,k} = (pref_dist_tc{j,i,k} - mean_val(i,k))/std_val(i,k);
%             Z_null_dist_tc{j,i,k} = (null_dist_tc{j,i,k} - mean_val(i,k))/std_val(i,k);
%             %only include this correlation value if the monkey had less than a 3:1 ratio
%             %of choices to the two targets (avoid conditions where there are few errors or bad biases)
%             if (min(length(Z_pref_dist_tc{j,i,k}),length(Z_null_dist_tc{j,i,k})) / max(length(Z_pref_dist_tc{j,i,k}),length(Z_null_dist_tc{j,i,k})) >= (1/3) )
%                 Zpref_tc = [Zpref_tc Z_pref_dist_tc{j,i,k}];
%                 Znull_tc = [Znull_tc Z_null_dist_tc{j,i,k}];
%             end
%         end
%     end
%     choice_prob_tc_norm(j) = rocN(Zpref_tc, Znull_tc, 100);
% end
% bin_center = start_time + (window_size/2);
%
% %plot choice probabilities against time for each correlation and disparity level
% for i=1:length(unique_coherence)
%     for k=1:length(unique_direction)
%         if ( (length(pref_dist_tc{1,i,k}) > 0) & (length(null_dist_tc{1,i,k}) > 0) )
%             hold on;
%             plot(bin_center, choice_prob_tc(:,i,k), 'k-');
%             hold off;
%         end
%     end
% end
% xlabel('Time after Stimulus Onset (ms)');
% ylabel('Choice Probability');
% YLim([0.0 1.0]);
% XLim([-100 1500]);
%
% %plot grand choice probabilities against time
% subplot(2, 1, 2);
% hold on;
% plot(bin_center, choice_prob_tc_norm, 'k-');
% hold off;
% xlabel('Time after Stimulus Onset (ms)');
% ylabel('Choice Probability');
% YLim([0.0 1.0]);
% XLim([-100 1500]);
%
% %time course of firing to preferred and null choice
% figure;
% set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', 'Time Course of Firing');
% subplot(2, 1, 1);
%
% start_offset = -100; % start of calculation relative to stim onset, ms
% window_size = 20;  % window size, ms
% window_step = 20; % step of sliding window, ms
% start_time = start_offset: window_step: 1500;
% for j = 1:length(start_time) %calculate spike rates for different window
%     spike_rates = ComputeSpikeRates(data, length(direction), StartCode, StartCode, start_time(j)+30, start_time(j)+window_size+30);
%     spike_rates = spike_rates(1,:);
%
%     for i=1:length(unique_coherence)%loop through each binocular correlation levels, and calculate CPs for each
%         for k=1:length(unique_direction)%loop through each disparity level.
%             pref_choices = ( (choice == PREFERRED) & (coherence == unique_coherence(i)) & (direction == unique_direction(k)) );
%             null_choices = ( (choice == NULL) & (coherence == unique_coherence(i)) & (direction == unique_direction(k)) );
%
%             %only include this correlation value if the monkey had less than a 3:1 ratio
%             %of choices to the two targets (avoid conditions where there are few errors or bad biases)
%             if (min(sum(pref_choices),sum(null_choices)) / max(sum(pref_choices),sum(null_choices)) >= (1/3) )
%                 mean_pref(j,i,k) = mean(spike_rates(pref_choices & select_trials));
%                 mean_null(j,i,k) = mean(spike_rates(null_choices & select_trials));
%             else
%                 mean_pref(j,i,k) = NaN;
%                 mean_null(j,i,k) = NaN;
%             end
%         end
%     end
% end
%
% %normalize firing rates
% max_firing = max([max(mean_pref);max(mean_null)]);
% for j = 1:length(start_time)
%     mean_pref_norm(j,:,:) = mean_pref(j,:,:)./max_firing;
%     mean_null_norm(j,:,:) = mean_null(j,:,:)./max_firing;
% end
%
% bin_center = start_time + (window_size/2);
%
% %plot normalize firing rate against time for each correlation and disparity level
% for i=1:length(unique_coherence)
%     for k=1:length(unique_direction)
%         hold on;
%         plot(bin_center, mean_pref_norm(:,i,k), 'k-');
%         plot(bin_center, mean_null_norm(:,i,k), 'k--');
%         hold off;
%     end
% end
% xlabel('Time after Stimulus Onset (ms)');
% ylabel('Normalized Response');
% YLim([0.0 1.0]);
% XLim([-100 1500]);
%
% %average across correlation and disparity values
% corr_count = 0;
% for i=1:length(unique_coherence)%loop through each binocular correlation levels, and calculate CPs for each
%     for k=1:length(unique_direction)%loop through each disparity level.
%         if (isnan(mean_pref_norm(1,i,k)) == 0)
%             corr_count = corr_count + 1;
%             norm_pref(:,corr_count) = mean_pref_norm(:,i,k);
%             norm_null(:,corr_count) = mean_null_norm(:,i,k);
%         end
%     end
% end
% mean_norm_pref = mean(norm_pref,2);
% mean_norm_null = mean(norm_null,2);
%
% %plot average normalized firing rate against time
% subplot(2, 1, 2);
% hold on;
% plot(bin_center, mean_norm_pref, 'k-');
% plot(bin_center, mean_norm_null, 'k-');
% hold off;
% xlabel('Time after Stimulus Onset (ms)');
% ylabel('Normalized Response');
% YLim([0.0 1.0]);
% XLim([-100 1500]);

%save ('Z:\LabTools\Matlab\TEMPO_Analysis\ProtocolSpecific\DepthDiscrim\CP_data.mat')
%disp ('workspace saved')






%-----------------------------------------------------------------------------------------------------------------------------------------------------------
%now print out some summary parameters to the screen and to a cumulative file
pref_indx = find(unique_direction == Pref_direction);	%index to preferred disparity (which has no var conditions, if any)
null_indx = find(unique_direction ~= Pref_direction);	%index to null disparity
if isnan(fixed_seed)	% this run didn't have NOVAR conditions
    str = sprintf('%s %6.2f %6s %6s %6.4f %7.5f %6.4f %7.5f %6.4f %6.4f', FILE, unique_coherence(1), '--', '--', zeroCP, zeroPval, grandCP, grandPval, ch_prob_pdirec, ch_prob_ndirec);
else
    str = sprintf('%s %6.2f %6.4f %6.4f %6.4f %7.5f %6.4f %7.5f %6.4f %6.4f', FILE, unique_coherence(1), choice_prob(1,pref_indx), choice_prob(1,null_indx), zeroCP, zeroPval, grandCP, grandPval, ch_prob_pdirec, ch_prob_ndirec);
end
%disp(str);

output = 1;
output2 = 1; %for CP on valid trials
if (output == 1)
    printflag = 0;
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CPSummary.dat'];
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fsummid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fsummid, 'FILE\t lo_corr\t NeuCPzero\t NeuPzero\t DirCPzero\t DirPzero\t NeuGrndCP\t NeuGrndP\t DirGrndCP\t DirGrandP\t DelZeroCP\t DelZeroCPlo\t DelZeroCPhi\t DelGrndCP\t DelGrndCPlo\t DelGrndCPhi\t NeuCP_PrefD\t NeuCP_NullD\t DirCP_PrefD\t DirCP_NullD\t');
        fprintf(fsummid, '\r\n');
    end
    fprintf(fsummid, sprintf('%s\t %5.2f\t %5.3f\t %13.10f\t %5.3f\t %13.10f\t %5.3f\t %13.10f\t %5.3f\t %13.10f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t ',...
        FILE, unique_coherence(1), zeroCP(1),zeroPval(1),zeroCP(2),zeroPval(2),...
        grandCP(1),grandPval(1),grandCP(2),grandPval(2),...
        zeroCP(2)-zeroCP(1),delta_zero_CP_lo,delta_zero_CP_hi,grandCP(2)-grandCP(1),delta_grnd_CP_lo,delta_grnd_CP_hi,...
        ch_prob_pdirec(1),ch_prob_ndirec(1),ch_prob_pdirec(2),ch_prob_ndirec(2)));
    fprintf(fsummid, '\r\n');
    fclose(fsummid);
end

if (output2)
    printflag = 0;
    outfile = [BASE_PATH 'ProtocolSpecific\CuedDirectionDiscrim\CP_VALID_Summary.dat'];
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fsummid = fopen(outfile, 'a');

    if (printflag)
        fprintf(fsummid, 'FILE\t lo_corr\t NeuCPzero\t NeuPzero\t ValCPzero\t ValPzero\t NeuGrndCP\t NeuGrndP\t ValGrndCP\t ValGrandP\t VDelZeroCP\t VDelZeroCPlo\t VDelZeroCPhi\t VDelGrndCP\t VDelGrndCPlo\t VDelGrndCPhi\t NeuCP_PrefD\t NeuCP_NullD\t ValCP_PrefD\t ValCP_NullD\t');
        fprintf(fsummid, '\r\n');
    end
    fprintf(fsummid, sprintf('%s\t %5.2f\t %5.3f\t %13.10f\t %5.3f\t %13.10f\t %5.3f\t %13.10f\t %5.3f\t %13.10f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t ',...
        FILE, unique_coherence(1), zeroCP(1),zeroPval(1),zeroCP(3),zeroPval(3),...
        grandCP(1),grandPval(1),grandCP(3),grandPval(3),...
        zeroCP(3)-zeroCP(1),delta_zero_CP_val_lo,delta_zero_CP_val_hi,grandCP(3)-grandCP(1),delta_grnd_CP_val_lo,delta_grnd_CP_val_hi,...
        ch_prob_pdirec(1),ch_prob_ndirec(1),ch_prob_pdirec(3),ch_prob_ndirec(3)));
%     if (printflag)
%         fprintf(fsummid, 'FILE\t lo_corr\t ValCPzero\t ValPzero\t ValGrndCP\t ValGrndP\t VDelZeroCP\t VDelZeroCPlo\t VDelZeroCPhi\t VDelGrndCP\t VDelGrndCPlo\t VDelGrndCPhi\t ValCP_PrefD\t ValCP_NullD\t');
%         fprintf(fsummid, '\r\n');
%     end
%     fprintf(fsummid, sprintf('%s\t %5.2f\t %5.3f\t %13.10f\t %5.3f\t %13.10f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t %5.3f\t ',...
%         FILE, unique_coherence(1), zeroCP(3),zeroPval(3), grandCP(3),grandPval(3), ...
%         zeroCP(3)-zeroCP(1),delta_zero_CP_val_lo,delta_zero_CP_val_hi, ...
%         grandCP(3)-grandCP(1),delta_grnd_CP_val_lo,delta_grnd_CP_val_hi, ...
%         ch_prob_pdirec(3),ch_prob_ndirec(3)));
    fprintf(fsummid, '\r\n');
    fclose(fsummid);
end

SAVE_FIGS = 0;
if (SAVE_FIGS)
    saveas(hlist(1), sprintf('%s_NeuCP.fig',FILE),'fig');
    saveas(hlist(2), sprintf('%s_NeuCP_acrossDir.fig',FILE),'fig');
    saveas(hlist(3), sprintf('%s_NeuGrandCP.fig',FILE),'fig');
    saveas(hlist(4), sprintf('%s_DirCP.fig',FILE),'fig');
    saveas(hlist(5), sprintf('%s_DirCP_acrossDir.fig',FILE),'fig');
    saveas(hlist(6), sprintf('%s_DirGrandCP.fig',FILE),'fig');
end

%keyboard

return;
%
% %----------------------------------------------------------------------------------------------------------------------------------------------------------------
% %now, print out spike rates for all trials at the lowest correlation, sorted by choice
% output = 0;
% if (output)
%     i = size(PATH,2) - 1;
%     while PATH(i) ~='\'	%Analysis directory is one branch below Raw Data Dir
%         i = i - 1;
%     end
%     PATHOUT = [PATH(1:i) 'Analysis\NeuroPsychoCurves\'];
%     i = size(FILE,2) - 1;
%     while FILE(i) ~='.'
%         i = i - 1;
%     end
%     FILEOUT = [FILE(1:i) 'choice_data'];
%
%     fileid = [PATHOUT FILEOUT];
%     fwriteid = eval(['fopen(fileid, ''w'')']);
%
%     pref_choices = ( (choice == PREFERRED) & (coherence == unique_coherence(1)) );
%     pref_dist = spike_rates(pref_choices & select_trials);
%     null_choices = ( (choice == NULL) & (coherence == unique_coherence(1)) );
%     null_dist = spike_rates(null_choices & select_trials);
%     len = [length(pref_dist) length(null_dist)];
%     max_vals = max(len);
%     min_vals = min(len);
%
%     fprintf(fwriteid,'Pref\tNull\n');
%     for i=1:min_vals
%         fprintf(fwriteid, '%6.3f\t%6.3f\n', pref_dist(i), null_dist(i));
%     end
%     for i=min_vals+1:max_vals
%         if (length(pref_dist) == max_vals)
%             fprintf(fwriteid, '%6.3f\t\n', pref_dist(i));
%         else
%             fprintf(fwriteid, '\t%6.3f\n', null_dist(i));
%         end
%     end
%
%     fclose(fwriteid);
% end
%
% %-----------------------------------------------------------------------------------------------------------------------------------------------------------
% %now print out data for time course of choice probabilities TU 1/23/01
% output2 = 0;
% if (output2)
%     outfile2 = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\CPtime_course.dat'];
%     printflag = 0;
%     if (exist(outfile2, 'file') == 0)    %file does not yet exist
%         printflag = 1;
%     end
%     fid = fopen(outfile2, 'a');
%     if (printflag)
%         fprintf(fid, 'FILE\t Nthr100\t Nthr200\t Nthr300\t Nthr400\t Nthr500\t Nthr600\t Nthr700\t Nthr800\t Nthr900\t Nthr1000\t Nthr1100\t Nthr1200\t Nthr1300\t Nthr1400\t Nthr1500\t ');
%         fprintf(fid, '\r\n');
%         printflag = 0;
%     end
%
%     buff = sprintf('%s\t ', FILE);
%     for i=1:length(choice_prob_tc_norm)
%         buff = sprintf('%s\t %6.4f\t', buff, choice_prob_tc_norm(i));
%     end
%     fprintf(fid, '%s', buff);
%     fprintf(fid, '\r\n');
%     fclose(fid);
% end
%
% %-----------------------------------------------------------------------------------------------------------------------------------------------------------
% %now print out data for time course of choice probabilities at different correlation levels TU 4/1/03
% output2 = 0;
% if (output2)
%     outfile2 = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\CPtime_course_lowcorr.dat'];
%     printflag = 0;
%     if (exist(outfile2, 'file') == 0)    %file does not yet exist
%         printflag = 1;
%     end
%     fid = fopen(outfile2, 'a');
%     if (printflag)
%         fprintf(fid, 'FILE\t Nthr100\t Nthr200\t Nthr300\t Nthr400\t Nthr500\t Nthr600\t Nthr700\t Nthr800\t Nthr900\t Nthr1000\t Nthr1100\t Nthr1200\t Nthr1300\t Nthr1400\t Nthr1500\t ');
%         fprintf(fid, '\r\n');
%         printflag = 0;
%     end
%
%     buff = sprintf('%s\t ', FILE);
%     for i=1:length(choice_prob_tc_norm)
%         buff = sprintf('%s\t %6.4f\t', buff, choice_prob_tc(i,1,1));
%     end
%     fprintf(fid, '%s', buff);
%     fprintf(fid, '\r\n');
%     buff = sprintf('%s\t ', FILE);
%     for i=1:length(choice_prob_tc_norm)
%         buff = sprintf('%s\t %6.4f\t', buff, choice_prob_tc(i,1,2));
%     end
%     fprintf(fid, '%s', buff);
%     fprintf(fid, '\r\n');
%     fclose(fid);
% end
% if (output2)
%     outfile2 = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\CPtime_course_intermediatecorr.dat'];
%     printflag = 0;
%     if (exist(outfile2, 'file') == 0)    %file does not yet exist
%         printflag = 1;
%     end
%     fid = fopen(outfile2, 'a');
%     if (printflag)
%         fprintf(fid, 'FILE\t Nthr100\t Nthr200\t Nthr300\t Nthr400\t Nthr500\t Nthr600\t Nthr700\t Nthr800\t Nthr900\t Nthr1000\t Nthr1100\t Nthr1200\t Nthr1300\t Nthr1400\t Nthr1500\t ');
%         fprintf(fid, '\r\n');
%         printflag = 0;
%     end
%
%     if(length(unique_coherence)>=4)
%         buff = sprintf('%s\t ', FILE);
%         for i=1:length(choice_prob_tc_norm)
%             buff = sprintf('%s\t %6.4f\t', buff, choice_prob_tc(i,4,1));
%         end
%         fprintf(fid, '%s', buff);
%         fprintf(fid, '\r\n');
%         buff = sprintf('%s\t ', FILE);
%         for i=1:length(choice_prob_tc_norm)
%             buff = sprintf('%s\t %6.4f\t', buff, choice_prob_tc(i,4,2));
%         end
%         fprintf(fid, '%s', buff);
%         fprintf(fid, '\r\n');
%     end
%     fclose(fid);
% end
% if (output2)
%     outfile2 = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\CPtime_course_highcorr.dat'];
%     printflag = 0;
%     if (exist(outfile2, 'file') == 0)    %file does not yet exist
%         printflag = 1;
%     end
%     fid = fopen(outfile2, 'a');
%     if (printflag)
%         fprintf(fid, 'FILE\t Nthr100\t Nthr200\t Nthr300\t Nthr400\t Nthr500\t Nthr600\t Nthr700\t Nthr800\t Nthr900\t Nthr1000\t Nthr1100\t Nthr1200\t Nthr1300\t Nthr1400\t Nthr1500\t ');
%         fprintf(fid, '\r\n');
%         printflag = 0;
%     end
%
%     if(length(unique_coherence)>=6)
%         buff = sprintf('%s\t ', FILE);
%         for i=1:length(choice_prob_tc_norm)
%             buff = sprintf('%s\t %6.4f\t', buff, choice_prob_tc(i,6,1));
%         end
%         fprintf(fid, '%s', buff);
%         fprintf(fid, '\r\n');
%         buff = sprintf('%s\t ', FILE);
%         for i=1:length(choice_prob_tc_norm)
%             buff = sprintf('%s\t %6.4f\t', buff, choice_prob_tc(i,6,2));
%         end
%         fprintf(fid, '%s', buff);
%         fprintf(fid, '\r\n');
%     end
%     fclose(fid);
% end
%
% %-----------------------------------------------------------------------------------------------------------------------------------------------------------
% %now print out data for time course of firing for each choice separately TU 1/31/01
% output3 = 0;
% if (output3)
%     outfile3 = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\PrefChoiceTime_course.dat'];
%     printflag = 0;
%     if (exist(outfile3, 'file') == 0)    %file does not yet exist
%         printflag = 1;
%     end
%     fid = fopen(outfile3, 'a');
%     if (printflag)
%         fprintf(fid, 'FILE\t Nthr100\t Nthr200\t Nthr300\t Nthr400\t Nthr500\t Nthr600\t Nthr700\t Nthr800\t Nthr900\t Nthr1000\t Nthr1100\t Nthr1200\t Nthr1300\t Nthr1400\t Nthr1500\t ');
%         fprintf(fid, '\r\n');
%         printflag = 0;
%     end
%
%     buff = sprintf('%s\t ', FILE);
%     for i=1:length(mean_norm_pref)
%         buff = sprintf('%s\t %6.4f\t', buff, mean_norm_pref(i));
%     end
%     fprintf(fid, '%s', buff);
%     fprintf(fid, '\r\n');
%     fclose(fid);
%
%     outfile4 = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\NullChoiceTime_course.dat'];
%     printflag = 0;
%     if (exist(outfile4, 'file') == 0)    %file does not yet exist
%         printflag = 1;
%     end
%     fid = fopen(outfile4, 'a');
%     if (printflag)
%         fprintf(fid, 'FILE\t Nthr100\t Nthr200\t Nthr300\t Nthr400\t Nthr500\t Nthr600\t Nthr700\t Nthr800\t Nthr900\t Nthr1000\t Nthr1100\t Nthr1200\t Nthr1300\t Nthr1400\t Nthr1500\t ');
%         fprintf(fid, '\r\n');
%         printflag = 0;
%     end
%
%     buff = sprintf('%s\t ', FILE);
%     for i=1:length(mean_norm_null)
%         buff = sprintf('%s\t %6.4f\t', buff, mean_norm_null(i));
%     end
%     fprintf(fid, '%s', buff);
%     fprintf(fid, '\r\n');
%     fclose(fid);
% end
%
% %------------------------------------------------------------------------------------------------------------------
% % write out CP for each correlation level. Only use when the calculation of CP at each correlation level
% % is done with ROC_significance_test not rocN  TU 08/09/01
% output1 = 0;
% if (output1)
%     outfile1 = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\CP_corr.dat'];
%
%     printflag = 0;
%     if (exist(outfile1, 'file') == 0)    %file does not yet exist
%         printflag = 1;
%     end
%     fid = fopen(outfile1, 'a');
%     if (printflag)
%         fprintf(fid, 'File SignedBinCorr PercentPref CP CP_Pval');
%         fprintf(fid, '\r\n');
%     end
%
%     for i = 1:length(unique_coherence)
%         for j = 1:length(unique_direction)
%             sign = (unique_direction(j) == Pref_direction)*2 - 1;	%=1 if preferred disparity, -1 if null disparity
%             signed_corr = unique_coherence(i) * sign;
%             percent_pref = (length(pref_dist{i,j}) / (length(pref_dist{i,j})+length(null_dist{i,j})));
%
%             if ( (length(pref_dist{i,j}) > 0) & (length(null_dist{i,j}) > 0) )
%                 outstr1 = sprintf('%s %8.4f %8.6f %8.6f %8.6f', FILE, signed_corr, percent_pref, choice_prob(i, j), choice_prob_Pval(i, j));
%                 fprintf(fid, '%s', outstr1);
%                 fprintf(fid, '\r\n');
%             end
%         end
%     end
%     fclose(fid);
% end
%
% %------------------------------------------------------------------------------------------------------------------
% % write out preferred and null CP for each correlation level. Only use when the calculation of CP at each correlation level
% % is done with ROC_significance_test not rocN  TU 09/08/02
% output1 = 0;
% if (output1)
%     outfile1 = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\CP_prefnull.dat'];
%
%     printflag = 0;
%     if (exist(outfile1, 'file') == 0)    %file does not yet exist
%         printflag = 1;
%     end
%     fid = fopen(outfile1, 'a');
%     if (printflag)
%         fprintf(fid, 'File BinCorr CPpref CPnull');
%         fprintf(fid, '\r\n');
%     end
%
%     for i = 1:length(unique_coherence)
%         pref_index = find(unique_direction == Pref_direction);
%         null_index = find(unique_direction ~= Pref_direction);
%         percent_pref1 = (length(pref_dist{i,pref_index}) / (length(pref_dist{i,pref_index})+length(null_dist{i,pref_index})));
%         percent_pref2 = (length(pref_dist{i,null_index}) / (length(pref_dist{i,null_index})+length(null_dist{i,null_index})));
%
%         if ( (length(pref_dist{i,pref_index}) > 0) & (length(null_dist{i,pref_index}) > 0) & (length(pref_dist{i,null_index}) > 0) & (length(null_dist{i,null_index}) > 0))
%             outstr1 = sprintf('%s %8.4f %8.6f %8.6f %8.6f %8.6f %8.6f', FILE, unique_coherence(i), percent_pref1, choice_prob(i, pref_index), percent_pref2, choice_prob(i, null_index));
%             fprintf(fid, '%s', outstr1);
%             fprintf(fid, '\r\n');
%         end
%     end
%     fclose(fid);
% end
%
% return;
%
%
% %-----------------------------------------------------------------------------------------------------------------
% % write out data to analyze Z-scored spikes and vergence angle with Origin. Only use when CORRECT_FOR_VERGENCE = 1.   TU 03/14/02
% outfile = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\CPverg_example.dat'];
%
% printflag = 0;
% if (exist(outfile, 'file') == 0)    %file does not yet exist
%     printflag = 1;
% end
% fid = fopen(outfile, 'a');
% if (printflag)
%     fprintf(fid, 'Trial VergAngle ZSpike Residual Choice ');
%     fprintf(fid, '\r\n');
% end
%
% for i = 1:length(coherence)
%             outstr1 = sprintf('%8.6f %8.6f %8.6f %8.6f %8.6f', trials(i), calib_h_verg(i), Z_Spikes(i), r(i), choice(i));
%             fprintf(fid, '%s', outstr1);
%             fprintf(fid, '\r\n');
% end
%
% fclose(fid);
%
% %-----------------------------------------------------------------------------------------------------------------
% % write out data to analyze Z-scored spikes with Origin. Only use when CORRECT_FOR_SLOW_SPIKE_RATE_CHANGE = 1.   TU 08/09/01
% i = size(PATH,2) - 1;
% while PATH(i) ~='\'	%Analysis directory is one branch below Raw Data Dir
%     i = i - 1;
% end
% PATHOUT = [PATH(1:i) 'Analysis\Temp\'];
% outfile1 = [PATHOUT 'ZSpike.dat'];
%
% printflag = 0;
% if (exist(outfile1, 'file') == 0)    %file does not yet exist
%     printflag = 1;
% end
% fid = fopen(outfile1, 'a');
% if (printflag)
%     fprintf(fid, 'ZSpike Trial SignedBinCorr Choice');
%     fprintf(fid, '\r\n');
% end
%
% for i = 1:length(coherence)
%             outstr1 = sprintf('%8.4f %8.6f %8.6f %8.6f', Z_Spikes(i), trials(i), signed_coherence(i), choice(i));
%             fprintf(fid, '%s', outstr1);
%             fprintf(fid, '\r\n');
% end
%
% fclose(fid);
%
% %-----------------------------------------------------------------------------------------------------------------
% % write out data to analyze Z-scored spikes with Origin. Only use when CORRECT_FOR_SLOW_SPIKE_RATE_CHANGE = 1.   TU 08/09/01
% outfile1 = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\ZSpike.dat'];
%
% printflag = 0;
% if (exist(outfile1, 'file') == 0)    %file does not yet exist
%     printflag = 1;
% end
% fid = fopen(outfile1, 'a');
% if (printflag)
%     fprintf(fid, 'B BINT BINT PValue');
%     fprintf(fid, '\r\n');
% end
%
% outstr1 = sprintf('%8.6f %8.6f %8.6f %8.6f', b(1), bint(1,1), bint(1,2), stats(3));
% fprintf(fid, '%s', outstr1);
% fprintf(fid, '\r\n');
%
% fclose(fid);
