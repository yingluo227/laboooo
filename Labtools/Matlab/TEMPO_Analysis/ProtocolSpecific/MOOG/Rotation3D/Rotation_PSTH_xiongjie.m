function Rotation_PSTH_xiongjie(data, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, StartEventBin, StopEventBin, PATH, FILE, Protocol);

Path_Defs;
ProtocolDefs; %contains protocol specific keywords - 1/4/01 BJP

%get the column of values for azimuth and elevation and stim_type
temp_azimuth = data.moog_params(ROT_AZIMUTH,:,MOOG); 
temp_elevation = data.moog_params(ROT_ELEVATION,:,MOOG); 
 temp_stim_type = data.moog_params(STIM_TYPE,:,MOOG);  
   temp_spike_data = data.spike_data(SpikeChan,:);
   temp_spike_rates = data.spike_rates(SpikeChan, :);    
   
%    dlmwrite('temp_azimuth.txt',temp_azimuth)
%    dlmwrite('temp_elevation .txt',temp_elevation)
%    dlmwrite('temp_stim_type.txt',temp_stim_type)
%    dlmwrite('temp_spike_data.txt',temp_spike_data)
%    dlmwrite('temp_spike_rates.txt',temp_spike_rates)
 dlmwrite('StartEventBin.txt',StartEventBin);
dlmwrite('StopEventBin.txt',StopEventBin);
 save('data', '-struct', 'data')
  
