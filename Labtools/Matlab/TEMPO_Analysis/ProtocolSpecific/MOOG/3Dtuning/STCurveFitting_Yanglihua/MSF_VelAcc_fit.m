function [space_fit,vect_calculated,r_squared,Current_ci,cor] = MSF_VelAcc_fit(spacetime_data, vect_Vel,timestep,allow_negative)
% MSFfit fits a Modified Sinusoid Function (MSF) to data using 'fmincon', with parameter bounds
%	It calls MSFerr.m to comput the error for each set of params.  The function 
%   evaluated is given by MSFfunc.m

clear global rawdata xdata tdata
global rawdata xdata tdata 
rawdata=spacetime_data;

x = ([1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26])'; % for fitting
for i = 1:size(spacetime_data,2)%101
    xdata(:, i) = x;    
end

t=0:timestep:timestep*(size(spacetime_data,2)-1);% t=0:0.05:2.5;
for i = 1:size(spacetime_data,1)
    tdata(i,:) = t;
end
xtdata = [xdata; tdata]; 

max_val=max(max(rawdata));
min_val=min(min(rawdata));
% max_indx=find(rawdata==max_val);
% min_indx=find(rawdata==min_val);

global model_use
model_use=2;

min_err = 9999999999999999.99;
if allow_negative
    LB = [0 -5*(max_val-min_val) 0.0001 0 0 0 -0.5 -90 0 0 -90];   % lower bounds
%     LB = [0 -5*(max_val-min_val) 0.0001 (0*45*pi/180) 1.115 0 -0.5 0 (0*45*pi/180)];   % lower bounds
    UB = [1.35*max_val 1.5*(max_val-min_val) 10 315 max(t) 6 0 90 1 315 90];   % upper bounds
else
    LB = [0 0 0.0001 0 0 0 -0.5 -90 0 0 -90];   % lower bounds
%     LB = [0 0 0.0001 (0*45*pi/180) 1.115 0 -0.5 0 (0*45*pi/180)];;
    UB = [1.35*max_val 1.5*(max_val-min_val) 10 315 max(t) 6 0 90 1 315 90];   % upper bounds
end
N = 20;
vect = [vect_Vel 0 0 -90];
vect_temp9 = LB(9) : (UB(9)-LB(9))/(N-1) : UB(9);
vect_temp10 = LB(10) : (UB(10)-LB(10))/(N-1) : UB(10);
vect_temp11= LB(11) : (UB(11)-LB(11))/(N-1) : UB(11);

for k = 1:N
    vect_t9 = vect_temp9(k);
    for l = 1:N
        vect_t10 = vect_temp10(l);
        vect_t11 = vect_temp11(l);
        vect_temp = [vect(1) vect(2) vect(3) vect(4) vect(5) vect(6) vect(7) vect(8) vect_t9 vect_t10 vect_t11];
        error = cosnlin_err(vect_temp);
        if (error < min_err)
            vect_t9min = vect_t9;
            vect_t10min = vect_t10;
            min_err = error;
        end
    end
end

vect(9) = vect_t9min;vect(10) = vect_t10min;
min_err = cosnlin_err(vect);% min_err = 100000;%min_err = 9999999999999999.99;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ydata = rawdata;
wiggle = 0.5;
% wiggle = 0.9;                  
N_reps = 100;

options = optimset('Display', 'off', 'MaxIter', 5000, 'LevenbergMarquardt', 'on'); % 'LevenbergMarquardt', 'on'); % 'Tolx',1e-4,
A = []; b = []; Aeq = []; beq = []; nonlcon = [];
err_pars=[];
for j=1:N_reps
    j;
    rand_factor = rand(size(vect)) * wiggle + (1-wiggle/2); % ranges from 1-wiggle/2 -> 1 + wiggle/2
    clear temp_vect;temp_vect = vect .* rand_factor;
    [testpars{j},resnorm{j},residual{j},exitflag{j},output{j},lambda{j},jacobian{j}] = lsqcurvefit('funccosnlin', temp_vect, xtdata, ydata, LB, UB, options);
    err_pars(j) = cosnlin_err(testpars{j});
    clear rand_factor temp_vect;
end

[min_err min_indx] = min(err_pars);
clear vect_calculated;vect_calculated=testpars{min_indx};%clear vect_calculated;vect_calculated = testpars_min;
space_fit = (funccosnlin(vect_calculated, xtdata));
Current_err = cosnlin_err(vect_calculated);
err_total = sum( sum(( ydata - mean(mean(ydata)) ) .^2) );
r_squared = (1 - ((Current_err)^2 / err_total));
Current_ci = nlparci(vect_calculated,residual{min_indx},jacobian{min_indx});

%%%%%%%%%%%%%%
%calculate variance cov matrix and correlation matrix of parameters
jac=full(jacobian{min_indx});
xtx=jac'*jac;
xtxinv=inv(xtx);
varinf=diag(xtxinv);
cor=xtxinv./sqrt(varinf*varinf');

return;