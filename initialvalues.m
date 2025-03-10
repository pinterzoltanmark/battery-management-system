% --------------------------------------------------------------- Coloring
global deltaT nt simT nsim t ns n
global OCV OCV_nom
global Qnom Q dQ
global R0 R1 R2 C1 C2 tau1 tau2 R0ref
global eff_EV Iref_EV OCV_EVnom Q_EVnom Vmax_EV EV_turnup Q_EVturnup
global Iref_inv OCV_inv eff_inv R_inv Vmin_inv
global ff
% --------------------------------------------------------- Initial values
% BESS
SoCtemp = 102 - 20*rand(1,n);        % State of charge [%]
SoCest_temp = SoCtemp + stochastic*(5*rand(1,n) - 2.5);      % Est. state of charge [%]
OCVtemp = zeros(1,n);                           % OCV [V]
R0est_temp = zeros(1,n);                        % Est. series resistance [Ohm]
for it_cell = 1:n
    OCVtemp(:,it_cell) =...                     
        interp1(soc,OCV(:,it_cell),SoCtemp(it_cell),'linear','extrap');
    R0est_temp(:,it_cell) =...
        interp1(0:10:110,R0ref,SoCest_temp(it_cell),'linear','extrap');
end
OCVest_temp = OCVtemp;                          % Est. OCV [V]
vtemp = OCVtemp;                                % Cell voltage [V]
vmeas = vtemp + 3e-3*randn(1,n);                % Meas. of cell voltage [V]
Itemp = 0;                                      % Current [I]
v1temp = zeros(1,n);                            % Diff. voltage 1 [V]
v2temp = zeros(1,n);                            % Diff. voltage 2 [V]
v1est_temp = zeros(1,n);                        % Est. of diff. voltage 1 [V]
v2est_temp = zeros(1,n);                        % Est. of diff. voltage 2 [V]
R0temp = NaN(1,n);                              % Series resistance [Ohm] (param)
R1temp = NaN(1,n);                              % Diff. resistance 1 [Ohm] (param)
R2temp = NaN(1,n);                              % Diff. resistance 2 [Ohm] (param)
Gtemp = zeros(1,n);                             % Engagement signal [-]
Vstring_temp = zeros(1,n);                      % String voltage [V]
Ah = zeros(1,n);                                % Ah throughput [Ah]
Ieff_temp = NaN(1,n);                           % Effective current [A]
% EV
V1_EVtemp = 0;                                  % Diff. voltage 1 [V]
V2_EVtemp = 0;                                  % Diff. voltage 2 [V]
SoC_EVtemp = 0;                                 % SoC of EV [%]
SoC_EVref = 100;                                % Required departure SoC
OCV_EVtemp = interp1(soc_EV,ocv_EV,SoC_EVtemp,'linear','extrap'); % OCV of EV
V_EVtemp = OCV_EVtemp;                          % EV voltage [V]
R0_EVtemp = interp1(soc_EV,R0_EV,SoC_EVtemp,'nearest','extrap'); % EV series resistance
Q_EV = Q_EVnom;                                 % EV capacity
% --------------------------------------------------------- Initial values
mode = 'discharging';                   % Mode: charging or discharging
noop = 0;                               % No operation flag
CCCV = 0;                               % CCCV flag, CC: 0, CV: 1
dQAh_pref = zeros(1,n);                 % Usage preference weight
uncertainty_factor = 1;     % Factor to improve the estimated current
% -------------------------------------------------------- Recording setup
% Preparation
record.I = NaN(nsim,1);
record.SoC = NaN(nsim,n);
record.SoCest = NaN(nsim,n);
record.SoC_EV = NaN(nsim,1);
record.Vref = NaN(nsim,1);
record.SoC_EVref = NaN(nsim,1);
record.G = NaN(nsim,n);
record.SoCeff = NaN(nsim,n);
record.Ieff = NaN(nsim,n);
record.Vstring = NaN(nsim,1);
record.loss = NaN(nsim,1);
record.eff = NaN(nsim,1);
record.Ah = NaN(nsim,n);
record.v = NaN(nsim,n);
record.v1 = NaN(nsim,n);
record.v2 = NaN(nsim,n);
record.v1est = NaN(nsim,n);
record.v2est = NaN(nsim,n);
record.Rj = NaN(nsim,1);
record.uncertainty_factor = NaN(nsim,1);
record.toc = NaN(nsim,1);
% Optimization exit flags
if strcmp(algorithm,'optimization')
    record.exitflag = NaN(nsim,1);
end
% Recording initial values
record.initialvalues.SoC = SoCtemp;
record.initialvalues.SoCest = SoCest_temp;
record.initialvalues.I = Itemp;
record.initialvalues.G = Gtemp;
record.initialvalues.SoC_EV = SoC_EVtemp;
record.initialvalues.Q_EV = Q_EV;