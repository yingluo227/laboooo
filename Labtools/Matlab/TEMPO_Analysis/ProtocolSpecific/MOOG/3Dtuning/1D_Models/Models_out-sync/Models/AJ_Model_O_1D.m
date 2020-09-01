% Acceleration-jerk model for 3D tuning 20170602LBY
% a is parameter set
% u_azi is unique azimuth ( 0,45,90,135,180,225,270,315 )
% u_ele is unique elevation ( 0, -+45, -+90 )
% t is PSTH time points

function r = AJ_Model_O_1D(a,st_data)

u_azi = st_data(1:8);
t = st_data(9:end);

% acceleration model
%time profile
acc_time = acc_func(a(3), t);
%spatial profiles
azi_a = cos_tuning_1D(a(7:9), u_azi);

% jerk model
%time profile
jerk_time = jerk_func(a(3)+a(11), t);
%spatial profiles
azi_j = cos_tuning_1D(a(7:9), u_azi);

%compute results
r = zeros(length(azi_a), length(acc_time));
for i=1:size(r,1),
        rr =a(1)*(a(10)*azi_a(i)*acc_time + (1-a(10))*azi_j(i)*jerk_time)+ a(2);
        rr(find(rr<0))  = 0;
        r(i,:) = rr;
end

end
