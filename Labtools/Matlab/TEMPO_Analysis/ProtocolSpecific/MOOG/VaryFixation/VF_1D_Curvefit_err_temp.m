% VF_1D_Curvefit_err_temp.m -- computes the error between the square root of the
% data and the square root of the values from VF_1D_Curvefit

function err = VF_1D_Curvefit_err_temp(x,n,k,reps)

global xdata ydata_merged

yfit_eye = VF_1D_Curvefit(x,xdata);

err = sum(sum((sqrt(yfit_eye) - sqrt(ydata_merged{n}( (k-1)*reps + 1 : k*reps , : ))).^2));

return;