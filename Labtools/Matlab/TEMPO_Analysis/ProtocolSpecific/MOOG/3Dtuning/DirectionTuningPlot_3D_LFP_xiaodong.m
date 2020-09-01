% DirectionTuningPlot_3D.m -- Plots response as a function of azimuth and elevation for MOOG 3D tuning expt
%--	YONG, 12/10/08  
%-----------------------------------------------------------------------------------------------------------------------
function DirectionTuningPlot_3D_LFP_xiaodong(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

TEMPO_Defs;
Path_Defs;
ProtocolDefs; %contains protocol specific keywords - 1/4/01 BJP

%get the column of values for azimuth and elevation and stim_type
temp_azimuth = data.moog_params(AZIMUTH,:,MOOG);
temp_elevation = data.moog_params(ELEVATION,:,MOOG);
temp_stim_type = data.moog_params(STIM_TYPE,:,MOOG);
temp_amplitude = data.moog_params(AMPLITUDE,:,MOOG);
temp_duration = data.moog_params(DURATION,:,MOOG);
temp_spike_data = data.spike_data(SpikeChan, :);

%now, get the firing rates for all the trials 
temp_spike_rates = data.spike_rates(SpikeChan, :);                                                                                                                             

%get indices of any NULL conditions (for measuring spontaneous activity
null_trials = logical( (temp_azimuth == data.one_time_params(NULL_VALUE)) );

%now, remove trials from direction and spike_rates that do not fall between BegTrial and EndTrial
trials = 1:length(temp_azimuth);		% a vector of trial indices
bad_tri = find(temp_spike_rates > 3000);   % cut off 3k frequency which definately is not cell's firing response
if ( bad_tri ~= NaN)
   select_trials= ( (trials >= BegTrial) & (trials <= EndTrial) & (trials~=bad_tri) );
else 
   select_trials= ( (trials >= BegTrial) & (trials <= EndTrial) ); 
end

azimuth = temp_azimuth(~null_trials & select_trials);
elevation = temp_elevation(~null_trials & select_trials);
stim_type = temp_stim_type(~null_trials & select_trials);
amplitude = temp_amplitude(~null_trials & select_trials);
duration = temp_duration(~null_trials & select_trials);
spike_rates = temp_spike_rates(~null_trials & select_trials);

unique_azimuth = munique(azimuth');
unique_elevation = munique(elevation');
unique_stim_type = munique(stim_type');
unique_amplitude = munique(amplitude');
unique_duration = munique(duration');

condition_num = stim_type;
h_title{1}='Vestibular';
h_title{2}='Visual';
h_title{3}='Combined';
unique_condition_num = munique(condition_num');

Discard_trials = find(null_trials==1 | trials <BegTrial | trials >EndTrial);
for i = 1 : length(Discard_trials)
    temp_spike_data( 1, ((Discard_trials(i)-1)*5000+1) :  Discard_trials(i)*5000 ) = 9999;
end
spike_data(1,:) = temp_spike_data( 1, find(temp_spike_data(1,:)~=9999) );
spike_data(1, find(spike_data>10) ) = 1; % something is absolutely wrong 
StartEventBin(1)=996;
for ss =  1 : length(spike_rates) % ss marks the index of trial
    if unique_duration == 2000
        % use the middle 1 second
        spike_rates(ss) = sum( spike_data(1,StartEventBin(1)+500+5000*(ss-1) : StartEventBin(1)+1500+5000*(ss-1)) ) ; 
    elseif unique_duration == 1000
        % use the whole 1 second
        spike_rates(ss) = sum( spike_data(1,StartEventBin(1)+0+5000*(ss-1) : StartEventBin(1)+1000+5000*(ss-1)) ) ; 
    end
end

% calculate spontaneous firing rate
spon_found = find(null_trials==1); 
spon_resp = mean(temp_spike_rates(spon_found))
% added by Katsu 111606
spon_std = std(temp_spike_rates(spon_found))

% plot option, if regular plot, set to 0, if lambert plot, set to 1
% lamber_plot = 0;  % regular plot with elevation in a linear step
lamber_plot = 1; % lambert plot with elevation in a sin-transformed way

repetition = floor( length(azimuth) / (26*length(unique_stim_type)) );

resp_mat = [];
for k=1: length(unique_condition_num)
    pc=0;
    for j=1:length(unique_elevation)
        for i=1:length(unique_azimuth)        
            select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) );
            if (sum(select) > 0)  
                pc = pc+1;
                resp_mat(k, j, i) = mean(spike_rates(select));
                resp_mat_vector(k, j, i) = mean(spike_rates(select)); % for vector sum only                   
                spike_temp = spike_rates(select);
                resp_trial_anova1{k}(1:repetition,pc) =  spike_temp(1:repetition);    % for later anova use
                resp_mat_std(k, j, i) = std(spike_rates(select));     % calculate std between trials for later DSI usage
                resp_mat_ste(k, j, i) = resp_mat_std(k, j, i)/ sqrt(length(find( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j))&(condition_num==unique_condition_num(k)) )) );
               
                % z-score data 
                z_dist = spike_rates(select);
                if std(z_dist)~=0 % there are cases that all values are 0 for a certain condition, e.g. m2c73r1, visual condition
                   z_dist = (z_dist - mean(z_dist))/std(z_dist);
                else
                    z_dist = 0;
                end
                Z_Spikes(select) = z_dist; 
                resp_z{j,i} = z_dist;
            else
%                resp_mat_trial{k}(t, j, i) = 0;
                resp_mat(k, j, i) = resp_mat(k,j,1);
                resp_mat_vector(k,j,i) =0; % for vector sum only
                resp_mat_std(k, j, i) = 0;
                resp_mat_ste(k, j, i) = 0;
                resp_z{j,i} = resp_z{j,1};
            end
        end        
    end    
    P_anova(k) =  anova1( resp_trial_anova1{k}(:,:),'','off' ); 
end
m{1}='b.-'; 
m{2}='rx-'; m{3}='ro-'; m{4}='r+-'; m{5}='rd-'; m{6}='rs-'; m{7}='rv-'; m{8}='r*-'; m{9}='r.-';
m{10}='gx-'; m{11}='go-'; m{12}='g+-'; m{13}='gd-'; m{14}='gs-'; m{15}='gv-'; m{16}='g*-'; m{17}='g.-';
m{18}='kx-'; m{19}='ko-'; m{20}='k+-'; m{21}='kd-'; m{22}='ks-'; m{23}='kv-'; m{24}='k*-'; m{25}='k.-';
m{26}='m.-'; 
figure(7);
n=0;
for j=1:26
   n = n+1;
   plot(resp_trial_anova1{1}(:, j), m{n});
   hold on;
end
%%%% Usually, axis azimuth from left is 270-225-180-135-90--0---90 %%%% 

unique_azimuth_s=[0 45 90 135 180 225 270 315];
temp=fliplr(unique_azimuth');unique_azimuth_plot=[temp(2:end) temp(1:2)];clear temp
%unique_azimuth_plot=[270 225 180 135 112.5 90 67.5 45 0 315 270];%unique_azimuth_plot=[270 225 180 135 90 45 0 315 270];

for i=1:length(unique_azimuth_plot)
    Index(i)=find(unique_azimuth==unique_azimuth_plot(i));
    resp_mat_tran(:,:,i) = resp_mat(:,:,Index(i));
end

% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate maximum and minimum firing rate
max_res = max(max(max(resp_mat)));
% max_vi_ve = max(max(max(resp_mat(2:3,:,:))));
min_res = min(min(min(resp_mat_tran)));

% Define figure
xoffset=0;
yoffset=0;
figure(2);clf;
set(2,'Position', [5,15 980,650], 'Name', '3D Direction Tuning');
orient landscape;
%set(0, DefaultAxesXTickMode, 'manual', DefaultAxesYTickMode, 'manual', 'DefaultAxesZTickMode', 'manual');
axis off;
% for cosine plot
%---------YOng's Cosine Plot------------Now disable by Katsu, 05/22/06
azi_cos = [1,2,3,4,5,6,7,8,9];
ele_sin = [-1,-0.707,0,0.707,1];
%
for k=1: length(unique_condition_num) 
    
    if( xoffset > 0.5)          % now temperarily 2 pictures one row and 2 one column
        yoffset = yoffset-0.4;
        xoffset = 0;
    end
    axes('position',[0.11+xoffset 0.54+yoffset 0.32 0.24]);

    if lamber_plot ==1
         contourf( azi_cos, ele_sin, squeeze( resp_mat_tran(k,:,:)) );
    elseif lamber_plot ==0
         contourf( squeeze( resp_mat_tran(k,:,:)) ); 
    end
    % set the same scale for visual and combined conditions but here assuming vestibular response is always smaller than that in visual and
    % combined conditions
%     if ( k==2 | k==3 )
%   caxis([min_res, max_res]);
%     end
% if ( k==1 )           % Katsu for paper settle for m2c467
%caxis([20, 60]);
% end
% if ( k==2 )
% caxis([0, 36]);
% end
% % % % make scale changes here.
% if ( k==1 )           % Katsu for paper settle for m3c296
% caxis([40, 120]);
% end
% if ( k==2 )
%  caxis([40, 120]); %changes the scale so that they can be the same for vis and vest.
% end
    colorbar;
    % make 0 correspond to rightward and 180 correspond to leftward
    set(gca, 'ydir' , 'reverse');
    set(gca, 'xtick', [] );
    set(gca, 'ytick', [] );    
    title( h_title{k} );

    % plot 1-D for mean respond as a function of elevation
    % notice that elevation scale is transformed by consine
    axes('position',[0.06+xoffset 0.54+yoffset 0.04 0.24]);
%     set(gca, 'xtick', [] );
%     set(gca, 'ytick', [] );  
    for j=1:length(unique_elevation)
        y_elevation_mean(1,j)=mean(resp_mat_tran(k,j,:));
        y_elevation_std(1,j) =std( spike_rates([find( (elevation==unique_elevation(j))&(condition_num==unique_condition_num(k)) )]) );
        y_elevation_ste(1,j) =y_elevation_std(1,j)/ sqrt(length(find( (elevation==unique_elevation(j))&(condition_num==unique_condition_num(k)) )) );
    end
    if lamber_plot == 1
        x_elevation=[-1,-0.707,0,0.707,1]; %uncomment for cosine plot
    elseif lamber_plot ==0
        x_elevation=unique_elevation;%05/22/06 Katsu changed not cosin axis
    end
    errorbar(x_elevation,y_elevation_mean,y_elevation_ste,'ko-');%-----------Temporaly disable

    xlabel('Elevation');
    view(90,90);
    set(gca, 'xtick',x_elevation);
    if lamber_plot == 1
       xlim([-1, 1]);
       set(gca, 'XTickMode','manual');
       set(gca, 'xtick',[-1,-0.707,0,0.707,1]);
       set(gca, 'xticklabel','-90|-45|0|45|90'); 
    elseif lamber_plot ==0
       xlim([-90, 90]);
    end
    ylim([min(y_elevation_mean(1,:))-max(y_elevation_ste(1,:)), max(y_elevation_mean(1,:))+max(y_elevation_ste(1,:))]);%axis off %----------Now add axis off

    % plot 1-D for mean respond as a function of azimuth
    axes('position',[0.11+xoffset 0.46+yoffset 0.274 0.06]);
    for i=1:(length(unique_azimuth_s) )
        y_azimuth_mean(1,i)=mean(resp_mat_tran(k,:,i));
        y_azimuth_std(1,i) =std( spike_rates([find( (azimuth==unique_azimuth_s(i))&(condition_num==unique_condition_num(k)) )]) );
        y_azimuth_ste(1,i) =y_azimuth_std(1,i)/ sqrt(length(find( (azimuth==unique_azimuth_s(i))&(condition_num==unique_condition_num(k)) )) );    
    end
    y_azimuth_mean(1,9) = mean(resp_mat_tran(k,:,1));
    for i=1:( length(unique_azimuth_s)+1 )
        if (i < 8)        
            y_azimuth_ste_tran(1,i) = y_azimuth_ste(1,8-i);
        elseif (i == 8)
            y_azimuth_ste_tran(1,i) = y_azimuth_ste(1,8);
        else
            y_azimuth_ste_tran(1,i) = y_azimuth_ste(1,7);
        end
    end
    x_azimuth=1:(length(unique_azimuth_s)+1);
    errorbar(x_azimuth,y_azimuth_mean,y_azimuth_ste_tran,'ko-');%----------------temporaly disable
%     errorbar(x_azimuth,y_azimuth_mean,y_azimuth_ste_tran,'k-');% Katsu for paper settle for m3c294
    xlim( [1, length(unique_azimuth)+1] );
%     xlim( [0.9, length(unique_azimuth_s)+1.1] );
    set(gca, 'XTickMode','manual');
    set(gca, 'xtick',[1,2,3,4,5,6,7,8,9]);
    set(gca, 'xticklabel','270|225|180|135|90|45|0|-45|-90'); % Katsu
%     set(gca, 'xticklabel','0|45|90|135|180|225|270|315|360'); 
    xlabel('Azimuth');
    ylim([min(y_azimuth_mean(1,:))-max(y_azimuth_ste(1,:)), max(y_azimuth_mean(1,:))+max(y_azimuth_ste(1,:))]);%axis off %----------Now add axis off

    xoffset=xoffset+0.48;
    
    % calculate min and max firing rate, standard deviation, HTI, Vectorsum
    Min_resp(k) = min( min( resp_mat_tran(k,:,:)) );
    Max_resp(k) = max( max( resp_mat_tran(k,:,:)) );
    resp_std(k) = sum( sum(resp_mat_std(k,:,:)) ) / 26;  % notice that do not use mean here, its 26 vectors intead of 40
    M=squeeze(resp_mat(k,:,:));     % notice that here DSI should use resp_temp without 0 value set manually
    % this part is to calculate vestibular gain
    resp_onedim{k} = [M(1,1),M(2,:),M(3,:),M(4,:),M(5,1)]';     % hard-code temperarilly    
    N=squeeze(resp_mat_vector(k,:,:));      % notice that here vectorsum should use resp_mat with 0 value set manually 
    [Azi, Ele, Amp] = vectorsum(N);
    Vec_sum{k}=[Azi, Ele];
    % Heading Tuning Index
    r(k) = HTI(M,spon_resp);   % call HTI function  
    DDI(k) = (Max_resp(k)-Min_resp(k))/(Max_resp(k)+Min_resp(k)+resp_std(k));
end

% % calculate vestibular gain by a*ves=comb-vis
% if (length(unique_stim_type) == 3)
%    [bb,bint,rr,rint,stats] = regress( (resp_onedim{3}-resp_onedim{2}), [ones(vector_num,1),(resp_onedim{1}-spon_resp)] );    % with offset
%    gain = bb(2);
% else
%    gain = NaN;
% end

% % linear sum model
% A=[]; B=[]; Aeq=[]; Beq=[]; NONLCON=[];
% OPTIONS = optimset('fmincon');
% OPTIONS = optimset('LargeScale', 'off', 'LevenbergMarquardt', 'on', 'MaxIter', 5000, 'Display', 'off');
% 
% yy1 = @(x)sum( (resp_onedim{1}*x(1)+resp_onedim{2}*x(2)+x(3)-resp_onedim{3}).^2 );  %w1*ve+w2*vi
% es1 = [0.5,0.5,0];
% LB1 = [-5,5,0];
% UB1 = [-5,5,100];
% 
% v1 = fmincon(yy1,es1,A,B,Aeq,Beq,LB1,UB1, NONLCON, OPTIONS); % fminsearch        

% %-------------------------------------------------------------------
%check significance of HTI and calculate p value, do bootstrap at the same time to test value varience
perm_num=1000;
bin = 0.005;
spike_rates_perm = [];
for n=1: perm_num
    % this is permuted based on trials
    for k=1:length(unique_condition_num)   
        spike_rates_pe{k} = spike_rates( find( condition_num==unique_condition_num(k) ) );
        spike_rates_pe{k} = spike_rates_pe{k}( randperm(length(spike_rates_pe{k})) );
    end

    % put permuted data back to spike_rates
    spike_rates_perm(length(spike_rates))=0;
    for k=1:length(unique_condition_num) 
        ii = find(stim_type == unique_stim_type(k));
        spike_rates_perm(ii) = spike_rates_pe{k};
    end
    
    % re-creat a matrix similar as resp_mat              
    resp_vector_perm = [];
    for i=1:length(unique_azimuth)
        for j=1:length(unique_elevation)
            for k=1:length(unique_condition_num)
                select = logical((azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) );
                if (sum(select) > 0)
                    resp_mat_perm(k,j,i) = mean(spike_rates_perm(select));
                    resp_mat_perm_std(k,j,i) = std(spike_rates_perm(select));
                else
                    resp_mat_perm(k,j,i) = 0;
                    resp_mat_perm_std(k,j,i) = 0;
                end
            end        
        end
    end
    
    % re-calculate HTI now
    for k=1: length(unique_condition_num)
 %       resp_perm_std(k) = sum( sum(resp_mat_perm_std(k,:,:)) ) / vector_num; 
        M_perm=squeeze(resp_mat_perm(k,:,:));
        r_perm(k,n) = HTI(M_perm, spon_resp); 
        Min_resp_perm = min( min( resp_mat_perm(k,:,:)) );
        Max_resp_perm = max( max( resp_mat_perm(k,:,:)) );
        resp_std_perm = sum( sum(resp_mat_perm_std(k,:,:)) ) / 26;  % notice that do not use mean here, its 26 vectors intead of 40
        DDI_perm(k,n) = (Max_resp_perm-Min_resp_perm)/(Max_resp_perm+Min_resp_perm+resp_std_perm);
    end

end
% now calculate p value or significant test
for k = 1 : length(unique_condition_num)
    p(k) = length(find(r_perm(k,:)>=r(k)) )/perm_num;   % calculate p value for HTI
    p_DDI(k) = length(find( DDI_perm(k,:)>=DDI(k)) )/perm_num;
end

 %----------------------------------------------------------------------------
% Now show vectorsum, DSI, p and spontaneous at the top of figure
axes('position',[0.05,0.85, 0.9,0.1] );
xlim( [0,100] );
ylim( [0,length(unique_condition_num)+1] );
h_spon = num2str(spon_resp);
text(0, length(unique_condition_num)+1, FILE);
text(20, length(unique_condition_num)+1, 'SpikeChan=');
text(30, length(unique_condition_num)+1, num2str(SpikeChan));
text(10,length(unique_condition_num),'Protocol       Spon   Minimum  Maximum   Azi     Ele      HTI        p         DDI        p-ANOVA');
for k=1:length(unique_condition_num) 
    h_text{k}=num2str( [spon_resp, Min_resp(k), Max_resp(k), Vec_sum{k}, r(k), p(k), DDI(k), P_anova(k)] );
    text(0,length(unique_condition_num)-k,h_title{unique_stim_type(k)});
    text(10,length(unique_condition_num)-k,'Translation');
    text(20,length(unique_condition_num)-k, h_text{k} );
end

axis off;

%---------------------------------------------------------------------------------------
%Also, write out some summary data to a cumulative summary file
buff = sprintf('%s\t %4.2f\t   %4.3f\t   %4.3f\t   %4.3f\t   %4.3f\t  %4.3f\t  %4.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %2.4f\t  %2.4f\t  %2.4f\t  %2.4f\t  %2.4f\t  %2.4f\t  %1.3f\t  %1.3f\t  %1.3f\t  %2.4f\t  %2.4f\t  %2.4f\t  %2.4f\t  %2.4f\t  %2.4f\t  %2.4f\t  %2.4f\t  %2.4f\t  %2.4f\t', ...
     FILE, spon_resp, Min_resp, Max_resp, Vec_sum{:}, r, p(:), DDI(:), P_anova );

outfile = ['Z:\Users\Yong\FEF\3D_Direction_Tuning_batch.dat']; 
printflag = 0;
if (exist(outfile, 'file') == 0)    %file does not yet exist
    printflag = 1;
end
fid = fopen(outfile, 'a');
if (printflag)
%     fprintf(fid, 'FILE\t         SPon\t Veb_min\t Vis_min\t Comb_min\t Veb_max\t Vis_max\t Comb_max\t Veb_azi\t Veb_ele\t Veb_amp\t Vis_azi\t Vis_ele\t Vis_amp\t Comb_azi\t Comb_ele\t Comb_amp\t Veb_HTI\t Vis_HTI\t Comb_HTI\t Veb_HTIerr\t Vis_HTIerr\t Comb_HTIerr\t Veb_P\t Vis_P\t Comb_P\t Veb_std\t Vis_std\t Comb_std\t gain\t F_anova\t P_anova\t Veb_DDI\t Vis_DDI\t Com_DDI\t Veb_var_term\t Vis_var_term\t Com_var_term\t');
    fprintf(fid, 'FILE\t SPon\t');
    fprintf(fid, '\r\n');
end
fprintf(fid, '%s', buff);
fprintf(fid, '\r\n');
fclose(fid);

return;
