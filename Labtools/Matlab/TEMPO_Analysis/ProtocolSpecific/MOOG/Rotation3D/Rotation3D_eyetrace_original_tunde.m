function Pursuit_eachCell_eyetrace(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE); 
%  original script from Rotation3D_eyetrace.m with a little modification.
%  I'm just keeping this to remind me of how the script was oritinally.
TEMPO_Defs;
Path_Defs;
ProtocolDefs; %contains protocol specific keywords - 1/4/01 BJP

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for figure writing , if running batch, comment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % From here RVOR/pursuit
% if size(data.eye_data,1)>6
%     LEFT_EYE_1_2=9;
%     RIGHT_EYE_3_4=10;
% else
%     LEFT_EYE_1_2=7;
%     RIGHT_EYE_3_4=8;
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %************************************************************************%
% %plot Vertical vs. Horizontal
% switch (data.eye_flag)
%     case (LEFT_EYE_1_2)
%         Eye_Select='Left Eye'
%         Hor=1;        Ver=2;
%     case(RIGHT_EYE_3_4)
%         Eye_Select='Right Eye'
%         Hor=3;        Ver=4;
% end
% % 




temp_azimuth = data.moog_params(ROT_AZIMUTH,:,MOOG);
temp_elevation = data.moog_params(ROT_ELEVATION,:,MOOG);
temp_stim_type = data.moog_params(STIM_TYPE,:,MOOG);
temp_spike_rates = data.spike_rates(SpikeChan, :); 
temp_total_trials = data.misc_params(OUTCOME, :);
temp_spike_data = data.spike_data(1,:);   % spike rasters
% temp_fp_rotate = data.moog_params(FP_ROTATE,:,MOOG);

% null_trials = logical( (temp_azimuth == data.one_time_params(NULL_VALUE)) );
null_trials = logical( (temp_elevation == data.one_time_params(NULL_VALUE)) );
%now, remove trials from direction and spike_rates that do not fall between BegTrial and EndTrial
% trials = 1:length(temp_azimuth);
trials = 1:length(temp_elevation);
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );
azimuth = temp_azimuth(~null_trials & select_trials);
elevation = temp_elevation(~null_trials & select_trials);
stim_type = temp_stim_type(~null_trials & select_trials);
spike_rates = temp_spike_rates(~null_trials & select_trials);
% fp_rotate = temp_fp_rotate(~null_trials & select_trials);

