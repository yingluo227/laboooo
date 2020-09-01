function err = gamma_err(q)
%GAMMA_ERR Used by GAMMAFIT.
%	GAMMA_ERR(q) returns the error between the data and the
%	values computed by the GAMMAFUNC function.

global Data RawData

x = RawData(:,1);
y = RawData(:,2);

z = gammafunc(x,q);

%threshold the fitted values (don't allow less than zero)
% return the sum squared error
%NOTE; we are minimizing differences between sqrt of data and sqrt of function
%THis is because the sqrt helps to homogenize the variance of the neuronal responses
%across values of the independent variable.
err = norm(sqrt(z)-sqrt(y))^2;

return;