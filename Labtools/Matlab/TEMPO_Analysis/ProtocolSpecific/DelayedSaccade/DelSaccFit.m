%-----------------------------------------------------------------------------------------------------------------------
%-- DelSaccFit.m -- Plots the response during the delayed saccade task versus spatial position 
%--                 and estimates a center of the response field.
%--	VR, 7/14/06 
%-----------------------------------------------------------------------------------------------------------------------

function DelSaccFit(data, Protocol, Analysis, SpikeChan, SpikeChan2, StartCode, StopCode, BegTrial, EndTrial, StartOffsetBin, StopOffsetBin, StartEventBin, StopEventBin, PATH, FILE);

TEMPO_defs;
ProtocolDefs;

%get delay period target brightness
targ_dimmer = data.one_time_params(TARG_DIMMER);

%get angle values (deg)
angle = data.dots_params(DOTS_DIREC,:,PATCH1); 
angle = squeeze_angle(angle);
unique_angle = munique(angle');

%get eccentricity (radius) values - stored in dummy variable DOTS_AP_XCTR
rad = data.dots_params(DOTS_AP_XCTR,:,PATCH1);
unique_rad = munique(rad');

%make list of trials
trials = 1:length(angle);
select_trials = logical (data.misc_params(OUTCOME,BegTrial:EndTrial) == CORRECT);

timing_offset = 71; %in ms, time between TARGS_ON_CD and detectable target on screen; only use this for aligning to target onset
%get firing rates for delay period (VSTIM_OFF:FP_OFF) and saccade (FP:IN_T1_WIN)
delay_rates = data.spike_rates(SpikeChan,:);
for i = trials
    trialdata = data.event_data(1,:,i);
    if ( sum(trialdata == TARGS_ON_CD) & sum(trialdata == VSTIM_OFF_CD) & ...
         sum(trialdata == FP_OFF_CD) & sum(trialdata == IN_T1_WIN_CD) )
        targ_on(i) = find(data.event_data(1,:,i) == TARGS_ON_CD) + timing_offset;
        delay_start(i) = find(data.event_data(1,:,i) == VSTIM_OFF_CD) + timing_offset;
        fix_off(i) = find(data.event_data(1,:,i) == FP_OFF_CD) + timing_offset;
        in_T1(i) = find(data.event_data(1,:,i) == IN_T1_WIN_CD,1,'last');
        delay_rates(i) = sum(data.spike_data(SpikeChan, delay_start(i):fix_off(i), i)) / length(delay_start(i):fix_off(i)) * 1000;
        sacc_rates(i) = sum(data.spike_data(SpikeChan, fix_off(i):in_T1(i), i)) / length(fix_off(i):in_T1(i)) * 1000;
    else
        select_trials(i) == 0;
    end
end

%note some times
delay_period = mean(fix_off-targ_on);

%now plot the delay_rates
figh(1) = figure;
set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [150 100 500 573], 'Name', sprintf('%s: Delay Period RF Map',FILE));
% subplot(411);
% PrintGeneralData(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffsetBin, StopOffsetBin, PATH, FILE);
subplot(411); hold on;

% %some temporary stuff for testing timing
% for i = 1:length(trials)
% sync(i) = find(data.spike_data(2,:,i)~=0,1);
% stimstart(i) = find(data.event_data(1,:,i)==VSTIM_ON_CD);
% targson(i) = find(data.event_data(1,:,i)==TARGS_ON_CD);
% diode(i) = find(data.spike_data(1,:,i)~=0,1);
% end
% keyboard

% errorbar for varing radius
if (length(unique_angle) == 1) 
    %first compute rates
    for i = 1:length(unique_rad)
        py = delay_rates( (rad == unique_rad(i)) & select_trials );
        px = unique_rad(i).*ones(length(py),1);
        mean_delay_rate(i) = mean(py);
        std_delay_rate(i) = std(py);
        plot(px,py,'b*'); %change size of dots?
    end
    %now plot
    hold on;
    errorbar(unique_rad, mean_delay_rate, std_delay_rate, 'b-');
    xlabel('Radius (deg)'); ylabel('Firing Rate (Hz)');

% errorbar for varying angle
elseif (length(unique_rad) == 1) 
    %first compute rates
    for i = 1:length(unique_angle)
        py = delay_rates( (angle == unique_angle(i)) & select_trials );
        mean_delay_rate(i) = mean(py);
        std_delay_rate(i) = std(py);
    end
    plot_x = angle(select_trials);
    plot_y = delay_rates(select_trials);
    
    %now first shift the data so that the angle with the highest response
    %is in the middle of the distribution
    [m, max_ind] = max(mean_delay_rate);
    adjust_angle = unique_angle - 360.*(unique_angle-unique_angle(max_ind) > 180) + 360.*(unique_angle-unique_angle(max_ind) < -180);
    adjust_plot_x = plot_x - 360.*(plot_x-unique_angle(max_ind) > 180) + 360.*(plot_x-unique_angle(max_ind) < -180);
    
    %now plot
    hold on;
    plot(adjust_plot_x, plot_y, 'b*');
    errorbar(adjust_angle, mean_delay_rate, std_delay_rate, 'bo');
    %xlabel('Angle (deg)'); 
	ylabel('Firing Rate (Hz)');
    axis('tight');
    title(sprintf('%s: Full Delay Period tuning curve',FILE));
    
    %now fit the data to a gaussian and plot the result
    means = [adjust_angle mean_delay_rate'];
    raw = [adjust_plot_x' plot_y'];
    [pars] = gaussfit(means, raw, 0);   %last arg: allow positive going fit only
    x_interp = (getval(xlim,1): 0.5 : getval(xlim,2));
    y_interp = gaussfunc(x_interp - 360.*(x_interp-unique_angle(max_ind) > 180) + 360.*(x_interp-unique_angle(max_ind) < -180),pars);
    plot(x_interp, y_interp, 'r-');
    
    %now filter the data and plot the responses
    stddev = 15; %std dev of gaussian filter, in ms
    buff = 3*stddev 
    gaussfilt = normpdf([1:2*buff+1],buff+1,stddev); %gaussian filter 3 std.dev's wide
    for i = 1:length(unique_angle)
        select = trials(select_trials & (angle == unique_angle(i)));
        for j = 1:length(select)
            infix = find(data.event_data(1,:,select(j))==IN_FIX_WIN_CD,1,'last');
            fixoff{i}(j) = find(data.event_data(1,:,select(j))==VSTIM_OFF_CD,1,'last');
            leavefix = find(data.event_data(1,:,select(j))==SACCADE_BEGIN_CD,1,'last');
            peritarg_rasters{i}(j,:) = data.spike_data(SpikeChan, infix-buff:infix+1525+buff, select(j));
            perisacc_rasters{i}(j,:) = data.spike_data(SpikeChan, leavefix-500-buff:leavefix+300+buff, select(j));
        end
        peritarg_psth{i} = sum(peritarg_rasters{i},1)./length(select).*1000; %psth is NOT binned
        sm_peritarg_psth{i} = conv(gaussfilt,peritarg_psth{i}); %convolve with the gaussian
        sm_peritarg_psth{i} = sm_peritarg_psth{i}(2*buff+1:end-2*buff); %lop off the edges
        perisacc_psth{i} = sum(perisacc_rasters{i},1)./length(select).*1000;
        sm_perisacc_psth{i} = conv(gaussfilt,perisacc_psth{i});
        sm_perisacc_psth{i} = sm_perisacc_psth{i}(2*buff+1:end-2*buff);
    end
    peritarg_x = [-100:1425];
    perisacc_x = [-500:300];
%     %now make some psths - OLD METHOD
%     binwidth = 40;
%     for i=1:length(unique_angle)
%         select = trials(select_trials & (angle == unique_angle(i)));
%         for j = 1:length(select)
%             infix = find(data.event_data(1,:,select(j))==IN_FIX_WIN_CD);
%             fixoff{i}(j) =
%             find(data.event_data(1,:,select(j))==VSTIM_OFF_CD);
%             leavefix = find(data.event_data(1,:,select(j))==SACCADE_BEGIN_CD);
%             [bins binned_rasters{i}(j,:)] = spikebinner(data.spike_data(SpikeChan, infix:infix+1525, select(j)), 1, binwidth, 100);
%             [perisacc_bins perisacc_binned_rasters{i}(j,:)] = spikebinner(data.spike_data(SpikeChan, leavefix-500:leavefix+200, select(j)), 1, binwidth, 500);
%         end
%         psth(i,:) = sum(binned_rasters{i},1)./length(select)./binwidth.*1000;
%         perisacc_psth(i,:) = sum(perisacc_binned_rasters{i},1)./length(select)./binwidth.*1000;
%     end
    %plot these psths on one graph
    subplot(413); hold on;
    cm = colormap(hsv);
    spacer = floor(size(cm,1)/length(unique_angle));
    linecolors = cm(1:spacer:size(cm,1),:);
    legstr = 'legend(legh,';
    for i = 1:length(unique_angle)
        legh(i) = plot(peritarg_x,sm_peritarg_psth{i},'Color',linecolors(i,:));
        legstr = strcat(legstr,sprintf('''%d'',',unique_angle(i)));
    end
    set(legh(max_ind),'LineWidth',1.5)
    legstr = strcat(legstr,'''Location'',''EastOutside'');');
    %eval(legstr);
    xlabel('Time About Target Onset');
    ylabel('F.R.(Hz)');
    axis('tight');
    plot([0 0],ylim,'k');
    plot([800 800],ylim,'k:')
    subplot(411); hold on;
    for i = 1:length(unique_angle)
        plot([adjust_angle(i)-5 adjust_angle(i)+5],[max(ylim) max(ylim)],'Color',linecolors(i,:),'LineWidth',4);
    end
    %now plot the perisacc psths on one graph
    subplot(414); hold on;
    for i = 1:length(unique_angle)
        legh2(i) = plot(perisacc_x,sm_perisacc_psth{i},'Color',linecolors(i,:));
    end
    set(legh2(max_ind),'LineWidth',1.5)
    xlabel('Time About Saccade Onset'); 
    ylabel('F.R.(Hz)');
    axis('tight');
    plot([0 0],ylim,'k');
    
    %keyboard
    %now compute and plot the tuning curve based on late delay data (last 300ms of delay)
    %first compute rates
    late_delay_rates = zeros(size(delay_rates));
    for i = 1:length(trials)
        if select_trials(i)
            late_delay_rates(i) = sum(data.spike_data(SpikeChan, fix_off(i)-300:fix_off(i), i)) / 301 * 1000;
        end
    end
    for i = 1:length(unique_angle)
        py = late_delay_rates( (angle == unique_angle(i)) & select_trials );
        mean_late_delay_rate(i) = mean(py);
        std_late_delay_rate(i) = std(py);
    end
    plot_y = late_delay_rates(select_trials);
%     keyboard
    subplot(412);hold on;
    plot(adjust_plot_x, plot_y, 'b*');
    errorbar(adjust_angle, mean_late_delay_rate, std_late_delay_rate, 'bo');
    axis('tight')
    xlabel('Angle (deg)'); ylabel('Firing Rate (Hz)');
    title('Last 300ms of Delay Period tuning curve');
        
    %now fit the data to a gaussian and plot the result
    means = [adjust_angle mean_late_delay_rate'];
    raw = [adjust_plot_x' plot_y'];
    [pars] = gaussfit(means, raw, 0);   %last arg: allow positive going fit only
    x_interp = (getval(xlim,1): 0.5 : getval(xlim,2));
    y_interp = gaussfunc(x_interp - 360.*(x_interp-unique_angle(max_ind) > 180) + 360.*(x_interp-unique_angle(max_ind) < -180),pars);
    plot(x_interp, y_interp, 'r-');
    
%     keyboard



% 2d colored scatter plot
else                        
    subplot(311);hold on;
    %first, convert polar coordinates into cartesian
    [xpos ypos] = pol2cart(angle.*pi./180, rad);
    xpos = round(1e6.*xpos)./1e6;  
    ypos = round(1e6.*ypos)./1e6;  
    unique_pos = munique([xpos' ypos']); %combining since xpos and ypos are not independent
    
    %next compute mean firing rate at each location
    for i = 1:size(unique_pos,1)
        tempx = unique_pos(i,1);   
        tempy = unique_pos(i,2);
        mean_delay_rate(i) = mean(delay_rates( (xpos==tempx) & (ypos==tempy) & select_trials ));
        std_delay_rate(i) = std(delay_rates( (xpos==tempx) & (ypos==tempy) & select_trials ));
        mean_sacc_rate(i) = mean(sacc_rates( (xpos==tempx) & (ypos==tempy) & select_trials ));
        std_sacc_rate(i) = std(sacc_rates( (xpos==tempx) & (ypos==tempy) & select_trials ));
    end
    
    %now plot a colored/sized scatter plot
    delay_rate_size = 30+(mean_delay_rate-min(mean_delay_rate))./(max(mean_delay_rate)-min(mean_delay_rate)).*170; %normalize size to range b/w 30 and 200
    temph = scatter(unique_pos(:,1), unique_pos(:,2), delay_rate_size, mean_delay_rate, 'MarkerFaceColor','flat')
    grid on;
    [mxspk,maxind] = max(mean_delay_rate);
    cb = colorbar; 
    xl = xlim; yl = ylim; %store the plot dimensions
    
    %now fit the firing rates in angle/rad space (NOT cartesian) space with a 2d gaussian 
%     figh(2) = figure;
%     subplot(211);  
    hold on;
    
    fitrates = [];
    for i = 1:length(unique_angle)
        for j = 1:length(unique_rad)
            fitrates(i,j) = mean(delay_rates( (angle==unique_angle(i)) & (rad == unique_rad(j)) & select_trials));
        end
    end
    %contourf(unique_angle, unique_rad, fitrates);
    %organize delay_rates by 
    [ang_list rad_list] = cart2pol(unique_pos(:,1),unique_pos(:,2));
    ang_list = ang_list./pi.*180;
    ang_list = squeeze_angle(ang_list);
    ang_list = 1e-4.*round(1e4.*ang_list);
    rad_list = 1e-4.*round(1e4.*rad_list);
    
    raw = [angle(select_trials)' rad(select_trials)' delay_rates(select_trials)'];
    means = [ang_list rad_list mean_delay_rate'];
    pars = gauss2Dfit(means,raw);
    pol_ctr = [pars(3) pars(5)]; %[angle(deg), ecc(deg)]
    [cart_ctr(1) cart_ctr(2)] = pol2cart(pars(3)/180*pi, pars(5)); %[x,y]
    title(sprintf('%s: Polar (%4.1f, %3.1f), Cart (%3.1f, %3.1f)',FILE, pol_ctr, cart_ctr))

    %create interpolated arrays for data display
    x_interp = [xl(1):0.5:xl(2)];
    y_interp = [yl(1):0.5:yl(2)];
    z_gauss = zeros(length(x_interp), length(y_interp));
    
    %obtain fitted data for interpolated arrays
    for i=1:length(x_interp)
        for j = 1:length(y_interp)
            [ang_temp rad_temp] = cart2pol(x_interp(i), y_interp(j));
            ang_temp = squeeze_angle(ang_temp/pi*180);
            z_gauss(i,j) =  gauss2Dfunc(ang_temp, rad_temp, pars);
        end
    end
    subplot(3,1,2);
    
    contourf(x_interp, y_interp, z_gauss')
    colorbar
%     axis ima

    %now plot rasters and psth for maximal condition.  
    
        %now filter the data and plot the responses
    stddev = 15; %std dev of gaussian filter, in ms
    buff = 3*stddev 
    gaussfilt = normpdf([1:2*buff+1],buff+1,stddev); %gaussian filter 3 std.dev's wide
    select = trials(select_trials & (xpos == unique_pos(maxind,1)) & (ypos == unique_pos(maxind,2)) );
    for j = 1:length(select)
        infix = find(data.event_data(1,:,select(j))==IN_FIX_WIN_CD,1,'last');
        fixoff = find(data.event_data(1,:,select(j))==VSTIM_OFF_CD,1,'last');
        leavefix = find(data.event_data(1,:,select(j))==SACCADE_BEGIN_CD,1,'last');
        maxperitarg_rasters(j,:) = data.spike_data(SpikeChan, infix-buff:infix+1525+buff, select(j));
        maxperisacc_rasters(j,:) = data.spike_data(SpikeChan, leavefix-500-buff:leavefix+300+buff, select(j));
    end
    maxperitarg_psth = sum(maxperitarg_rasters,1)./length(select).*1000; %psth is NOT binned
    maxsm_peritarg_psth = conv(gaussfilt,maxperitarg_psth); %convolve with the gaussian
    maxsm_peritarg_psth = maxsm_peritarg_psth(2*buff+1:end-2*buff); %lop off the edges
    maxperisacc_psth = sum(maxperisacc_rasters,1)./length(select).*1000;
    maxsm_perisacc_psth = conv(gaussfilt,maxperisacc_psth);
    maxsm_perisacc_psth = maxsm_perisacc_psth(2*buff+1:end-2*buff);

    peritarg_x = [-100:1425];
    perisacc_x = [-500:300];
    subplot(3,2,5); hold on;
    plot(peritarg_x, maxsm_peritarg_psth)
    xlabel('Time About Target Onset');
    ylabel('F.R.(Hz)');
    axis tight
    subplot(3,2,6); hold on;
    plot(perisacc_x, maxsm_perisacc_psth)
    xlabel('Time About Saccade Onset');
    ylabel('F.R.(Hz)');
    axis tight
%     subplot(313)
%     PrintGeneralData(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, 0, 0, PATH, FILE)
%     %now, print out some specific useful info.
%     xpos = 0; ypos = 10;
%     font_size = 10;
%     bump_size = 8;
%     line = sprintf('Target Dimmer = %3.2f', targ_dimmer);
%     text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;    

%     figure;
%     set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 50 500 573], 'Name', sprintf('%s: Delayed Saccade Fit',FILE));
%     subplot(211)
%     contourf(unique_angle, unique_rad, fitrates');
%     %contourf(ang_list, rad_list, mean_delay_rate');
%     colorbar;
%     title(sprintf('%s: Data',FILE));
%     subplot(212)
%     ang_interp = [min(ang_list):1:max(ang_list)];
%     rad_interp = [min(rad_list):1:max(rad_list)];
%     z_gauss2 = zeros(ang_interp, rad_interp);
%     for i=1:length(ang_interp)
%         for j=1:length(rad_interp)
%             z_gauss2(i,j) = gauss2dfunc(ang_interp(i), rad_interp(j), pars);
%         end
%     end
%     contourf(ang_interp, rad_interp, z_gauss2');
%     colorbar;
%     title(sprintf('Peak at (%5.1f, %5.1f)',pars(3), pars(5)));
%     
% %    keyboard
end



% keyboard;