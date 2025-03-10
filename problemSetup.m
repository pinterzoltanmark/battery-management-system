function [obj,const] = problemSetup(threshold,switchcount,V_extmeas,G,SoC,SoCtemp,...
    I,Ieff,Iref,Iprev,Gprev,Vref,vmeas,OCVtemp,R0temp,v1temp,v2temp,CCCV,dQAh_pref,v1,v2,v1eff,v2eff)
% --------------------------------------------------------------- Globals
global deltaT ns n Qnom dQ R1ref R2ref tau1ref tau2ref ff_dQAh OCVnom Vmax_EV Vmin_inv Rbase Rterm vmin vmax
global stochastic

% Needs to be at the beginning of the code, since variable constraints
%   are modified
% Hard protection
idx_above = [find(SoCtemp > 100); find(vmeas > vmax)];
idx_below = [find(SoCtemp < 0); find(vmeas < vmin)];
idx_exceed = [idx_below idx_above];
idx_normal = 1:n;
idx_normal(idx_exceed) = [];
SoC.LowerBound(:,idx_exceed) = -1e3;
SoC.UpperBound(:,idx_exceed) = 1e3;
SoC.LowerBound(:,idx_normal) = 0;
SoC.UpperBound(:,idx_normal) = 100;
% Protection constraint
if Iref > 0
    const.SoCprotection = G(:,idx_below) == 0;
elseif Iref < 0
    const.SoCprotection = G(:,idx_above) == 0;
end

% --------------------------------------------------- McCormick relaxation
mccormick

% ------------------------------------------------------------ Expressions
% String measurement
if stochastic
    Vstring =...
        sum(G.*(ones(ns,1)*(OCVtemp - v2temp - v1temp)) - Ieff.*(ones(ns,1)*(R0temp+Rterm)),2)...
        - I*Rbase + 3e-3*randn(ns,1);
else
    Vstring =...
        sum(G.*(ones(ns,1)*OCVtemp) - v2eff - v1eff - Ieff.*(ones(ns,1)*(R0temp+Rterm)),2)...
        - I*Rbase + 3e-3*randn(ns,1);
end
% Mean SoC 
if stochastic
    if ~CCCV
        Gexp = (V_extmeas + Iref*Rbase) /mean(OCVtemp - v1temp - v2temp -  Iref*(R0temp + Rterm));
        SoCmean = mean(SoCtemp) -  Iref*(Gexp/n)*(100/Qnom*deltaT)*(1:ns-1)'*ones(1,n);
    else
        Gexp = (V_extmeas + Iprev*Rbase)/mean(OCVtemp - v1temp - v2temp - Iprev*(R0temp + Rterm));
        SoCmean = mean(SoCtemp) - Iprev*(Gexp/n)*(100/Qnom*deltaT)*(1:ns-1)'*ones(1,n);
    end
else
    SoCmean = mean(SoC(2:end,:),2)*ones(1,n);
end
% Weighted usage
dQAh_inc = sign(Iref)*Ieff*diag(dQ)*(deltaT/60);

% -------------------------------------------------------------- Objective
if ~CCCV
    CCCV_constraint =...
        [-(I - Iref) <= threshold(1);...
          (I - Iref) <= threshold(1)];
    CCCV_objective = threshold(1); % per string
else
    CCCV_constraint = [Vref - Vstring  <= threshold(1);...
                     -(Vref - Vstring) <= threshold(1)];
    CCCV_objective = threshold(1); % per string
end

SoCEqualization_constraint =...
    [-(SoC(2:end,:) - SoCmean) <= threshold(2);...
      (SoC(2:end,:) - SoCmean) <= threshold(2)];
SoCEqualization = threshold(2); % per cell
DeltaCurrentMinimization_constraint =...
    [-(I - [Iprev; I(1:end-1)]) <= threshold(3);...
      (I - [Iprev; I(1:end-1)]) <= threshold(3)];
DeltaCurrentMinimization = threshold(3); % per string
SoHEqualization_constraint =...
    (1-ff_dQAh)*ones(ns,1)*dQAh_pref + ff_dQAh*dQAh_inc <= threshold(4);
SoHEqualization = threshold(4); % per cell

obj = 1e-1*SoCEqualization +...
    stochastic*1e-6*SoHEqualization +...
    (1 + (Iref > 0)*1e1)*CCCV_objective +...
    (Iref > 0)*1e4*DeltaCurrentMinimization;

% ------------------------------------------------------------ Constraints
% Kirchhoff law
const.kirchhoff = [Vstring - V_extmeas  <= OCVnom/10;...
                 -(Vstring - V_extmeas) <= OCVnom/10];
% SoC progression constraints
const.SoCinitial = SoC(1,:) == SoCtemp;
const.SoCprogression =...
    SoC(2:end,:) == SoC(1:end-1,:) - Ieff(1:end-1,:)*diag(100/Qnom*deltaT);
% Voltage progression constraints
% if ~stochastic 
% %     const.v1initial = v1 == ones(ns,1)*v1temp;
%     const.v1initial = v1(1,:) == v1temp;
%     const.v1progression =...
%         v1(2:end,:) == v1(1:end-1,:).*(ones(ns-1,1)*(1 - deltaT./tau1ref))...
%         + Ieff(1:end-1,:).*(ones(ns-1,1)*(deltaT./tau1ref.*R1ref));
% %     const.v2initial = v2 == ones(ns,1)*v2temp;
%     const.v2initial = v2(1,:) == v2temp;
%     const.v2progression =...
%         v2(2:end,:) == v2(1:end-1,:).*(ones(ns-1,1)*(1 - deltaT./tau2ref))...
%         + Ieff(1:end-1,:).*(ones(ns-1,1)*(deltaT./tau2ref.*R2ref));
% end
% Functionality constraints
if Iref > 0
    const.Vlim = Vstring <= Vmax_EV;
    if ~CCCV
        const.Ilim = [I >= Iref*0.9; Iref*1.1 >= I];
    else
        const.Ilim = [I >= 20; Iref*1.1 >= I];
    end
elseif Iref < 0
    const.Vlim = Vstring >= Vmin_inv;
    const.Ilim = [I <= -30; Iref*1.25 <= I];
end
if Iprev % && ((Iprev > 110) || (Iprev < -30))  % && stochastic 
    const.switchcount1 = [ G - [Gprev; G(1:end-1,:)]  <= switchcount;...
                         -(G - [Gprev; G(1:end-1,:)]) <= switchcount];
    const.switchcount2 = sum(switchcount,2) <= 30; 
end
% Helping constraints
const.sumGlim = [sum(G,2) <= Vref/2.8; Vref/3.5 <= sum(G,2)];
% Constraints related to objectives
const.currenttracking = CCCV_constraint;
const.socequalization = SoCEqualization_constraint;
const.sohequalization = SoHEqualization_constraint;
const.deltacurrentminimization = DeltaCurrentMinimization_constraint;
% McCormick relaxation constraint
const.mcCormick_Ieff = mcCormick_Ieff <= 0;

end