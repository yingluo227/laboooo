%the function takes in a data set that is a cell array containing 30 2 column vectors, One column is time
%and the other is the data to be fitted.

function total_pars = gaussfit_new_1D(means, row_max, col_max, file_name, spon, rat, is_rejected, current_col, current_row, no_fit, stimtype)
% gaussfit fits a Gaussian function to data using 'fmincon', with parameter bounds
%	It calls gausserr.m to comput the error for each set of params.  THe function 
%   evaluated is given by gaussfunc.m

global Data;
N=20;
is_empty = zeros(1,30);

Total_Data = means;
ratio = rat;
DC = spon;
no_plot = is_empty;
reject = is_rejected;
azi = current_col;
gaze = current_row;

% find directions that have not been rejected 
good_dir = find(reject == 0);

pos_err(30) = 0;
pos_err_veloc(30) = 0;
pars{30} = 0;
pars_veloc{30} = 0;
gaussian{30} = 0;
zz{30} = 0;
zz1{30} = 0;
dgaussian{30} = 0;
zzz{30} = 0;
zzz1{30} = 0;
vel{30} = 0;
acc{30} = 0;
velocity_only{30} = 0;
F_Combined_Velocity(30) = 0;
P_Combined_Velocity(30) = 0;
VAF_comb(30) = 0;
VAF_vel(30) = 0;
parameters1{30} = 0;
parameters2{30} = 0;
%Fit only directions that have not been rejected (good_dir)
if no_fit

    for i = 1:length(good_dir)
        file_name
        i
        out_of = length(good_dir)
        
        Data = Total_Data{good_dir(i)};
        
        % first, generate some initial parameter guesses
        [max_val max_indx] = max(Data(:,2));
        [min_val min_indx] = min(Data(:,2));
        [max_x max_x_indx] = max(Data(:,1));
        [min_x min_x_indx] = min(Data(:,1));
        
        N_values = length(Data(:,1));
        
        q(1) = DC(good_dir(i));
        q(2) = .3;
        q(3) = 2;
        q(4) = 0.2*(max_x - min_x);
        q(5)= .3;
        
        r(1) = DC(good_dir(i));
        r(2) = (max_val - min_val);
        r(3) = 2;
        r(4) = 0.2*(max_x - min_x);
        
        s(1) = DC(good_dir(i));
        s(2) = (max_val - min_val);
        s(3) = 2;
        s(4) = 0.2*(max_x - min_x);
        
        
        %Starting here, search for better starting values of q(3) and q(4)
        q3temp = q(3);
        q3range = (max_x-min_x)/2.66;
        q1range = 0:.065:.4;
        q1range = q1range*DC(good_dir(i));
        min_err = 9999999999999999.99;
        min_err_veloc = 9999999999999999.99;
        min_err_veloc_unconstr = 9999999999999999.99;
        min_err_sig = 9999999999999999.99;
        
        exponent = [0.05 .1 .15 .2 .25 .3 .42 .54 .66 .8];
        number = [sort(-exponent) 0 exponent];
        loop_number=[];
        cycle_number=[];

        %for combined velocity/acceleration
        for sp = 1:7
            q(1) = q1range(sp);
            for k = 1:10
                q(2) = exponent(k);
                for p=1:N           
                    q(3) = q3temp + (p-1)*q3range/N;
                    for j = 1:N
                        q(4) = j*(max_x-min_x)/N;         
                        for h=1:20
                            q(5) = number(h);
                            error = gausserr_neg(q);
                            if (error < min_err)
                                q1min = q(1);
                                q2min = q(2);
                                q3min = q(3);
                                q4min = q(4);
                                q5min = q(5);
                                min_err = error;    
                            end
                        end
                    end
                end
            end
        end
        
        q(1) = q1min;
        q(2) = q2min;
        q(3) = q3min;
        q(4) = q4min;
        q(5) = q5min;
        pos_err(good_dir(i)) = min_err;
        
        
        %for velocity
        r3temp = r(3);
        r3range = (max_x-min_x)/2.66;
        r1range = q1range;
        for spon2 = 1:7
            r(1) = r1range(spon2);
            for kik = 1:10
                r(2) = exponent(kik);
                for ii=1:N
                    r(3) = r3temp + (ii-1)*r3range/N; 
                    for jj = 1:N
                        r(4) = jj*(max_x-min_x)/N;  
                        error_veloc=gausserr_anuk(r);
                        if (error_veloc < min_err_veloc)
                            r1min = r(1);
                            r3min = r(3);
                            r4min = r(4);
                            r2min = r(2);
                            min_err_veloc = error_veloc;    
                        end
                    end
                end
            end
        end
        r(1) = r1min;
        r(3) = r3min;
        r(4) = r4min;
        r(2) = r2min;
        pos_err_veloc(good_dir(i)) = min_err_veloc;

        
        %for unconstrained velocity
        s3temp = s(3);
        s3range = (max_x-min_x)/2.66;
        s1range = 0:.05:.4;
        for spon2 = 1:length(s1range)
            s(1) = s1range(spon2);
            for kik = 1:10
                s(2) = exponent(kik);
                for ii=1.15:.1:3
                    s(3) = ii; 
                    for jj = 1:N
                        s(4) = jj*(max_x-min_x)/N;  
                        error_veloc_unconstr=gausserr_anuk(s);
                        if (error_veloc_unconstr < min_err_veloc_unconstr)
                            s1min = s(1);
                            s3min = s(3);
                            s4min = s(4);
                            s2min = s(2);
                            min_err_veloc_unconstr = error_veloc_unconstr;    
                        end
                    end
                end
            end
        end
        s(1) = s1min;
        s(3) = s3min;
        s(4) = s4min;
        s(2) = s2min;
        pos_err_veloc_unconstr(good_dir(i)) = min_err_veloc_unconstr;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Fit with combined model
        A=[]; B=[]; Aeq=[]; Beq=[]; NONLCON=[];
        
        LB=[0.7*DC(good_dir(i)); 0; 2; 0.05*(max_x - min_x); -1];  %lower bounds
        UB=[1.3*DC(good_dir(i)); 1; 2.5; 0.85; 1]; %upper bounds
        
        OPTIONS = OPTIMSET('fmincon');
        OPTIONS = OPTIMSET('LargeScale', 'off', 'LevenbergMarquardt', 'on', 'MaxIter', 5000, 'Display', 'off');
        
        N_reps = 40;
        wiggle = 0.2;
        testpars = []; err=[];
        
        for kk=1:N_reps
            rand_factor = rand(length(q),1) * wiggle + (1-wiggle/2); %ranges from 1-wiggle/2 -> 1 + wiggle/2
            temp_q = q' .* rand_factor;
            testpars{kk} = fmincon('gausserr_neg',temp_q,A,B,Aeq,Beq,LB,UB, NONLCON, OPTIONS);
            err(kk) = gausserr_neg(testpars{kk});
        end
        %now find best fit and return the parameters
        [min_err min_indx] = min(err);
        pars{good_dir(i)} = testpars{min_indx};
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Fit with velocity model
        
        LB_veloc=[0.7*DC(good_dir(i)); 0; 2; 0.05*(max_x - min_x)];  %lower bounds for velocity
        UB_veloc=[1.3*DC(good_dir(i)); 1.5*(max_val - min_val); 2.5; .85]; %upper bounds for velocity

        for pp=1:N_reps
            rand_factor_veloc = rand(length(r),1) * wiggle + (1-wiggle/2); %ranges from 1-wiggle/2 -> 1 + wiggle/2
            temp_r = r' .* rand_factor_veloc;
            testpars_veloc{pp} = fmincon('gausserr_anuk',temp_r,A,B,Aeq,Beq,LB_veloc,UB_veloc, NONLCON, OPTIONS);
            err_veloc(pp) = gausserr_anuk(testpars_veloc{pp});
        end
        [min_err_veloc min_indx] = min(err_veloc);
        pars_veloc{good_dir(i)} = testpars_veloc{min_indx};
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Fit with unconstrained velocity model
        
        LB_veloc_unconstr=[0.7*DC(good_dir(i)); 0; 1.15; 0.05*(max_x - min_x)];  %lower bounds for unconstr velocity
        UB_veloc_unconstr=[1.3*DC(good_dir(i)); 1.5*(max_val - min_val); 3; .85]; %upper bounds for unconstr velocity

        for pp=1:N_reps
            rand_factor_veloc_unconstr = rand(length(s),1) * wiggle + (1-wiggle/2); %ranges from 1-wiggle/2 -> 1 + wiggle/2
            temp_s = s' .* rand_factor_veloc_unconstr;
            testpars_veloc_unconstr{pp} = fmincon('gausserr_anuk',temp_s,A,B,Aeq,Beq,LB_veloc_unconstr,UB_veloc_unconstr, NONLCON, OPTIONS);
            err_veloc_unconstr(pp) = gausserr_anuk(testpars_veloc_unconstr{pp});
        end
        [min_err_veloc_unconstr min_indx] = min(err_veloc_unconstr);
        pars_veloc_unconstr{good_dir(i)} = testpars_veloc_unconstr{min_indx};

        
        dummy_pars = pars{good_dir(i)};
        %Find the combined fit function
        gaussian{good_dir(i)} = gaussfunc_anuk(Data(:,1), pars{good_dir(i)});     
        
        zz{good_dir(i)} = exp(-0.5*((Data(:,1) - dummy_pars(3))/ dummy_pars(4)).^2);
        zz1{good_dir(i)} = zz{good_dir(i)}./max(zz{good_dir(i)});
        dgaussian{good_dir(i)} = diff(zz1{good_dir(i)});
        zzz{good_dir(i)} = [dgaussian{good_dir(i)}' dgaussian{good_dir(i)}(end)];
        zzz{good_dir(i)} = zzz{good_dir(i)}./.05;
        zzz1{good_dir(i)} = zzz{good_dir(i)}./max(zzz{good_dir(i)});
        
        %velocity component
        vel{good_dir(i)} = (dummy_pars(1) + dummy_pars(2).*zz1{good_dir(i)});
        %acceleration component
        acc{good_dir(i)} = (dummy_pars(5).*zzz1{good_dir(i)}');
        
        %Fit the data with a pure gaussian only
        velocity_only{good_dir(i)}= gaussfunc_anuk(Data(:,1),pars_veloc{good_dir(i)});
        
        %sequential f test
        Velocity_SSE = gausserr_anuk(pars_veloc{good_dir(i)});
        Combined_SSE = gausserr_anuk(pars{good_dir(i)});
        
        nfree_Velocity = 4;
        nfree_Combined = 5;
        
        F_Combined_Velocity(good_dir(i)) = ( (Velocity_SSE - Combined_SSE)/(nfree_Combined-nfree_Velocity) ) / ( Combined_SSE/(length(Data(:,1))-nfree_Velocity) );
        P_Combined_Velocity(good_dir(i)) = 1 - fcdf(F_Combined_Velocity(good_dir(i)), (nfree_Combined-nfree_Velocity), (length(Data(:,1))-nfree_Combined) );
        Time=Data(:,1);
        
        
        % VAF
        pop_mean = mean(Data(:,2));
        dat_err = sum(((Data(:,2) - pop_mean).^2));
        fit_err_comb = sum(((gaussian{good_dir(i)} - Data(:,2)).^2));
        VAF_comb(good_dir(i)) = (1 - fit_err_comb/dat_err);
        
        fit_err_vel = sum(((velocity_only{good_dir(i)} - Data(:,2)).^2));
        VAF_vel(good_dir(i)) = (1 - fit_err_vel/dat_err);
        
        parameters1{good_dir(i)} = [pars{good_dir(i)}(2) pars{good_dir(i)}(5) pars_veloc{good_dir(i)}(2)];
        parameters2{good_dir(i)} = [VAF_comb(good_dir(i)) VAF_vel(good_dir(i)) P_Combined_Velocity(good_dir(i))];
        
        if parameters1{good_dir(i)}(1) < 0.00000001 
            parameters1{good_dir(i)}(1) = 0;
        elseif parameters1{good_dir(i)}(2) < 0.00000001 & parameters1{good_dir(i)}(2) > -0.00000001
            parameters1{good_dir(i)}(2) = 0;
        elseif parameters1{good_dir(i)}(3) < 0.00000001
            parameters1{good_dir(i)}(3) = 0;
        end
        % [azimuth gaze p_val VAF_comb VAF_vel DC_com b tau_comb sigma_comb a DC_vel K tau_vel sigma_vel ratio]
        total_pars{i} = [azi(good_dir(i)) gaze(good_dir(i)) P_Combined_Velocity(good_dir(i)) VAF_comb(good_dir(i)) VAF_vel(good_dir(i)) pars{good_dir(i)}' pars_veloc{good_dir(i)}' pars_veloc_unconstr{good_dir(i)}' ratio(good_dir(i))];
        
    end

else total_pars = {};
end

%plot the data
% figure
%plot_vect contains the directions that are being plotted in the order that
%subplot plots them

% figure(12); title([FILE '  Visual']); orient landscape; set(12,'Position', [25,50 1250,750]);
col = col_max;
row = row_max;
layout = [1:3:28; 2:3:29 ; 3:3:30];
max_direction = layout(row, col);

b1 = ['a'];
b2 = ['b'];
b3 = ['K'];
b4 = ['std ratio'];
b5 = ['VAF(comb)'];
b6 = ['VAF(vel)'];
b7 = ['p val'];

tt = 1.05:.05:2.85;
Time = tt;
k=1;
for i = 1:10
    for j = 1:3
        
        low_bound = 0;
        if length(acc{k}) > 0
            low_bound = min(acc{k});
        end
                       
        h = subplot('position',[.01+(0.097*(i-1)) 0.65-(0.3*(j-1)) 1/12 1/5]);
        bar(Time, Total_Data{k}(:,2))
        axis([1,3,low_bound,1])
        text(1, 1.05, num2str(ratio(k)))
        hold on
        
        if is_empty(k) == 0 & reject(k) == 0
            for f = 1:3
                par_lab1{f} = num2str(sprintf('%1.4f', parameters1{k}(f)));
            end
            plot(Time, velocity_only{k}, 'g', 'linewidth',2)
            plot(Time, gaussian{k}, ' m', 'linewidth', 2)
            plot(Time, acc{k}, 'c-.', 'linewidth', 2)
            plot(Time, vel{k}, 'r--', 'linewidth', 2)
            
            text(2.25, 1.17, texlabel(par_lab1{1}))
            text(2.25, 1.05, texlabel(par_lab1{2}))
            text(1, 1.17, texlabel(par_lab1{3}))
            
            if k == max_direction
                text(2, (min(acc{k})+ 0.1), 'Max')
            end
        
        else 
            text(1, 1.16, 'Rejected')
            if k == max_direction
                text(2.5, 0.9, 'Max')
            end
        end

        if k == 1
            text(1, 1.3, 'Legend:  Green = vel only,  Pink = combined')
        end

        
        if k == 13
            text(1, 1.45, [file_name '   ' stimtype])
        end
        
        if k == 25
            text(2, 1.3, b4)
            text(2, 1.42, b3)
            text(3.5, 1.3, b1)
            text(3.5, 1.42, b2)
        end
        
        set(h, 'XTick', [])
        set(h, 'YTick', [])
        k=k+1;
        
    end
end
print
close





return;
