%----------------------------------------------------------------------------------------------------------------------
%-- PSTH.m -- Plots Post Stimulus Time Histogram for MOOG 3D tuning expt
%--	Yong, 6/27/03
%-----------------------------------------------------------------------------------------------------------------------

function MOOG_PSTH(data, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, StartEventBin, StopEventBin, PATH, FILE, Protocol);

Path_Defs;
ProtocolDefs; %contains protocol specific keywords - 1/4/01 BJP

added4RecoveringSpikeData;

% SaveTrials(data, Protocol, Analysis, SpikeChan, StartCode, StopCode,BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE, OutputPath)
% [StartOffsetBin StopOffsetBin StartEventBin StopEventBin] = CheckTimeOffset(data, size(data.event_data, 3), 4, 5, 500, -500, data.UseSyncPulses);

% % temp: save out .mat files for Tanya -- 12-2009
save(['Z:\Users\Tanya\Nodulus_frequency_analysis\all_data\' FILE '.mat']);

% %get the column of values for azimuth and elevation and stim_type
% temp_azimuth = data.moog_params(AZIMUTH,:,MOOG);
% temp_elevation = data.moog_params(ELEVATION,:,MOOG);
% temp_stim_type = data.moog_params(STIM_TYPE,:,MOOG); 
% temp_amplitude = data.moog_params(AMPLITUDE,:,MOOG); 
% temp_spike_data = data.spike_data(SpikeChan,:);
% temp_spike_rates = data.spike_rates(SpikeChan, :);    
% 
% %get indices of any NULL conditions (for measuring spontaneous activity
% null_trials = logical( (temp_azimuth == data.one_time_params(NULL_VALUE)) );
% 
% %now, remove trials from direction and spike_rates that do not fall between BegTrial and EndTrial
% trials = 1:length(temp_azimuth);		% a vector of trial indices
% bad_trials = find(temp_spike_rates > 3000);   % cut off 3k frequency which definately is not cell's firing response
% if ( bad_trials ~= NaN)
%    select_trials= ( (trials >= BegTrial) & (trials <= EndTrial) & (trials~=bad_trials) );
% else 
%    select_trials= ( (trials >= BegTrial) & (trials <= EndTrial) ); 
% end
% 
% azimuth = temp_azimuth(~null_trials & select_trials);
% elevation = temp_elevation(~null_trials & select_trials);
% stim_type = temp_stim_type(~null_trials & select_trials);
% amplitude = temp_amplitude(~null_trials & select_trials);
% % stim_duration = length(temp_spike_data)/length(temp_azimuth);
% % spike_data = data.spike_data(1, ((BegTrial-1)*stim_duration+1):EndTrial*stim_duration);
% spike_rates= temp_spike_rates(~null_trials & select_trials);
% % notice that this bad_trials is the number without spon trials 
% 
% unique_azimuth = munique(azimuth');
% unique_elevation = munique(elevation');
% unique_stim_type = munique(stim_type');
% unique_amplitude = munique(amplitude');
% 
% condition_num = stim_type;
% h_title{1}='Vestibular';
% h_title{2}='Visual';
% h_title{3}='Combined';
% unique_condition_num = munique(condition_num');
% 
% % add parameters here
% % timebin for plot PSTH
% timebin=50;
% % sample frequency depends on test duration
% frequency=length(temp_spike_data)/length(select_trials);  
% % length of x-axis
% x_length = frequency/timebin;
% % x-axis for plot PSTH
% x_time=1:(frequency/timebin);
% 
% % find spontaneous trials which azimuth,elevation,stim_type=-9999
% spon_found = find(null_trials==1);     
% 
% % remove null trials, bad trials, and trials outside Begtrial~Engtrial
% 
% % first save temp_spike_data for finding null trials later
% spike_data_withnulls = temp_spike_data; % (this should be correct, barring any mysterious 'bad trials')
% 
% stim_duration = length(temp_spike_data)/length(temp_azimuth);
% Discard_trials = find(null_trials==1 | trials <BegTrial | trials >EndTrial);
% for i = 1 : length(Discard_trials)
%     temp_spike_data( 1, ((Discard_trials(i)-1)*stim_duration+1) :  Discard_trials(i)*stim_duration ) = 9999;
% end
% spike_data = temp_spike_data( temp_spike_data~=9999 );
% spike_data( find(spike_data>100) ) = 1; % something is absolutely wrong
% 
% 
% % count spikes from raster data (spike_data)
% max_count = 1;
% time_step=1;
% for k=1: length(unique_condition_num)
%     for j=1:length(unique_elevation)
%         for i=1: length(unique_azimuth)
%             select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) );            
%             % get rid off -90 and 90 cases
%             if (sum(select) > 0)
%                 resp{k}(j,i) = mean(spike_rates(select));
%                 act_found = find( select==1 );
%                 % count spikes per timebin on every same condition trials
%                 for repeat=1:length(act_found) 
%                     for n=1:(x_length)
%                         temp_count(repeat,n)=sum(spike_data(1,(frequency*(act_found(repeat)-1)+time_step):(frequency*(act_found(repeat)-1)+n*timebin)));
%                         time_step=time_step+timebin;
%                     end
%                     time_step=1;                    
%                 end
%                 count_y_trial{k,i,j}(:,:) = temp_count;  % each trial's PSTH 
%                 % get the average of the total same conditions if repetion is > 1
%            %     if (length(act_found) > 1);
%                 dim=size(temp_count);
%                 if dim(1) > 1;
%                    count_y{i,j,k} = mean(temp_count);
%                 else
%                    count_y{i,j,k}= temp_count;     % for only one repetition cases
%                 end
%                
%              else
%                 resp{k}(j,i) = 0; 
%                 count_y{i,j,k}=count_y{1,j,k};
%              end   
%              % normalize count_y
%              if max(count_y{i,j,k})~=0;
%                 count_y_norm{i,j,k}=count_y{i,j,k} / max(count_y{i,j,k});
%              else
%                 count_y_norm{i,j,k}=0;
%              end
%         end
%     end  
%     % now find the peak
%     [row_max, col_max] = find( resp{k}(:,:)==max(max(resp{k}(:,:))) )
%     % it is likely there are two peaks with same magnitude, choose the first one arbitraly
%     row_m{k}=row_max(1);
%     col_m{k}=col_max(1);
%     if max(count_y{col_max(1), row_max(1), k})~=0;
%      %  count_y_max{k} = count_y{col_max(1), row_max(1), k} / max(count_y{col_max(1), row_max(1), k}); % normalized
%        count_y_max{k} = count_y{col_max(1), row_max(1), k};
%       %count_y_max{k} = count_y{4, 3, k};
%     else
%        count_y_max{k} =0;
%     end
%     % find the largest y to set scale later
%     if max(count_y{col_max(1), row_max(1), k}) > max_count
%         max_count = max(count_y{col_max(1), row_max(1), k});
%     end
% end
% % %--------------------------------------------------------------------------
% % % compare whether there is delay over recording sesseion, cut into two parts
% % repetition = floor( length(spike_rates)/78); % take minimum repetition
% % if repetition >=5 % only include data more than 5 repetitions
% % 	max_trial = max(max( mean(count_y_trial{2,col_m{2},row_m{2}}(1:3,:)),mean(count_y_trial{2,col_m{2},row_m{2}}(4:end,:)) ));
% % 	count_trial_beg = mean(count_y_trial{2,col_m{2},row_m{2}}(1:3,:)) / max_trial;
% % 	count_trial_end = mean(count_y_trial{2,col_m{2},row_m{2}}(4:end,:)) / max_trial;
% %     repetition
% % end
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % calculate PSTH for each direction according to the eccentricity from the
% % % maximum direction, 45,90,135 and 180, all 5 variables
% % % techniquelly, given any maximum angle, go through all the directions to
% % % pick up any angles with expected difference. us norm, dot to calculate
% % % the angle between two vectors in 3D. 
% % 
% % count_y_45(3,frequency/timebin)=0;
% % count_y_90(3,frequency/timebin)=0;
% % count_y_135(3,frequency/timebin)=0;
% % % count_y_45(3,100)=0;
% % % count_y_90(3,100)=0;
% % % count_y_135(3,100)=0;
% % for k=1: length(unique_condition_num)
% %     for j=1:length(unique_elevation)
% %         for i=1: length(unique_azimuth)
% %             select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) );            
% %             if (sum(select) > 0)
% %                 [x,y,z]=sph2cart( unique_azimuth(i)*3.14159/180,unique_elevation(j)*3.14159/180,1 );
% %                 direction_c=[x,y,z];
% %                 [xm,ym,zm]=sph2cart( unique_azimuth(col_m{k})*3.14159/180,unique_elevation(row_m{k})*3.14159/180,1 );
% %                 direction_m=[xm,ym,zm];
% %                 diff_angle = 180*acos( dot(direction_c,direction_m) )/3.14159;
% %                 if diff_angle > -1 & diff_angle < 1
% %                     count_y_0(k,:) = count_y_norm{i,j,k};   % actually this is the same to count_y_max
% %                 elseif diff_angle > 44 & diff_angle < 46
% %                     count_y_45(k,:) = count_y_45(k,:) + count_y_norm{i,j,k};
% %                 elseif diff_angle > 89 & diff_angle < 91
% %                     count_y_90(k,:) = count_y_90(k,:) + count_y_norm{i,j,k};
% %                 elseif diff_angle > 134 & diff_angle < 136
% %                     count_y_135(k,:) = count_y_135(k,:) + count_y_norm{i,j,k};
% %                 elseif diff_angle > 179
% %                     count_y_180(k,:) = count_y_norm{i,j,k};
% %                 end                
% %             end
% %         end
% %     end
% % end
% 
% % plot PSTH now
% % get the largest count_y so that make the scale in each figures equal    
% % plot two lines as stimulus start and stop marker
% x_start = [StartEventBin(1,1)/timebin, StartEventBin(1,1)/timebin];
% x_stop =  [StopEventBin(1,1)/timebin,  StopEventBin(1,1)/timebin];
% y_marker=[0,max_count];
% % define figure
% figure(2);
% set(2,'Position', [5,5 1000,700], 'Name', '3D Direction Tuning');
% orient landscape;
% title(FILE);
% axis off;
% 
% xoffset=0;
% yoffset=0;
% 
% % now plot
% for k=1: length(unique_condition_num) 
%     
%     if( xoffset > 0.5)          % now temperarily 2 pictures one row and 2 one column
%         yoffset = yoffset-0.42;
%         xoffset = 0;
%     end
%     % output some text 
%     axes('position',[0 0 1 0.9]); 
%     xlim([-50,50]);
%     ylim([-50,50]);
%     text(-30+xoffset*100,52+yoffset*110, h_title{k} );
%     %text(-47,-40, 'Azim: 270       225       180        135        90        45        0        315        270');  
%     temp=fliplr(unique_azimuth');unique_azimuth_plot=[temp(2:end) temp(1:2)];clear temp
%     text(-47,-40, ['Azim:' num2str(unique_azimuth_plot)]);  
%     text(25,-40, 'Translation');
%     axis off;
%     hold on;
%     for i=1:length(unique_azimuth)+1                    % aizmuth 270 are plotted two times in order to make circular data
%         for j=1:length(unique_elevation)
%             axes('position',[0.05*i+0.01+xoffset (0.92-0.07*j)+yoffset 0.045 0.045]); 
% %             if (i < 8 )                                 % temporarilly line output figure with contour one, so that the middle panel corresponds to 90 deg,                             
% %                 bar( x_time,count_y{8-i,j,k}(1,:) );    % which is forward motion and the lateral edges correspond to 270 deg which is backward motion
% %             elseif(i==8)
% %                 bar( x_time,count_y{i,j,k}(1,:) ); 
% %             else
% %                 bar( x_time,count_y{7,j,k}(1,:) ); 
% %             end
%             if (i < length(unique_azimuth))                                 
%                 bar( x_time,count_y{length(unique_azimuth)-i,j,k}(1,:) );    
%             elseif(i==length(unique_azimuth))
%                 bar( x_time,count_y{i,j,k}(1,:) ); 
%             else
%                 bar( x_time,count_y{length(unique_azimuth)-1,j,k}(1,:) ); 
%             end
%             hold on;
%             plot( x_start, y_marker, 'r-');
%             plot( x_stop,  y_marker, 'r-');
%             set( gca, 'xticklabel', ' ' );
%             % set the same scale for all plot
%             xlim([0,x_length]);
%             ylim([0,max_count]);
%             
%         end    
%     end 
% 
%     xoffset=xoffset+0.46;
%     
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Frequency analysis for Tanya; 9-18-09
% %for i=1:length(unique_azimuth)
%     %for j=1:length(unique_elevation)
%         %[f, amp, resp_phase] = FT(x_time(1000/timebin+1:3000/timebin) * timebin/1000, count_y{i,j,k}(1,1:62), length(x_time(1:62)), 1, 1);
% % %         print; close;
%         %max_freq(i,j) = f(find(amp==max(amp)));
%          %max_amp(i,j) = max(amp);
%          %end
%          %end
%  %save(['C:\moog\' FILE '_maxfreq.mat']);
% %data_x = x_time*0.05; data_y=count_y{i,j,k}(1,:); FFT_PTS=length(x_time); DC_remove = 1; plot_flag = 1;
% 
% % Compute FFT of null trials (spontaneous activity) to characterize
% % pulsations -CRF & TY 12-2009
%   find_nulls = find(null_trials);
%  count_y_allnulls = zeros(1,x_length);
%  for t = 1:length(find_nulls)
% %     sum(spike_data_withnulls(1,5000*(t-1)+1:5000*(t-1)+5000))
%     temp_spike_times = spike_data_withnulls(1,5000*(find_nulls(t)-1)+1:5000*(find_nulls(t)-1)+5000);
%     for n=1:x_length
%         count_y_nulls(t,n) = sum(temp_spike_times((n-1)*timebin+1 : n*timebin));
%         count_y_allnulls(n) = count_y_allnulls(n) + sum(temp_spike_times((n-1)*timebin+1 : n*timebin));
%     end
% %     figure; bar(count_y_nulls(t,:));
%     [f, amp, resp_phase] = FT(x_time(1000/timebin+1:3000/timebin) * timebin/1000, count_y_nulls(t,(1000/timebin+1:3000/timebin)), length(x_time(1000/timebin+1:3000/timebin)), 1, 0);
%     max_freq_null(t) = f(find(amp==max(amp)));
%     max_amp_null(t) = max(amp);
% end
% % % 
% % % % plot average of null trials
% count_y_allnulls = count_y_allnulls/length(find_nulls);
% % figure; bar(count_y_allnulls);
% plot_flag_righthere = 0;
% [f, amp, resp_phase] = FT(x_time(1000/timebin+1:3000/timebin) * timebin/1000, count_y_allnulls((1000/timebin+1:3000/timebin)), length(x_time(1000/timebin+1:3000/timebin)), 1, plot_flag_righthere);
% if plot_flag_righthere
%     subplot(3,1,1); title(['Input Data - ' FILE ' - All Nulls']);
% end
% max_freq_allnulls = f(find(amp==max(amp)));
% max_amp_allnulls = max(amp);
% % % 
% % % save(['Z:\Users\Tanya\Nodulus_frequency_analysis\' FILE '_maxfreq_nulls.mat'], 'FILE', 'count_y_nulls', 'count_y_allnulls', 'max_freq_null', 'max_amp_null', 'max_freq_allnulls', 'max_amp_allnulls');
% % % % save(['C:\moog\' FILE '_maxfreq_nulls.mat']);
% % % 
% % % % temporary: to plot FT of a particular response direction
%   [f, amp, resp_phase] = FT(x_time(1000/timebin+1:3000/timebin) * timebin/1000, count_y{5,5,1}(1,(1000/timebin+1:3000/timebin)), length(x_time(1000/timebin+1:3000/timebin)), 1, 0);
% % %  [f, amp, resp_phase] = FT(x_time(1000/timebin+1:3000/timebin) * timebin/1000, count_y{i,j,k}(1,1:62), length(x_time(1:62)), 1, 1);
% % % 
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Special PSTH with velocity and acceleration information-- AC 02/17/08
% figure(3)
% t = 0:.05:1.85;
% ampl = 0.13;
% %sigma approximately equal to .17-.18
% num_sigs = 6;
% pos = ampl*0.5*(erf(2*num_sigs/3*(t-1)) + 1);
% veloc = diff(pos)/0.05;
% norm_veloc= veloc./max(veloc);
% accel = diff(veloc)/0.05;
% norm_accel= accel./max(accel); %normal acceleration
% % norm_accel= -accel./max(accel); %flipped acceleration
% x_start = [StartEventBin(1,1)/timebin, StartEventBin(1,1)/timebin];
% x_stop =  [StopEventBin(1,1)/timebin,  StopEventBin(1,1)/timebin];
% y_marker=[0,max_count];%y_marker=[0,max_count];
% xoffset=0;yoffset=0;
% 
% for k=1: length(unique_condition_num) % K = condition 1:vestibular, 2:visual
%     for i=1:8+1
%         for j=1:5
%             figure(k+2);axes('position',[0.1*(i-1)+0.05+xoffset (0.92-0.1*j)+yoffset 0.09 0.09]);
%             if (i < 8 )                                 % temporarilly line output figure with contour one, so that the middle panel corresponds to 90 deg,                             
%                 %             bar( x_time,count_y{8-i,j,k}(1,:) );    % which is forward motion and the lateral edges correspond to 270 deg which is backward motion
%                 bar( x_time(round(x_start(1,1)):round(x_stop(1,1))),count_y{8-i,j,k}(1,round(x_start(1,1)):round(x_stop(1,1))) );
%             elseif(i==8)
%                 bar( x_time(round(x_start(1,1)):round(x_stop(1,1))),count_y{i,j,k}(1,round(x_start(1,1)):round(x_stop(1,1))) ); 
%             else
%                 bar( x_time(round(x_start(1,1)):round(x_stop(1,1))),count_y{7,j,k}(1,round(x_start(1,1)):round(x_stop(1,1))) );
%             end
%             %         plot( x_start, y_marker, 'r-','LineWidth',2.0);
%             %         plot( x_stop,  y_marker, 'r-','LineWidth',2.0);
%             hold on;
% %             max_count=3;%Syed
%             if (i==5 & j==5)
%                 plot([ x_start(1,1):(x_stop(1,1)-x_start(1,1))/(length(norm_veloc)-1):x_stop(1,1)],0.5*max_count*(norm_veloc),'r','LineWidth',2.0);           
%                 %             plot([ x_start(1,1):(x_stop(1,1)-x_start(1,1))/(length(norm_accel)-1):x_stop(1,1)],0.5*max_count*(norm_accel),'g','LineWidth',2.0);
%                 text(0,-1, h_title{k});
%             else
%             end
%             set( gca, 'xticklabel', ' ');
%             if (i>1)
%                 set(gca,'yticklabel',' ');
%             end
%             % set the same scale for all plot
%             %         xlim([0,x_length]);
%             xlim([round(x_start(1,1)),round(x_stop(1,1))]);            
%             ylim([0,max_count]);             
%             %         if(j==5 & i==5)
%             %            ylim([-max_count,max_count]); 
%             %         else
%             %             ylim([0,max_count]);        
%             %         end        
%             axis off;
%         end
%     end    
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% figure(2);saveas(gcf,['Z:\Users\Aihua\Temporal_OutputData\' FILE(1:end-4) '_PSTH.png'],'png')
% saveas(gcf,['Z:\Users\Aihua\Temporal_OutputData\' FILE(1:end-4) '_PSTH.fig'])
% close (2);
% 
% 
% %---------------------------------------------------------------------------------------
% %Also, write out some summary data to a cumulative summary file
% sprint_txt = ['%s'];
% for i = 1 : x_length * 3
%      sprint_txt = [sprint_txt, ' %1.2f'];    
% end
% %buff = sprintf(sprint_txt, FILE, count_y_max{1},count_y_max{2},count_y_45(1,:)/8, count_y_45(2,:)/8,count_y_90(1,:)/8, count_y_90(2,:)/8,count_y_135(1,:)/8, count_y_135(2,:)/8, count_y_180(1,:), count_y_180(2,:));  
% %buff = sprintf(sprint_txt, FILE, count_y_max{1},count_y_max{2} );  % for 2 conditions
% buff = sprintf(sprint_txt, FILE, count_y_max{1} );   % for 1 conditions
% %buff = sprintf(sprint_txt, FILE, count_trial_beg,count_trial_end ); 
% 
% %outfile = [BASE_PATH 'ProtocolSpecific\MOOG\3Dtuning\DirectionTuning3D_PSTH_Tanya.dat'];
% outfile = ['Z:\Users\HuiM\psth.dat'];
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
% 
 return;
% 