% %get indices of any NULL conditions (for measuring spontaneous activity
% null_trials = logical( (temp_azimuth == data.one_time_params(NULL_VALUE)) );
% 
% %now, remove trials from direction and spike_rates that do not fall between BegTrial and EndTrial
% trials = 1:length(temp_azimuth);		% a vector of trial indices
% select_trials= ( (trials >= BegTrial) & (trials <= EndTrial) ); 
% 
% azimuth = temp_azimuth(~null_trials & select_trials);
% elevation = temp_elevation(~null_trials & select_trials);
% stim_type = temp_stim_type(~null_trials & select_trials);
% 
% % stim_duration = length(temp_spike_data)/length(temp_azimuth);
% % spike_data = data.spike_data(1, ((BegTrial-1)*stim_duration+1):EndTrial*stim_duration);
% spike_rates= temp_spike_rates(~null_trials & select_trials);
% % notice that this bad_trials is the number without spon trials 
% 
% unique_azimuth = munique(azimuth');
% unique_elevation = munique(elevation');
% unique_stim_type = munique(stim_type');
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
% % remove null trials, bad trials (rates >3000), and trials outside Begtrial~Endtrial
% stim_duration = length(temp_spike_data)/length(temp_azimuth);
% Discard_trials = find(null_trials==1 | trials <BegTrial | trials >EndTrial);
% for i = 1 : length(Discard_trials)
%     temp_spike_data( 1, ((Discard_trials(i)-1)*stim_duration+1) :  Discard_trials(i)*stim_duration ) = 9999;
% end
% spike_data = temp_spike_data( temp_spike_data~=9999 );
% spike_data( find(spike_data>100) ) = 1; % something is absolutely wrong 
% 
% % count spikes from raster data (spike_data)
% max_count = 1;
% time_step=1;
% for k=1:length(unique_condition_num)  
%     for j=1:length(unique_elevation)       
%         for i=1:length(unique_azimuth)
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
%     [row_max, col_max] = find( resp{k}(:,:)==max(max(resp{k}(:,:))) );
%     % it is likely there are two peaks with same magnitude, choose the first one arbitraly
%     row_m{k}=row_max(1);
%     col_m{k}=col_max(1);
%     if max(count_y{col_max(1), row_max(1), k})~=0;
%        count_y_max{k} = count_y{col_max(1), row_max(1), k} / max(count_y{col_max(1), row_max(1), k});
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
% % count_y_45(3,100)=0;
% % count_y_90(3,100)=0;
% % count_y_135(3,100)=0;
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
% set(2,'Position', [5,5 1000,700], 'Name', '3D Rotation Tuning');
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
%     text(-47,-40, 'Azim: 270        225       180       135         90         45         0         315        270');
%     text(25,-40, 'Rotation');
%     axis off;
%     hold on;
%     for i=1:length(unique_azimuth)+1                    % aizmuth 270 are plotted two times in order to make circular data
%         for j=1:length(unique_elevation)
%             axes('position',[0.05*i+0.01+xoffset (0.92-0.07*j)+yoffset 0.045 0.045]); 
%             if (i < 8 )                                 % temporarilly line output figure with contour one, so that the middle panel corresponds to 90 deg,                             
%                 bar( x_time,count_y{8-i,j,k}(1,:) );    % which is forward motion and the lateral edges correspond to 270 deg which is backward motion
%             elseif(i==8)
%                 bar( x_time,count_y{i,j,k}(1,:) ); 
%             else
%                 bar( x_time,count_y{7,j,k}(1,:) ); 
%             end
%             hold on;
%             plot( x_start, y_marker, 'r-');
%             plot( x_stop,  y_marker, 'r-');
%             set( gca, 'xticklabel', ' ' );
%             % set the same scale for all plot
%             xlim([0,x_length]);
%             ylim([0.6*max_count,max_count]);%----temporaly off
% %             ylim([0,10]);% for m3c296r1r3, [0,6], for m3c294r1r3, [0,10]
%         end    
%     end 
% 
%     xoffset=xoffset+0.46;
%     
% end
% 
% %---------------------------------------------------------------------------------------
% % TEMP: Manually plot circular array of PSTH's (at a given elev)
% % to show oppositely-tuned vel and acc responses -- CRF 6/19/07
% best_elev = 45;
% j = find(unique_elevation==best_elev); k = 1; span = 67;
% figure(10); set(10,'Position', [25,100 700,700]);
% title([FILE ' - Elev = ' num2str(best_elev)]); axis off;
% xscale = .28;
% yscale = .32;
% xoffset = .42;
% yoffset = .42;
% for i=1:length(unique_azimuth)
%     axes('position',[xscale*cos(unique_azimuth(i)*pi/180)+xoffset yscale*sin(unique_azimuth(i)*pi/180)+yoffset 0.18 0.12]);
%     bar(x_time, count_y{i,j,k});
%     hold on;
%     plot( x_start, y_marker, 'r-');
%     plot( x_stop,  y_marker, 'r-');
%     set( gca, 'xticklabel', ' ' );
%     set( gca, 'yticklabel', ' ' );
%     % set the same scale for all plot
%     xlim([0,span]);
%     ylim([0,max_count]);
% end
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Special PSTH with velocity and acceleration information-- AC 01/18/08
% close (10);
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
% y_marker=[0,max_count];
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
%             max_count=8;%Syed
%             if (i==5 & j==5)
%                 plot([ x_start(1,1):(x_stop(1,1)-x_start(1,1))/(length(norm_veloc)-1):x_stop(1,1)],0.5*max_count*(norm_veloc),'r.','LineWidth',2.0);           
%                 %             plot([ x_start(1,1):(x_stop(1,1)-x_start(1,1))/(length(norm_accel)-1):x_stop(1,1)],0.5*max_count*(norm_accel),'g.','LineWidth',2.0);
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
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% %---------------------------------------------------------------------------------------
% %Also, write out some summary data to a cumulative summary file
% %sprint_txt = ['%s'];
% %for i = 1 : x_length * 3
% %     sprint_txt = [sprint_txt, ' %1.2f'];    
% %end
% %buff = sprintf(sprint_txt, FILE, count_y_max{1},count_y_max{2},count_y_45(1,:)/8, count_y_45(2,:)/8,count_y_90(1,:)/8, count_y_90(2,:)/8,count_y_135(1,:)/8, count_y_135(2,:)/8, count_y_180(1,:), count_y_180(2,:));  
% %buff = sprintf(sprint_txt, FILE, count_y_max{1},count_y_max{2},count_y_max{3} );  
% %buff = sprintf(sprint_txt, FILE, count_trial_beg,count_trial_end ); 
% 
% %outfile = [BASE_PATH 'ProtocolSpecific\MOOG\DirectionTuning3D_PSTH.dat'];
% %printflag = 0;
% %if (exist(outfile, 'file') == 0)    %file does not yet exist
% %    printflag = 1;
% %end
% %fid = fopen(outfile, 'a');
% %if (printflag)
% %    fprintf(fid, 'FILE\t');
% %    fprintf(fid, '\r\n');
% %end
% %fprintf(fid, '%s', buff);
% %fprintf(fid, '\r\n');
% %fclose(fid);
% 
% return;
% 
