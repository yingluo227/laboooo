function [pars] = loggaussfit(means,raw)
% LOGGAUSSFIT fits a Gaussian function to the natural log of the data with an offset using Simplex algorithm.
%	It calls loggauss_err.m to comput the error for each set of params
%	Params are as follows: Bg (q1)=base rate, A (q2) = scale factor, vn (q3), sigma (q4), v0 (q5)
%   A*exp(-1/2/sigma^2 * (ln((v+v0)/(vn+v0)))^2) + Bg
global Data RawData;

%allows calculation of error for both raw data and mean data
Data = means;
RawData = raw;

% first, generate some initial parameter guesses
[max_val	max_indx] = max(Data(:,2));
[min_val	min_indx] = min(Data(:,2));
N_values = length(Data(:,1));
fixed_v0=1; %set this flag to true and set the default value you like to loggaussfunc, then also at bottom of this func.
fixed_sigma=1;%choose to pars(5) for return (is in an if statement at the bottom)
%You must fix v0 if you're going to fix sigma.

%these starting conditions generally work wellq(1) = min_val; %bg rate
q(2) = max_val - min_val; %scale factorq(3) = Data(max_indx,1); %best observed speed, vn

%knowing the 1/e points and vn (after removing bg and normalizing) gives us v0 and sigma,
%so we will find the closest points and use those for our starting conditions.
%In general this hasn't been working too well but it's so quick to do why not?
left_of_vn=Data(logical(Data(:,1)<q(3)),:);
right_of_vn=Data(logical(Data(:,1)>q(3)),:);

%some annoying if/thens follows with a fair amount of code duplication if you're
%fixing v0 or v0 and sigma. 
if ~(fixed_v0)
  if ~(isempty(left_of_vn) | isempty(right_of_vn))
    left_of_vn(:,2)=(left_of_vn(:,2)-q(1))./q(2);%normalize both
    right_of_vn(:,2)=(right_of_vn(:,2)-q(1))./q(2);
    %find left and right points
    [temp left_index]=min(abs(left_of_vn(:,2)-exp(-1)));
    [temp right_index]=min(abs(right_of_vn(:,2)-exp(-1)));
    left_point=left_of_vn(left_index,1);
    right_point=right_of_vn(right_index,1);
    %now we use our expression for v0 in terms of v- (vleft) v+ (vright) and vn, which is:
    %v0= (vn^2 - v+ * v-)/(v+ + v- - 2*vn)
    q(5) = (q(3)^2 - right_point*left_point)/max((right_point + left_point - 2*q(3)),.1); %avoid divide by 0 error    %and now sigma=1/2/sqrt(2) * ln( (v+ + v0)/ (v- + v0))
    q(4) = max([1/2/sqrt(2) * log( (right_point + q(5)) / (left_point + q(5))),.01]);
    min_err = loggauss_err(q);
  else % we just do tha parameter search so go ahead and use those intial values
   q(4)=.1;
   q(5)=.1;
   min_err=Inf;
  %in general it's pretty quick to do a coarse
  %blind search of the parameter space, so we do one now (only the last 3 params though):
  end
  q(~isfinite(q))=1;

  for i = 1:1:40      % vn
      for j = .05:05:4    % sigma
          for k = .05:.05:10 % v0
              qtemp = q;
              qtemp(3) = i;
              qtemp(4) = j;
              qtemp(5) = k;
              temp_err = loggauss_err(qtemp);
              if (temp_err < min_err)
                  min_err = temp_err;
                  q(3) = i;
                  q(4) = j;
                  q(5) = k;
              end
          end
      end
  end
            
q(5)=5.5;
  
  A=[]; B=[]; Aeq=[]; Beq=[]; NONLCON=[];
  LB=[0;0;0;.05;.001];
  UB=[1.5*min_val;1.5*(max_val - min_val);50;10;6];
else
  %in general it's pretty quick to do a coarse
  %blind search of the parameter space, so we do one now (only the last 3 params though):
  if ~(fixed_sigma)
    min_err=Inf;
    for i = 1:1:40      % vn
        for j = .05:05:2    % sigma  for k = .05:.05:2 % sigma
              qtemp = q;
              qtemp(3) = i;
              qtemp(4) = j;
              temp_err = loggauss_err(qtemp);
              if (temp_err < min_err)
                  min_err = temp_err;
                  q(3) = i;
                  q(4) = j;
              end
        end
    end
    A=[]; B=[]; Aeq=[]; Beq=[]; NONLCON=[];
    LB=[0;0;0;.05];
    UB=[1.5*min_val;1.5*(max_val - min_val);50;6];
  else
    min_err=Inf;
    for i=1:.1:40
        qtemp=q;
        qtemp(3)=i;
        temp_err = loggauss_err(qtemp);
        if (temp_err < min_err)
            min_err = temp_err;
            q(3)=i;
        end
    end
    A=[]; B=[]; Aeq=[]; Beq=[]; NONLCON=[];
    LB=[0;0;0];
    UB=[1.5*min_val;1.5*(max_val - min_val);75];
  end
end
OPTIONS = OPTIMSET('fmincon');
OPTIONS = OPTIMSET('LargeScale', 'off', 'LevenbergMarquardt', 'on', 'MaxIter', 5000, 'Display', 'off');
%OPTIONS = OPTIMSET('LargeScale', 'off', 'LevenbergMarquardt', 'on', 'MaxIter', 5000);
N_reps = 10;
wiggle = 0.6;
testpars = []; err=[];
for j=1:N_reps
    rand_factor = rand(length(q),1) * wiggle + (1-wiggle/2); %ranges from 1-wiggle/2 -> 1 + wiggle/2
    temp_q = q' .* rand_factor;
    testpars{j} = fmincon('loggauss_err',temp_q,A,B,Aeq,Beq,LB,UB, NONLCON, OPTIONS);
    err(j) = loggauss_err(testpars{j});
end
%now find best fit and return the parameters
[min_err min_indx] = min(err);
pars = testpars{min_indx};
if (fixed_v0)
    if (fixed_sigma)
        pars(4)=1.22; %set this value also in loggaussfunc
    end
    pars(5)=0.01; %set this value also in loggaussfunc
end
return;