unique_azimuth = munique(azimuth');
unique_elevation = munique(elevation');
unique_stim_type = munique(stim_type');
% unique_fp_rotate = munique(fp_rotate');

% repeat = floor( length(temp_spike_rates) / (length(unique_stim_type)*(length(unique_fp_rotate)*(length(unique_elevation)-2)+2)+1) );
%Yong's bad Aihua's good for calculate repeat

trials_per_rep = (length(unique_azimuth)*length(unique_elevation)-14) * length(unique_stim_type) + 1;
repetition = floor( (EndTrial-(BegTrial-1)) / trials_per_rep);

%%%%%%%%%%%%%%  clear   %%%%%%%%%%%%%%%%%%%%%%%%% 
clear offset_x offset_y resp_x resp_y resp_x_up resp_y_up resp_x_down resp_y_down resp_x_left resp_y_left resp_x_right resp_y_right
clear eye_x_up eye_y_up eye_x_down eye_y_down eye_x_left eye_y_left eye_x_right eye_y_right mean_eye_x_up mean_eye_y_up mean_eye_x_down mean_eye_y_down mean_eye_x_left mean_eye_y_left mean_eye_x_right mean_eye_y_right
clear vis_eye_x_up vis_eye_y_up vis_eye_x_down vis_eye_y_down vis_eye_x_left vis_eye_y_left vis_eye_x_right vis_eye_y_right vis_mean_eye_x_up vis_mean_eye_y_up vis_mean_eye_x_down vis_mean_eye_y_down vis_mean_eye_x_left vis_mean_eye_y_left vis_mean_eye_x_right vis_mean_eye_y_right

for k = 1 : length(unique_stim_type)
   {'k =', k, 'unique_stim_type = ' , unique_stim_type(k)}
    for i = 1 : length(unique_azimuth)
        {'i =', i, 'unique_azi_type =', unique_azimuth(i)}
        for j = 1 : length(unique_elevation)
            {'j =', j, 'unique_ele', unique_elevation(j)}
            select = find( temp_azimuth==unique_azimuth(i) & temp_elevation==unique_elevation(j) & temp_stim_type==unique_stim_type(k) );
%           the above line "select = find ..." basically finds the indices/index where all the conditions are met 
%           i.e. the index/indices where temp_azimuth is equal to unique_azimuth(i), and so on... ---- Tunde
            if sum(select)>0
                for jj = 1 : repetition % for convenience with sacrefice of some of the trials
                    {'jj =', jj, 'repetition'}
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%%        select eye Right ch.3, 4 or Left ch.1, 2
                    %%%%        
% % %                Right Eye Old_Que, Zeblon, Lothar, Que_Laby, Zebu_Laby
%                     offset_x = mean( data.eye_data(3,201:300,select(jj)) ); % horizontal
%                     offset_y = mean( data.eye_data(4,201:300,select(jj)) ); % vertical
%                     resp_x{k,i,j}(jj,:) = data.eye_data(3,201:600,select(jj)) - offset_x;  % horizontal   
%                     resp_y{k,i,j}(jj,:) = data.eye_data(4,201:600,select(jj)) - offset_y;  %  

%                Left Eye Azrael, Lothar(after..), New_Que, but some eye data are destroyed !! use old cell for Que (see Translation) 
               %% and Lother left Eye
                    offset_x = mean( data.eye_data(1,201:300,select(jj)) ); % horizontal
                    offset_y = mean( data.eye_data(2,201:300,select(jj)) ); % vertical
                    resp_x{k,i,j}(jj,:) = data.eye_data(1,201:600,select(jj)) - offset_x;  % horizontal   
                    resp_y{k,i,j}(jj,:) = data.eye_data(2,201:600,select(jj)) - offset_y;  %
                    

%                Eye select (for figure wrinting)
%                     offset_x = mean( data.eye_data(Hor,201:300,select(jj)) ); % horizontal
%                     offset_y = mean( data.eye_data(Ver,201:300,select(jj)) ); % vertical
%                     resp_x{k,i,j}(jj,:) = data.eye_data(Hor,201:600,select(jj)) - offset_x;  % horizontal   
%                     resp_y{k,i,j}(jj,:) = data.eye_data(Ver,201:600,select(jj)) - offset_y;  % vertical
                end
            else
                resp_x{k,i,j}(:,:) = resp_x{k,1,j}(:,:);%??? +-90 elevation
                resp_y{k,i,j}(:,:) = resp_y{k,1,j}(:,:);
%                 this results in 
            end
        end
    end
    resp_x_up{k}(:,:) = resp_x{k,1,3}(:,:);     resp_y_up{k}(:,:) = resp_y{k,1,3}(:,:);
    resp_x_down{k}(:,:) = resp_x{k,5,3}(:,:);   resp_y_down{k}(:,:) = resp_y{k,5,3}(:,:);
    resp_x_left{k}(:,:) = resp_x{k,1,1}(:,:);   resp_y_left{k}(:,:) = resp_y{k,1,1}(:,:);
    resp_x_right{k}(:,:) = resp_x{k,1,5}(:,:);  resp_y_right{k}(:,:) = resp_y{k,1,5}(:,:); 

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% Difference between mean for repeatition and 201-600 should be
%%%%%%%% attention!!
% paper=0;

for k = 1 : length(unique_stim_type)
    
    eye_x_up(:,:)= resp_x_up{k}(:,101:300);% vestibular (k=1) only
    eye_y_up(:,:) = resp_y_up{k}(:,101:300);%(jj, 201-600) jj=repeatition, 400 points(1point=50ms)
    eye_x_down(:,:)= resp_x_down{k}(:,101:300);%middle 1 sec = 101:300
    eye_y_down(:,:) = resp_y_down{k}(:,101:300);
    eye_x_left(:,:)= resp_x_left{k}(:,101:300);
    eye_y_left(:,:)= resp_y_left{k}(:,101:300);
    eye_x_right(:,:)= resp_x_right{k}(:,101:300);
    eye_y_right(:,:)= resp_y_right{k}(:,101:300);
    
    mean_eye_x_up{k} = mean(eye_x_up(:,:)');
    mean_eye_y_up{k} = mean(eye_y_up(:,:)');
    mean_eye_x_down{k} = mean(eye_x_down(:,:)');
    mean_eye_y_down{k} = mean(eye_y_down(:,:)');
    mean_eye_x_left{k} = mean(eye_x_left(:,:)');
    mean_eye_y_left{k} = mean(eye_y_left(:,:)');
    mean_eye_x_right{k} = mean(eye_x_right(:,:)');
    mean_eye_y_right{k} = mean(eye_y_right(:,:)');
    
        %%%%% here plot figures %%%% commented
% figure(k+10);
% subplot(2,2,1);
% plot(mean_eye_x_up{k} ,'rx');hold on;plot(mean_eye_x_down{k} ,'ro');hold off;title('Hor / pitch Up (x) and Down(o)');ylim([-10 10]);
% subplot(2,2,2);
% plot(mean_eye_x_left{k} ,'rx');hold on;plot(mean_eye_x_right{k} ,'ro');hold off;title('Hor / yaw Left (x) and Right(o)');ylim([-10 10]);
% subplot(2,2,3);
% plot(mean_eye_y_up{k} ,'bx');hold on;plot(mean_eye_y_down{k} ,'bo');hold off;title('Ver / pitch Up (x) and Down(o)');ylim([-10 10]);
% subplot(2,2,4);
% plot(mean_eye_y_left{k} ,'bx');hold on;plot(mean_eye_y_right{k} ,'bo');hold off;title('Ver / yaw Left (x) and Right(o)');ylim([-10 10]);

end

% %% from here to line 646 is contouf plot and eye velocity
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%
% %%%           from tuning especially rotation3D_DDI perm
% %%%
% condition_num = stim_type;
% h_title{1}='Vestibular';
% h_title{2}='Visual';
% h_title{3}='Combined';
% unique_condition_num = munique(condition_num');
% 
% % calculate spontaneous firing rate
% spon_found = find(null_trials==1); 
% spon_resp = mean(temp_spike_rates(spon_found));
% % added by Katsu 111606
% spon_std = std(temp_spike_rates(spon_found))
% 
% % -------------------------------------------------------------------------
% %ANOVA modified by Aihua, it does not require whole trials, it does not matter if trial stopped during repetition
% trials_per_rep = (length(unique_azimuth)*length(unique_elevation)-14) * length(unique_condition_num) + 1;
% repetitions = floor( (EndTrial-(BegTrial-1)) / trials_per_rep);
% 
% % first parse raw data into repetitions, including null trials
% for q = 1:repetitions
%    azimuth_rep{q} = temp_azimuth(trials_per_rep*(q-1)+BegTrial : trials_per_rep*q+BegTrial-1);
%    elevation_rep{q} = temp_elevation(trials_per_rep*(q-1)+BegTrial : trials_per_rep*q+BegTrial-1);
%    condition_num_rep{q} = temp_stim_type(trials_per_rep*(q-1)+BegTrial : trials_per_rep*q+BegTrial-1);
%    spike_rates_rep{q} = temp_spike_rates(trials_per_rep*(q-1)+BegTrial : trials_per_rep*q+BegTrial-1);
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% resp_mat_anova = [];
% for k=1: length(unique_condition_num)
%    clear select_rep;
%    for q=1:1:repetitions
%        n = 0;
%        for i=1:length(unique_azimuth)
%            for j=1:length(unique_elevation)
%                select_rep{q} = logical( azimuth_rep{q}==unique_azimuth(i) & elevation_rep{q}==unique_elevation(j) & condition_num_rep{q}==unique_condition_num(k) );
%                if (sum(select_rep{q}) > 0)
%                    n = n+1;
%                    resp_mat_anova{k}(q,n) = spike_rates_rep{q}(select_rep{q})';
%                end
%            end
%        end
%    end
%    [p_anova, table, stats] = anova1(resp_mat_anova{k},[],'off');
%    P_anova(k) = p_anova;
%    anova_table{k} = table;
%    F_val(k) = anova_table{k}(2,5);
% end
% F_val = cell2mat(F_val);
% 
% 
% 
% 
% %% ADD CODE HERE FOR PLOTTING
% resp_mat = [];
% for i=1:length(unique_azimuth)
%     for j=1:length(unique_elevation)
%         for k=1: length(unique_condition_num)
%             select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) );
%             if (sum(select) > 0)                
%                 resp_mat(k, j, i) = mean(spike_rates(select));
%                 resp_mat_vector(k, j, i) = mean(spike_rates(select));
%                 for t = 1 : length(spike_rates(select));              % this is to calculate response matrix based on each trial
%                     spike_temp = spike_rates(select);                 % in order to calculate error between trials in one condition
%                     resp_mat_trial{k}(t, j, i) = spike_temp( t );     % t represents how many repetions each condition
%                 end
%                 resp_mat_std(k, j, i) = std(spike_rates(select));     % calculate std between trials for later DSI usage
%                 resp_mat_ste(k, j, i) = resp_mat_std(k, j, i)/ sqrt(length(find( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j))&(condition_num==unique_condition_num(k)) )) );
%             else
% %                resp_mat_trial{k}(t, j, i) = 0; % From the begining
% %                (071306) this sentence was commented by Katsu
% %Following was wrong, I think from 07/10/06 by Katsu
% %                 resp_mat(k, j, i) = 0;
% %                 resp_mat_vector(k, j, i) = resp_mat_vector(k, j, 1);
% %                 resp_mat_std(k, j, i) = 0;
% %                 resp_mat_ste(k, j, i) = 0;
% %So corrected by Katsu 07/15/06
%                 resp_mat(k, j, i) = resp_mat(k,j,1);
%                 resp_mat_vector(k,j,i) =0; % for vector sum only % once this value was 1, not i %%011707 by Katsu
%                 resp_mat_std(k, j, i) = 0;
%                 resp_mat_std(k, j, i) = 0;
%                 resp_mat_ste(k, j, i) = 0;
%             end
%         end        
%     end
% end
% 
% % % creat a real 3-D based plot where the center correspond to forward and
% resp_mat_tran(:,:,1) = resp_mat(:,:,7);
% resp_mat_tran(:,:,2) = resp_mat(:,:,6);
% resp_mat_tran(:,:,3) = resp_mat(:,:,5);
% resp_mat_tran(:,:,4) = resp_mat(:,:,4);
% resp_mat_tran(:,:,5) = resp_mat(:,:,3);
% resp_mat_tran(:,:,6) = resp_mat(:,:,2);
% resp_mat_tran(:,:,7) = resp_mat(:,:,1);
% resp_mat_tran(:,:,8) = resp_mat(:,:,8);
% resp_mat_tran(:,:,9) = resp_mat_tran(:,:,1);
% 
% 
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % calculate maximum and minimum firing rate
% max_res = max(max(max(resp_mat)));
% % max_vi_ve = max(max(max(resp_mat(2:3,:,:))));
% min_res = min(min(min(resp_mat_tran)));
% 
% vector_num = length(unique_azimuth) * (length(unique_elevation)-2) + 2;
% repeat = floor( length(spike_rates) / vector_num );
% 
% % Define figure
% xoffset=0;
% yoffset=0;
% % 
% figure(2);
% set(2,'Position', [5,15 980,650], 'Name', 'Rotation_3D');
% orient landscape;
% %set(0, DefaultAxesXTickMode, 'manual', DefaultAxesYTickMode, 'manual', 'DefaultAxesZTickMode', 'manual');
% axis off;
% 
% for k=1:length(unique_condition_num) 
%     
%     if( xoffset > 0.5)          % now temperarily 2 pictures one row and 2 one column
%         yoffset = yoffset-0.4;
%         xoffset = 0;
%     end
%     axes('position',[0.11+xoffset 0.54+yoffset 0.32 0.24]);
%     contourf( squeeze( resp_mat_tran(k,:,:)) );
%     % set the same scale for visual and combined conditions but here assuming vestibular response is always smaller than that in visual and
%     % combined conditions
% %     if ( k==2 | k==3 )
% %    caxis([min_res, max_res]);
% %    caxis([0, 60]);
% %     end
% 
%     colorbar;
%     % make 0 correspond to rightward and 180 correspond to leftward
%     set(gca, 'ydir' , 'reverse');
%     set(gca, 'xtick', [] );
%     set(gca, 'ytick', [] );    
%     title( h_title{k} );
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     
%     % plot 1-D for mean respond as a function of elevation
%     axes('position',[0.06+xoffset 0.54+yoffset 0.04 0.24]);
%     for j=1:length(unique_elevation)
%         y_elevation_mean(1,j)=mean(resp_mat_tran(k,j,:));
%         y_elevation_std(1,j) =std( spike_rates([find( (elevation==unique_elevation(j))&(condition_num==unique_condition_num(k)) )]) );
%         y_elevation_ste(1,j) =y_elevation_std(1,j)/ sqrt(length(find( (elevation==unique_elevation(j))&(condition_num==unique_condition_num(k)) )) );
%     end
%     x_elevation=unique_elevation;
%     errorbar(x_elevation,y_elevation_mean,y_elevation_ste,'ko-');%----------Now disable temporaly
% %     errorbar(x_elevation,y_elevation_mean,y_elevation_ste,'k-');% Katsu for paper settle for m3c294
%     xlabel('Elevation');
%     view(90,90);
%     set(gca, 'xtick',unique_elevation);
%     xlim([-90, 90]);
%     ylim([min(y_elevation_mean(1,:))-max(y_elevation_ste(1,:)), max(y_elevation_mean(1,:))+max(y_elevation_ste(1,:))]);%----------Now disable temporaly
% 
%     % plot 1-D for mean respond as a function of azimuth
%     axes('position',[0.11+xoffset 0.46+yoffset 0.274 0.06]);
%     for i=1:(length(unique_azimuth) )
%         y_azimuth_mean(1,i)=mean(resp_mat_tran(k,:,i));
%         y_azimuth_std(1,i) =std( spike_rates([find( (azimuth==unique_azimuth(i))&(condition_num==unique_condition_num(k)) )]) );
%         y_azimuth_ste(1,i) =y_azimuth_std(1,i)/ sqrt(length(find( (azimuth==unique_azimuth(i))&(condition_num==unique_condition_num(k)) )) );    
%     end
%     y_azimuth_mean(1,9) = mean(resp_mat_tran(k,:,1));
%     for i=1:( length(unique_azimuth)+1 )
%         if (i < 8)        
%             y_azimuth_ste_tran(1,i) = y_azimuth_ste(1,8-i);
%         elseif (i == 8)
%             y_azimuth_ste_tran(1,i) = y_azimuth_ste(1,8);
%         else
%             y_azimuth_ste_tran(1,i) = y_azimuth_ste(1,7);
%         end
%     end
%     x_azimuth=1:(length(unique_azimuth)+1);
%     errorbar(x_azimuth,y_azimuth_mean,y_azimuth_ste_tran,'ko-');%----------Now disable temporaly
% %     errorbar(x_azimuth,y_azimuth_mean,y_azimuth_ste_tran,'k-');% Katsu for paper settle for m3c294
%     xlim( [1, length(unique_azimuth)+1] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,2,3,4,5,6,7,8,9]);
%     set(gca, 'xticklabel','270|225|180|135|90|45|0|-45|-90'); 
% %     xlabel('Azimuth');
%     ylim([min(y_azimuth_mean(1,:))-max(y_azimuth_ste(1,:)), max(y_azimuth_mean(1,:))+max(y_azimuth_ste(1,:))]);%----------Now disable temporaly
% 
%     xoffset=xoffset+0.48;
%     
%     % calculate min and max firing rate, standard deviation, HTI, Vectorsum
%     Min_resp(k) = min( min( resp_mat_tran(k,:,:)) );
%     Max_resp(k) = max( max( resp_mat_tran(k,:,:)) );
%     resp_std(k) = sum( sum(resp_mat_std(k,:,:)) ) / vector_num;  % notice that do not use mean here, its (length(unique_azimuth)*length(unique_elevation)-14) vectors intead of 40
%     
%     Ave_26{k}=sum(sum(squeeze(resp_mat_vector(k,:,:))))/26; %resp_mat_vec includes 0, so sum*sum devided by 26 trajectories
%     
%     M=squeeze(resp_mat_vector(k,:,:));     % notice that here DSI should use resp_temp without 0 value set manually
%     % this part is to calculate vestibular gain
%     resp_onedim{k} = [M(1,1),M(2,:),M(3,:),M(4,:),M(5,1)]';     % hard-code temperarilly    
%     N=squeeze(resp_mat_vector(k,:,:));      % notice that here vectorsum should use resp_mat with 0 value set manually 
%     [Azi, Ele, Amp] = vectorsum(N);
%     Vec_sum{k}=[Azi, Ele, Amp];
%     % Heading Tuning Index
%     r(k) = HTI(M,spon_resp);   % call HTI function    
% end
% % calculate vestibular gain by a*ves=comb-vis
% if (length(unique_stim_type) == 3)
%    [bb,bint,rr,rint,stats] = regress( (resp_onedim{3}-resp_onedim{2}), [ones(vector_num,1),(resp_onedim{1}-spon_resp)] );    % with offset
%    gain = bb(2);
% else
%    gain = NaN;
% end
% unique_stim_type
% % Max_resp
% % Min_resp
% % Ave_26
% 
% 
% %%------------------------------------------------------------------
% % DDI Direction discrimination index   by Katsu 05/18/06
% %--------------------------------------------------------------------
% %spike_rates_sqrt = sqrt(spike_rates);That is not original, it makes value bigger by 
% each_stim_trials=repetitions*(length(unique_azimuth)*length(unique_elevation)-14) % (length(unique_azimuth)*length(unique_elevation)-14) trajectory  -90+90 -45 0 + 45 *0 45 90 .......
% %
% SSE_term = [];
% for k=1:length(unique_stim_type)
%     n=0;
%     for j=1:length(unique_elevation)
%         for i=1:length(unique_azimuth)
%             clear select;
%             select=logical((azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (stim_type==unique_stim_type(k)));
%             if (sum(select) > 0)
%                    n = n+1;
%                    SSE_term(k,j,i)=sum((spike_rates(select)-mean(spike_rates(select))).^2);
%                else
%                    SSE_term(k,j,i)=0;%This is correct extra -90 and 90 should be 0, to be summed
%             end
%          end
%      end
% %      SSE_azimth_sum(k,j)=sum(SSE_term(k,j,:))  %it is not correct
% %      SSE_total(k)=sum(SSE_azimth_sum(k,:))
%      SSE_total(k)=sum(sum(SSE_term(k,:,:)));
%      max_min_term(k)=(Max_resp(k)-Min_resp(k))/2;
%      var_term(k)=sqrt(SSE_total(k)/(each_stim_trials-n));
%      DDI(k)=max_min_term(k)/(max_min_term(k)+var_term(k));
% end
% % r
% % DDI
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% %check significance of DDI and calculate p value, Not !!! do bootstrap at the same time to test value varience
% perm_num=1000;
% bin = 0.005;
% spike_rates_perm = [];
% SSE_term_perm=[];
% for n=1: perm_num
%     % this is permuted based on trials
%     for k=1:length(unique_condition_num)   
%         spike_rates_pe{k} = spike_rates( find( condition_num==unique_condition_num(k) ) );
%         spike_rates_pe{k} = spike_rates_pe{k}( randperm(length(spike_rates_pe{k})) );
%     end
% 
%     % put permuted data back to spike_rates
%     spike_rates_perm(length(spike_rates))=0;
%     for k=1:length(unique_condition_num) 
%         ii = find(stim_type == unique_stim_type(k));
%         spike_rates_perm(ii) = spike_rates_pe{k};
%     end
%     
%     % re-creat a matrix similar as resp_mat              
%     resp_vector_perm = [];
%     for k=1:length(unique_condition_num)
%         m=0;
%         
%         for j=1:length(unique_elevation)
%             for i=1:length(unique_azimuth)
%                 
%                 select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) );
%                 if (sum(select) > 0)
%                     m=m+1;
%                     
%                     resp_mat_perm(k,j,i) = mean(spike_rates_perm(select));
% %                     resp_mat_perm_std(k,j,i) = std(spike_rates_perm(select));
%                     SSE_term_perm(k,j,i)=sum((spike_rates_perm(select)-mean(spike_rates_perm(select))).^2);
%                 else
%                     resp_mat_perm(k,j,i) = resp_mat_perm(k,j,1);% Note! This is not =0. In order to calcurate Max or Min, line 349-350.
% %                     resp_mat_perm_std(k,j,i) = 0;
%                     SSE_term_perm(k,j,i) = 0;% This will be sum, so need to be 0
%                 end
%             end        
%         end
%     end
%     
%     
%     
%     % re-calculate HTI and DDI now
%     for k=1: length(unique_condition_num)
%  %       resp_perm_std(k) = sum( sum(resp_mat_perm_std(k,:,:)) ) / vector_num; 
%         M_perm=squeeze(resp_mat_perm(k,:,:));
%         r_perm(k,n) = HTI(M_perm, spon_resp);
%         
%         Min_resp_perm(k,n) = min( min( resp_mat_perm(k,:,:) ));
%         Max_resp_perm(k,n) = max( max( resp_mat_perm(k,:,:) ));
%     
%         SSE_total_perm(k,n)=sum(sum(SSE_term_perm(k,:,:)));
%         max_min_term_perm(k,n)=(Max_resp_perm(k,n)-Min_resp_perm(k,n))/2;
%         var_term_perm(k,n)=sqrt(SSE_total_perm(k,n)/(each_stim_trials-m));
%         DDI_perm(k,n)=max_min_term_perm(k,n)/(max_min_term_perm(k,n)+var_term_perm(k,n));
%         
%     end
%     % do bootstrap now
%     % first to bootstap raw data among trils 
%     repetition = 5;
%     for k=1:length(unique_stim_type)
%         for i=1:length(unique_azimuth)
%             for j=1:length(unique_elevation)
%                     select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (stim_type==unique_stim_type(k)) );
%                     if (sum(select) > 0)
%                         spike_select = spike_rates(select);
%                         for b=1:repetition    % use 5 repetitions temporarilly, should doesn't matter whether have 5 repetitions or not actually
%                             spike_select = spike_select( randperm(length(spike_select)) );
%                             spike_bootstrap(b) = spike_select(1);   % always take the first one element
%                         end 
%                         resp_mat_boot(k, j, i) = mean(spike_bootstrap);
%                     else
%                         resp_mat_boot(k, j, i) = 0;
%                     end       
%              end
%          end
%      end
%      % now recalculate values
%      for k=1: length(unique_stim_type)   
%          Mb=squeeze(resp_mat_boot(k,:,:));
%          r_boot(k,n) = HTI(Mb,spon_resp) ; 
%          % also calculate the significant different angles between preferred headings, for only vestibualr condition
%          [Azi_boot, Ele_boot, Amp_boot] = vectorsum(Mb);
%          Vec_sum_boot{k}=[Azi_boot, Ele_boot, Amp_boot];
%          Angle_boot(n)=(180/3.14159) * acos( sin(Vec_sum{1}(2)*3.14159/180) * sin(Vec_sum_boot{1}(2)*3.14159/180)  +  cos(Vec_sum_boot{1}(2)*3.14159/180) * sin(Vec_sum_boot{1}(1)*3.14159/180) * cos(Vec_sum{1}(2)*3.14159/180) * sin(Vec_sum{1}(1)*3.14159/180) + cos(Vec_sum_boot{1}(2)*3.14159/180) * cos(Vec_sum_boot{1}(1)*3.14159/180) * cos(Vec_sum{1}(2)*3.14159/180) * cos(Vec_sum{1}(1)*3.14159/180) );
%      end  
% end
% % now calculate p value or significant test
% x_bin = 0 : bin : 1;
% for k = 1 : length(unique_condition_num)
%     hist_perm(k,:) = hist( r_perm(k,:), x_bin );  % for permutation
%     hist_boot(k,:) = hist( r_boot(k,:), x_bin );  % for bootstrap
%     
%     hist_DDI_perm(k,:) = hist( DDI_perm(k,:), x_bin );  % for DDI permutation
%     
%     
%     [hist_boot_angle(k,:),x_angle] = hist( Angle_boot(:), 200 );  % for bootstrap, set 200 bins temporarilly
%     
%     bin_sum = 0;
%     n = 0;
%     while ( n < (r(k)/bin) )
%           n = n+1;
%           bin_sum = bin_sum + hist_perm(k, n);
%           p{k} = (perm_num - bin_sum)/ perm_num;    % calculate p value for HTI
%     end 
%     
%     bin_sum = 0;
%     n = 0;
%     while ( n < (DDI(k)/bin) )
%           n = n+1;
%           bin_sum = bin_sum + hist_DDI_perm(k, n);
%           DDI_p{k} = (perm_num - bin_sum)/ perm_num;    % calculate p value for HTI
%     end 
%     
%     
%     bin_sum = 0;
%     n = 0;
%     while ( bin_sum < 0.025*sum( hist_boot(k,:)) )   % define confidential value to be 0.05, now consider one side only which is 0.025 of confidence
%           n = n+1;
%           bin_sum = bin_sum + hist_boot(k, n);      
%           HTI_boot(k) = r(k) - n * bin ;    % calculate what HTI value is thought to be significant different
%     end 
% %     bin_sum = 0;
% %     n = 0;
% %     while ( bin_sum < 0.975*sum( hist_boot_angle(k,:)) )   % define confidential value to be 0.05, now consider one side only which is 0.025 of confidence
% %           n = n+1;
% %           bin_sum = bin_sum + hist_boot_angle(k, n);      
% %           Angle_boot(k) = x_angle(n) ;    
% %     end 
% end
% 
%  %---------------------------------------------------------------------------
% % Now show vectorsum, DSI, p and spontaneous at the top of figure--------and DDI by Katsu 05/18/06
% axes('position',[0.05,0.85, 0.9,0.1] );
% xlim( [0,100] );
% ylim( [0,length(unique_condition_num)] );
% h_spon = num2str(spon_resp);
% text(0, length(unique_condition_num), FILE);
% text(10,length(unique_condition_num),'Protocol  Spon   Minimum   Maximum    Azi      Ele       Amp     Std        HTI          HTIerr      p-HTI       F-val        p-ANOVA       DDI   p-DDI');
% for k=1:length(unique_condition_num) 
%     h_text{k}=num2str( [spon_resp, Min_resp(k), Max_resp(k), Vec_sum{k}, resp_std(k), r(k), HTI_boot(k), p{k}, F_val(k), P_anova(k), DDI(k), DDI_p{k}], 4);
%     text(0,length(unique_condition_num)-k,h_title{k});
%     text(9,length(unique_condition_num)-k,'Rotation');
%     text(17,length(unique_condition_num)-k, h_text{k} );
% end
% 
% axis off;
% 
% %%%%%%%%%%%%%%%% MFR and 
% %%%%%%%%%%%%%%%% eye position/velocity
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 
% for k=1:length(unique_condition_num) ;
%     mfr_up{k}=[];
%    mfr_down{k}=[];
%    mfr_left{k}=[];
%    mfr_right{k}=[];
% end
% 
% for k=1:length(unique_condition_num)  
% for t=1:repetitions
% 
%    mfr_up{k}=[mfr_up{k} resp_mat_trial{k}(t,3,1)];
%    mfr_down{k}=[mfr_down{k} resp_mat_trial{k}(t,3,5)];
%    mfr_left{k}=[mfr_left{k} resp_mat_trial{k}(t,1,1)];
%    mfr_right{k}=[mfr_right{k} resp_mat_trial{k}(t,5,1)];
%    
% end
% end
% 
% xshift=0;
% 
% minxscale=-20; maxxscale=20;
% scalesum=[];
% for k=1:length(unique_condition_num)
%     scalesum{k}=[mean_eye_x_up{k} mean_eye_x_down{k} mean_eye_x_left{k} mean_eye_x_right{k} mean_eye_y_up{k} mean_eye_y_down{k} mean_eye_y_left{k} mean_eye_y_right{k}];
%     minscalesum{k}=min(scalesum{k});
%     maxscalesum{k}=max(scalesum{k});
%     if minscalesum{k} < minxscale
%         minxscale=minscalesum{k};
%     elseif maxscalesum{k}> maxxscale
%         maxxscale=maxscalesum{k};
%     end
% end
%    
% 
% for k=1:length(unique_condition_num) 
%    axes('position',[0.1+xshift 0.22 0.17 0.17]); 
%    plot(mean_eye_x_up{k}, mfr_up{k},'r^');hold on; 
%    plot(mean_eye_x_down{k}, mfr_down{k},'bv');
%    xlim([minxscale maxxscale]);ylim([Min_resp(k)-5 Max_resp(k)+10]);
%    title('Horizontal(x) Eye Vel (deg/s)');
%    ylabel('Up and Down');
%    
%    axes('position',[0.1+xshift 0.02 0.17 0.17]);hold on;  
%    plot(mean_eye_x_left{k}, mfr_left{k},'r<');
%    plot(mean_eye_x_right{k}, mfr_right{k},'b>');
%    xlim([minxscale maxxscale]);ylim([Min_resp(k)-5 Max_resp(k)+10]);
%    ylabel('Left and Right');
%    
%    axes('position',[0.3+xshift 0.22 0.17 0.17]);hold on;  
%    plot(mean_eye_y_up{k}, mfr_up{k},'r^');
%    plot(mean_eye_y_down{k}, mfr_down{k},'bv');
%    xlim([minxscale maxxscale]);ylim([Min_resp(k)-5 Max_resp(k)+10]);
%    title('Vertical(y) Eye Vel (deg/s)');
%    
%    axes('position',[0.3+xshift 0.02 0.17 0.17]);
%    plot(mean_eye_y_left{k}, mfr_left{k},'r<');hold on; 
%    plot(mean_eye_y_right{k}, mfr_right{k},'b>');
%    xlim([minxscale maxxscale]);ylim([Min_resp(k)-5 Max_resp(k)+10]);
% 
% xshift=xshift+0.5;
% end
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% %%%%%                         output to text file
% sprint_txt = ['%s'];
% for i = 1 : 100
%     sprint_txt = [sprint_txt, ' %3.4f'];    
% end
% foldername = ('C:\Frequency_Analysis\');
% outfile = [foldername 'MFR_EyeVel.dat'];
% 
% for i = 1:repetitions
%     
%     buff = sprintf(sprint_txt, FILE, repetitions, spon_resp, Min_resp(1), Max_resp(1), Vec_sum{1},DDI(1), Ave_26{1}, p{1} , P_anova(1), DDI_p{1},...
%         mean_eye_x_up{1}(i), mfr_up{1}(i), mean_eye_y_up{1}(i), mfr_up{1}(i), mean_eye_x_down{1}(i), mfr_down{1}(i),  mean_eye_y_down{1}(i), mfr_down{1}(i),...
%         mean_eye_x_left{1}(i), mfr_left{1}(i), mean_eye_y_left{1}(i), mfr_left{1}(i), mean_eye_x_right{1}(i), mfr_right{1}(i),  mean_eye_y_right{1}(i), mfr_right{1}(i));    
%     fid = fopen(outfile, 'a');
%     fprintf(fid, '%s', buff);
%     fprintf(fid, '\r\n');
%     fclose(fid);
% end
% 
% %      tittle index paste & copy to .dat or .xls file
% %
% % FILE	repeat	spont	Ves_min	Veb_max	Veb_azi	Veb_ele	Veb_amp	Veb_DDI	VebHTI_P	Veb_P_anova	Veb_p_DDI	eye_x_up	mfr_up	eye_y_up	mfr_up	eye_x_down	mfr_down	eye_y_down	mfr_down	eye_x_left	mfr_left	eye_y_left	mfr_left	eye_x_right	mfr_right	eye_y_right	mfr_right
% 
% % 
% % 
% %%%%%           commented 04/05/07 temporaly not using eyetracce analysis
% %%%%%           but darkness analysis above
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%   take mean to plotsupplemental figure, use folder 'analysis' mat
% %%%%%%   code to calculate
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear re_x_up re_y_up re_x_down re_y_down re_x_left re_y_left re_x_right re_y_right 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     mean for 5 repeatition for figures

for k = 1 : length(unique_stim_type)
    re_x_up{k} = mean(resp_x_up{k}(:,:));
    re_y_up{k} = mean(resp_y_up{k}(:,:));
    re_x_down{k} = mean(resp_x_down{k}(:,:));
    re_y_down{k} = mean(resp_y_down{k}(:,:));
    re_x_left{k} = mean(resp_x_left{k}(:,:));
    re_y_left{k} = mean(resp_y_left{k}(:,:));
    re_x_right{k} = mean(resp_x_right{k}(:,:));
    re_y_right{k} = mean(resp_y_right{k}(:,:));
    
    eyescale{k}=[re_x_up{k} re_y_up{k} re_x_down{k} re_y_down{k} re_x_left{k} re_y_left{k} re_x_right{k} re_y_right{k}];
    eyemax{k}=max(eyescale{k})
    eyemin{k}=min(eyescale{k})
    if eyemax{k}<0.5
        eyemax{k}=0.5;
    end
    if eyemin{k}>-0.5
        eyemin{k}=-0.5;
    end
end
%     


% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%For figure writing, in order to batch comment!!!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5


   title1 = 'up';
    title2 = 'down';
    title3 = 'left';
    title4 = 'right';
    
    subtitle{1}='Vestibular';subtitle{2}='Visual';
    
    lengthstim=length(unique_stim_type);
    if lengthstim > 2; % combined No!
        lengthstim=2;
    end

%%%%%%%%%%%%%% MEAN Figure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tunde1 = figure(3);  orient landscape;
    axes('position',[0 0 1 1]); 
    xlim([1,10]);
    ylim([1,10]);
    axis off
%     for k = 1 : length(unique_stim_type)
          for k = 1 : lengthstim;% combined No!
    text (3+5*(k-1), 9, subtitle(k));
    end
    text (5, 9, FILE);

%     for k = 1 : length(unique_stim_type)
        for k = 1 : lengthstim
        for i = 1:4
            
            axes('position',[0.1+0.5*(k-1) 0.65-0.2*(i-1) 0.35 0.15]); 
            
            if i==1
                plot(re_x_up{k},'r.');
                   hold on;
                    xlim( [1, 400] );
                    ylim( [eyemin{k}, eyemax{k}] );
                set(gca, 'XTickMode','manual');
                set(gca, 'xtick',[1,100,200,300,400]);
                set(gca, 'xticklabel','0|0.5|1|1.5|2'); 

                 ylabel('(deg)');
                 title(['Eye Position /  ',title1]);

                 plot(re_y_up{k},'b.');
                    hold off;
                    
            elseif i==2
                 plot(re_x_down{k},'r.');
                    hold on;
                   xlim( [1, 400] );
                    ylim( [eyemin{k}, eyemax{k}] );
                set(gca, 'XTickMode','manual');
                set(gca, 'xtick',[1,100,200,300,400]);
                set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
                ylabel('(deg)');
                title(['Eye Position /  ',title2]);

                plot(re_y_down{k},'b.');
                    hold off;   
                    
            elseif i==3
                  plot(re_x_left{k},'r.');
                    hold on;
                    xlim( [1, 400] );
                    ylim( [eyemin{k}, eyemax{k}] );
                    set(gca, 'XTickMode','manual');
                    set(gca, 'xtick',[1,100,200,300,400]);
                    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
                    ylabel('(deg)');
                    title(['Eye Position /  ',title3]);

                    plot(re_y_left{k},'b.');
                         hold off;      
                        
            elseif i==4
                    plot(re_x_right{k},'r.');
                        hold on;
                    xlim( [1, 400] );
                     ylim( [eyemin{k}, eyemax{k}] );
                    set(gca, 'XTickMode','manual');
                    set(gca, 'xtick',[1,100,200,300,400]);
                    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
                    ylabel('(deg)');
                    title(['Eye Position /  ',title4]);

                    plot(re_y_right{k},'b.');
                        hold off;        
                            
                            
                        end
                    end
                end

%%%%%%%%%%%%%% Each repetition Figure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tunde2 = figure(4);  orient landscape;
    axes('position',[0 0 1 1]); 
    xlim([1,10]);
    ylim([1,10]);
    axis off
%     for k = 1 : length(unique_stim_type)
          for k = 1 : lengthstim;% combined No!
    text (3+5*(k-1), 9, subtitle(k));
    end
    text (5, 9, FILE);
%  %%%%%%%%%%%%%%%%%%%%% max_ and min_ %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5  
%
%  still working on it
%
%
%     for k = 1 : length(unique_stim_type)
%         
%     max_re_x_up{k} = max(max(resp_x_up{k}(:,:)));
%     max_re_y_up{k} = max(max(resp_y_up{k}(:,:)));
%     max_re_x_down{k} = max(max(resp_x_down{k}(:,:)));
%     max_re_y_down{k} = max(max(resp_y_down{k}(:,:)));
%     max_re_x_left{k} = max(max(resp_x_left{k}(:,:)));
%     max_re_y_left{k} = max(max(resp_y_left{k}(:,:)));
%     max_re_x_right{k} = max(max(resp_x_right{k}(:,:)));
%     max_re_y_right{k} = max(max(resp_y_right{k}(:,:)));
%     
%     max_eyescale{k}=[max_re_x_up{k} max_re_y_up{k} max_re_x_down{k} max_re_y_down{k} max_re_x_left{k} max_re_y_left{k} max_re_x_right{k} max_re_y_right{k}];
%     max_eyemax{k}=max(max_eyescale{k})
%     
%     min_eyescale{k}=[min_e_x_up{k} min_re_y_up{k} min_re_x_down{k} min_re_y_down{k} min_re_x_left{k} min_re_y_left{k} min_re_x_right{k} min_re_y_right{k}];
%     min_eyemin{k}=min(min_eyescale{k})
%     
%     if eyemax{k}<0.5
%         eyemax{k}=0.5;
%     end
%     if eyemin{k}>-0.5
%         eyemin{k}=-0.5;
%     end
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    howmany=size(resp_x_up{1})

%     for k = 1 : length(unique_stim_type)
        for k = 1 : lengthstim; % permit only 2 conditions, because of lack of space
        for i = 1:4
            
            axes('position',[0.1+0.5*(k-1) 0.65-0.2*(i-1) 0.35 0.15]); 
            
            if i==1
                for jj=1:howmany(1)
                plot(resp_x_up{k}(jj,:),'r.');
                   hold on;
                plot(resp_y_up{k}(jj,:),'b.');
                    hold on;
               end
                    xlim( [1, 400] );
                    ylim( [eyemin{k}, eyemax{k}] );
                set(gca, 'XTickMode','manual');
                set(gca, 'xtick',[1,100,200,300,400]);
                set(gca, 'xticklabel','0|0.5|1|1.5|2'); 

                 ylabel('(deg)');
                 title(['Eye Position /  ',title1]);
%                  for jj=1:howmany(1)
%                  plot(resp_y_up{k}(jj,:),'b.');
%                     hold on;
%                 end
                    
            elseif i==2
                 for jj=1:howmany(1)
                 plot(resp_x_down{k}(jj,:),'r.');
                    hold on;
                 plot(resp_y_down{k}(jj,:),'b.');
                    hold on;
                end
                   xlim( [1, 400] );
                    ylim( [eyemin{k}, eyemax{k}] );
                set(gca, 'XTickMode','manual');
                set(gca, 'xtick',[1,100,200,300,400]);
                set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
                ylabel('(deg)');
                title(['Eye Position /  ',title2]);

%                 plot(resp_y_down{k},'b.');
%                     hold off;   
                    
            elseif i==3
                 for jj=1:howmany(1)
                  plot(resp_x_left{k}(jj,:),'r.');
                    hold on;
                  plot(resp_y_left{k}(jj,:),'b.');
                         hold on; 
                  end
                    xlim( [1, 400] );
                    ylim( [eyemin{k}, eyemax{k}] );
                    set(gca, 'XTickMode','manual');
                    set(gca, 'xtick',[1,100,200,300,400]);
                    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
                    ylabel('(deg)');
                    title(['Eye Position /  ',title3]);

%                     plot(resp_y_left{k},'b.');
%                          hold off;      
                        
            elseif i==4
                 for jj=1:howmany(1)
                    plot(resp_x_right{k}(jj,:),'r.');
                        hold on;
                    plot(resp_y_right{k}(jj,:),'b.');
                        hold on;
                    end
                    xlim( [1, 400] );
                     ylim( [eyemin{k}, eyemax{k}] );
                    set(gca, 'XTickMode','manual');
                    set(gca, 'xtick',[1,100,200,300,400]);
                    set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
                    ylabel('(deg)');
                    title(['Eye Position /  ',title4]);

%                     plot(resp_y_right{k},'b.');
%                         hold off;        
                            
                            
                        end
                    end
        end
                
        
        
        saveas(tunde1, [FILE, '1.fig'], 'fig')
    
% for k = 1 : length(unique_stim_type)
%     
%     figure(k+20)
% 
% subplot(4,1,1)
% plot(re_x_up{k},'r.');
%     hold on;
%     xlim( [1, 400] );
%     ylim( [eyemin{k}, eyemax{k}] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
% %     ylim([-20, 20]);
%     ylabel('(deg)');
%     title(['Eye Position /  ',title1]);
% 
%     plot(re_y_up{k},'b.');
%     hold off;
% 
% 
% subplot(4,1,2)
% plot(re_x_down{k},'r.');
%     hold on;
%     xlim( [1, 400] );
%     ylim( [eyemin{k}, eyemax{k}] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
% %     ylim([-20, 20]);
%     ylabel('(deg)');
%     title(['Eye Position /  ',title2]);
% 
%     plot(re_y_down{k},'b.');
%     hold off;
% 
% subplot(4,1,3)
% plot(re_x_left{k},'r.');
%     hold on;
%     xlim( [1, 400] );
%     ylim( [eyemin{k}, eyemax{k}] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
% %     ylim([-20, 20]);
%     ylabel('(deg)');
%     title(['Eye Position /  ',title3]);
% 
%     plot(re_y_left{k},'b.');
%     hold off;
%     
% subplot(4,1,4)
% plot(re_x_right{k},'r.');
%     hold on;
%     xlim( [1, 400] );
%     ylim( [eyemin{k}, eyemax{k}] );
%     set(gca, 'XTickMode','manual');
%     set(gca, 'xtick',[1,100,200,300,400]);
%     set(gca, 'xticklabel','0|0.5|1|1.5|2'); 
% %     ylim([-20, 20]);
%     ylabel('(deg)');
%     title(['Eye Position /  ',title4]);
% 
%     plot(re_y_right{k},'b.');
%     hold off;
%     
% end    
% 
%     
%     
% %     %% commented 04/04/07
% %     
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %%%%%                         output to text file
% % sprint_txt = ['%s'];
% % for i = 1 : 400*repeat*10
% %     sprint_txt = [sprint_txt, ' %1.2f'];    
% % end
% % 
% % 
% % % if you want to save 'world', select 2, 'pursuit', select 3
% % 
% % 
% % buff= sprintf(sprint_txt, FILE, repeat, re_x_up{1}(:,:), re_y_up{1}(:,:), re_x_down{1}(:,:), re_y_down{1}(:,:), ...
% %                           re_x_left{1}(:,:), re_y_left{1}(:,:),re_x_right{1}(:,:),re_y_right{1}(:,:) );
% % % buff= sprintf(sprint_txt, FILE, repeat, re_x_up{2}(:,:), re_y_up{2}(:,:), re_x_down{2}(:,:), re_y_down{2}(:,:), ...
% % %                           re_x_left{2}(:,:), re_y_left{2}(:,:),re_x_right{2}(:,:),re_y_right{2}(:,:) );
% % % buff= sprintf(sprint_txt, FILE, repeat, re_x_up{3}(:,:), re_y_up{3}(:,:), re_x_down{3}(:,:), re_y_down{3}(:,:), ...
% % %                           re_x_left{3}(:,:), re_y_left{3}(:,:),re_x_right{3}(:,:),re_y_right{3}(:,:) );
% % %                       
% %                       
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\RVOR_Pursuit\Que_Pursuit_World.dat'];
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\QueEye_Rot_Vet.dat'];
% % 
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\AzraelEye_Rot_Vet.dat'];
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\AzraelEye_Rot_Vis.dat'];
% % 
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\ZebulonEye_Rot_Vet.dat'];
% % 
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\QueLaby_Rot_Vet.dat'];
% % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\ZebulonLaby_Rot_Vet.dat'];
% % 
% % printflag = 0;
% % if (exist(outfile, 'file') == 0)    %file does not yet exist
% %     printflag = 1;
% % end
% % fid = fopen(outfile, 'a');
% % if (printflag)
% %     fprintf(fid, 'FILE\t');
% %     fprintf(fid, '\r\n');
% % end
% % fprintf(fid, '%s', buff);
% % fprintf(fid, '\r\n');
% % fclose(fid);
% % 
% % 
% % 
% % %%%%%                         output to text file
% % sprint_txt2 = ['%s'];
% % for i = 1 : 400*repeat*10
% %     sprint_txt2 = [sprint_txt2, ' %1.2f'];    
% % end
% % 
% % 
% % % if you want to save 'world', select 2, 'pursuit', select 3
% % 
% % 
% % % buff= sprintf(sprint_txt2, FILE, repeat, re_x_up{1}(:,:), re_y_up{1}(:,:), re_x_down{1}(:,:), re_y_down{1}(:,:), ...
% % %                           re_x_left{1}(:,:), re_y_left{1}(:,:),re_x_right{1}(:,:),re_y_right{1}(:,:) );
% % buff= sprintf(sprint_txt, FILE, repeat, re_x_up{2}(:,:), re_y_up{2}(:,:), re_x_down{2}(:,:), re_y_down{2}(:,:), ...
% %                           re_x_left{2}(:,:), re_y_left{2}(:,:),re_x_right{2}(:,:),re_y_right{2}(:,:) );
% % % buff= sprintf(sprint_txt, FILE, repeat, re_x_up{3}(:,:), re_y_up{3}(:,:), re_x_down{3}(:,:), re_y_down{3}(:,:), ...
% % %                           re_x_left{3}(:,:), re_y_left{3}(:,:),re_x_right{3}(:,:),re_y_right{3}(:,:) );
% % %                       
% %                       
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\RVOR_Pursuit\Que_Pursuit_World.dat'];
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\AzraelEye_Rot_Vet.dat'];
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\AzraelEye_Rot_Vis.dat'];
% % 
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\QueEye_Rot_Vis.dat'];
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\ZebulonEye_Rot_Vis.dat'];
% % 
% % % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\QueLaby_Rot_Vis.dat'];
% % outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Rotation3D\ZebulonLaby_Rot_Vis.dat'];
% % 
% % printflag = 0;
% % if (exist(outfile, 'file') == 0)    %file does not yet exist
% %     printflag = 1;
% % end
% % fid = fopen(outfile, 'a');
% % if (printflag)
% %     fprintf(fid, 'FILE\t');
% %     fprintf(fid, '\r\n');
% % end
% % fprintf(fid, '%s', buff);
% % fprintf(fid, '\r\n');
% % fclose(fid);



return;

