% --------------------------------------------------------------- Plant
% If the voltage limit is exceeded
if (CCCV && Vmax_EV < V_extmeas) || (Vmin_inv > V_extmeas && Iref < 0)
    warning(['Voltage limit exceeded at ' num2str(it*simT)])
    Gtemp(:) = 0;
    Iopt = 0;
    Itemp = 0;
    noop = 1;
end
% If SoC or voltage exceeds the limit, the cell operation is abrupted
idx_below = find(SoCest_temp < 0 | vmeas < vmin);
idx_above = find(SoCest_temp > 100 | vmeas > vmax);
if Iref > 0
    Gtemp(:,idx_below) = 0;
elseif Iref < 0
    Gtemp(:,idx_above) = 0;
end
% Parameters
SoCmean_temp = mean(SoCtemp);
for it_cell = 1:n
    OCVtemp(:,it_cell) = interp_regular(soc(1),soc(end),OCV(:,it_cell)',SoCtemp(it_cell));
    if stochastic
        OCVest_temp(:,it_cell) = interp_regular(soc(1),soc(end),OCVref',SoCest_temp(it_cell));
    else
        OCVest_temp(:,it_cell) = OCVtemp(:,it_cell);
    end
    R0temp(:,it_cell) = interp_regular(0,110,R0(:,it_cell)',SoCtemp(it_cell));
    if stochastic
        R0est_temp(:,it_cell) = interp_regular(0,110,R0ref',SoCest_temp(it_cell));
    else
        R0est_temp(:,it_cell) = R0temp(:,it_cell);
    end
    R1temp(:,it_cell) = interp_regular(0,110,R1(:,it_cell)',SoCtemp(it_cell));
    R2temp(:,it_cell) = interp_regular(0,110,R2(:,it_cell)',SoCtemp(it_cell));
    tau1temp(:,it_cell) = interp_regular(0,110,tau1(:,it_cell)',SoCtemp(it_cell));
    tau2temp(:,it_cell) = interp_regular(0,110,tau2(:,it_cell)',SoCtemp(it_cell));
end
% Iterative method to find voltage and current
if ~noop && any(Gtemp)
    switch mode
        case 'charging'
            Itemp =...
                (sum(Gtemp.*(OCVtemp - v1temp - v2temp)) - OCV_inv)/...
                (R_inv + sum(Gtemp.*(R0temp + Rterm)) + Rbase);
            Rj_temp = R_inv + sum(Gtemp.*(R0temp + Rterm)) + Rbase +...
                sum(Gtemp.*(v1temp + v2temp))/Itemp;
        case 'discharging'
            Itemp =...
                (sum(Gtemp.*(OCVtemp - v1temp - v2temp)) - V1_EVtemp - V2_EVtemp - OCV_EVtemp)/...
                (R0_EVtemp + sum(Gtemp.*(R0temp + Rterm)) + Rbase);
            Rj_temp = R0_EVtemp + sum(Gtemp.*R0temp) + Rbase +...
                (sum(Gtemp.*(v1temp + v2temp)) + V1_EVtemp + V2_EVtemp)/Itemp;
    end
else
    Gtemp(:) = 0;
    Itemp = 0;
    Iopt = 0;
end
% Over current protection
if abs(Itemp) > 200
    warning(['Measured current over limit at ' num2str(it*simT)])
    Gtemp(:) = 0;
    Iopt = 0;
    Itemp = 0;
    noop = 1;
end
vtemp = OCVtemp - v1temp - v2temp - (R0temp + Rterm)*Itemp;
vmeas = vtemp + 3e-3*randn(1,n);
Vstring_temp = sum(Gtemp.*vtemp) - Itemp*Rbase;
% Abrupting operation in case of low power
if ~rem(it-1,10) && Itemp < 50 && strcmp(mode,'discharging')
    disp(['Low power at time ' num2str(it*simT)])
    Gtemp(:) = 0;
    Itemp = 0;
    Iopt = 0;
    noop = 1;
end
% Abrupting operation in case of power flow uncertainty
if (Itemp < 10 && strcmp(mode,'discharging')) ||...
        (Itemp > -10 && strcmp(mode,'charging'))
    disp(['Power flow uncertainty at time ' num2str(it*simT)])
    Gtemp(:) = 0;
    Itemp = 0;
    Iopt = 0;
    if ~rem(it-1,10)
        noop = 1;
    end
end
% Effective current
Ieff_temp = Gtemp.*Itemp;
% Time progression: the BESS
v1temp = v1temp.*(1 - simT./tau1temp) + Ieff_temp.*(simT./tau1temp.*R1temp);
v2temp = v2temp.*(1 - simT./tau2temp) + Ieff_temp.*(simT./tau2temp.*R2temp);
if stochastic
    v1est_temp = v1est_temp.*(1 - simT./tau1ref) + Ieff_temp.*(simT./tau1ref.*R1ref);
    v2est_temp = v2est_temp.*(1 - simT./tau2ref) + Ieff_temp.*(simT./tau2ref.*R2ref);
else
    v1est_temp = v1temp;
    v2est_temp = v2temp;
end
SoCtemp = SoCtemp - Ieff_temp.*(100./Q*simT);
SoCest_temp = SoCest_temp - Ieff_temp.*(100/Qnom*simT);
% Time progression: the electrical vehicle
switch mode
    case 'charging'
        SoC_EVtemp = NaN;
        OCV_EVtemp = NaN;
        V1_EVtemp = NaN;
        V2_EVtemp = NaN;
    case 'discharging'
        SoC_EVtemp = SoC_EVtemp + Itemp*100/Q_EV*simT;
        OCV_EVtemp = interp_regular(soc_EV(1),soc_EV(end),ocv_EV,SoC_EVtemp);
        R0_EVtemp = interp_regular(soc_EV(1),soc_EV(end),R0_EV,SoC_EVtemp);
        R1_EVtemp = interp_regular(soc_EV(1),soc_EV(end),R1_EV,SoC_EVtemp);
        R2_EVtemp = interp_regular(soc_EV(1),soc_EV(end),R2_EV,SoC_EVtemp);
        tau1_EVtemp = interp_regular(soc_EV(1),soc_EV(end),tau1_EV,SoC_EVtemp);
        tau2_EVtemp = interp_regular(soc_EV(1),soc_EV(end),tau2_EV,SoC_EVtemp);
        V1_EVtemp = V1_EVtemp.*(1 - simT./tau1_EVtemp) + Itemp.*(simT./tau1_EVtemp.*R1_EVtemp);
        V2_EVtemp = V2_EVtemp.*(1 - simT./tau2_EVtemp) + Itemp.*(simT./tau2_EVtemp.*R2_EVtemp);
        V_EVtemp = OCV_EVtemp + Itemp*R0_EVtemp + V1_EVtemp + V2_EVtemp;
end
% Ah progression
Ah_inc = abs(Ieff_temp)*simT/60;
Ah = Ah + Ah_inc;
dQAh_pref = (1 - ff_dQAh)*dQAh_pref + ff_dQAh*Ah_inc*diag(dQ);
% Efficiency and losses
losstemp = Itemp*Itemp*Rj_temp;
switch mode
    case 'charging'
        efftemp = 1 - losstemp/abs(Itemp*OCV_inv);
    case 'discharging'
        efftemp = 1 - losstemp/abs(Itemp*sum(Gtemp.*OCVtemp));
end
% -------------------------------------------------------------- Recording
if strcmp(algorithm,'optimization')
    record.exitflag(it,:) = exitflag;
end
record.I(it,:) = Itemp;
record.Ah(it,:) = Ah;
record.SoC(it,:) = SoCtemp;
record.SoCest(it,:) = SoCest_temp;
record.SoC_EV(it,:) = SoC_EVtemp;
record.Vref(it,:) = Vref;
record.SoC_EVref(it,:) = SoC_EVref;
record.G(it,:) = Gtemp;
record.Ieff(it,:) = Ieff_temp;
record.v(it,:) = vtemp;
record.v1(it,:) = v1temp;
record.v2(it,:) = v2temp;
record.v1est(it,:) = v1est_temp;
record.v2est(it,:) = v2est_temp;
record.Vstring(it,:) = Vstring_temp;
record.loss(it,:) = losstemp;
record.eff(it,:) = efftemp;
record.Rj(it,:) = Rj_temp;
record.uncertainty_factor(it,:) = uncertainty_factor;
record.toc(it,:) = toctemp;