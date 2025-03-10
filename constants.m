% -------------------------------------------------------------- Constants
global deltaT nt simT nsim t ns n
% Function for bounded Gaussian distribution
randb = @(std,n1,n2) min(max(-3*std,std*randn(n1,n2)),3*std);
% Time
deltaT = .5;                            % Switching time [min]
nt = 200;                               % # minutes
simT = deltaT/10;                       % Simulation time step [min]
nsim = nt/simT;                         % # simulation time instants
t = simT:simT:nt;                       % Time vector
if stochastic
    ns = 2;                             % Time horizon: more than 1 means prediction
else
    ns = 5;
end
n = 300;                                % # Cells
global OCVref OCV OCVnom vmin vmax
% OCV-SoC curve
load ocvsoc.mat
OCVref = squeeze(mean(ocvsoc,3));
OCVref = mean(OCVref(:,2:3),2);
OCV = OCVref*(1 + randb(0.5e-3*stochastic,1,n));
OCVnom = 3.2;                           % Nominal voltage [V]
vmin = 2.8;                             % Minimum voltage [V]
vmax = 3.45;                            % Maximum voltage [V]
global Qnom Q dQ
% Capacities
Qnom = 100*60;
Q = Qnom*(0.95 + randb(0.05*stochastic,1,n));
dQ = max(Q) - Q;                        % Capacity difference from max
global R0ref R0 R1ref R1 R2ref R2 C1 C2 tau1ref tau1 tau2ref tau2 Rbase Rterm
global OCV_EV R0_EV R1_EV R2_EV tau1_EV tau2_EV 
% Resistance, capacitance and time constant, battery cells
load thevenin.mat
R0ref = squeeze(mean(R0,3));
R0ref = mean(R0ref(:,2:3),2);
R1 = squeeze(mean(R1,3));
R1orig = mean(R1(:,2:3),2);
R2 = squeeze(mean(R2,3));
R2orig = mean(R2(:,2:3),2);
C1 = squeeze(mean(C1,3));
C1 = mean(C1(:,2:3),2);
C2 = squeeze(mean(C2,3));
C2 = mean(C2(:,2:3),2);
R0 = R0ref*(Qnom./Q + randb(0.1*stochastic,1,n));
R1 = R1orig*(Qnom./Q + randb(0.1*stochastic,1,n));
R2 = R2orig*(Qnom./Q + randb(0.1*stochastic,1,n));
C1orig(1,:) = C1(2,:);
C2orig(1,:) = C2(2,:);
C1 = C1orig*(1 + randb(0.1*stochastic,1,n));
C2 = C2orig*(1 + randb(0.1*stochastic,1,n));
tau1 = R1.*C1;
tau2 = R2.*C2;
tau1 = tau1/60;
tau2 = tau2/60;
R1ref = mean(R1,'all')*ones(1,n);   % Reference resistance (shared)
R2ref = mean(R2,'all')*ones(1,n);   % Reference resistance (shared)
tau1ref = mean(tau1,'all')*ones(1,n);   % Reference resistance (shared)
tau2ref = mean(tau2,'all')*ones(1,n);   % Reference resistance (shared)
Rbase = 0.1;                        % Accummulated mosfet, PCB and connector resistance
Rterm = 6e-5;                       % Terminal connection resistance
global eff_EV Iref_EV OCV_EVnom Q_EVnom Vmax_EV
global EV_turnup Q_EVturnup SoC_EVturnup SoCref_EVturnup
% ------------------------------------------------- The electrical vehicle
eff_EV = 0.96;                      % Eff. of 94% leads to 15A jumps per cell
Iref_EV = 125;                      % Reference current [A]
OCV_EVnom = 350.4;                  % Nominal OCV of EV [V]
Q_EVnom = 61.8e3*60/OCV_EVnom;      % Nominal capacity of an EV -
Vmax_EV = 403;                      % Maximum voltage connected to an EV [V]
EV_turnup = binornd(1,1e-3,nsim,1); % Turnups of EVs
Q_EVturnup = Q_EVnom*(0.8 + 0.7*rand(nsim,1));
SoC_EVturnup = 20*rand(nsim,1);
SoCref_EVturnup =...
    (SoC_EVturnup + 20) + (100 - (SoC_EVturnup + 20)).*rand(nsim,1);
tau1_EV = tau1_EV/60;
tau2_EV = tau2_EV/60;
global Iref_inv OCV_inv eff_inv R_inv Vmin_inv
% The inverter 
Iref_inv = -70;                     % Charging current reference [A]
OCV_inv = 800;                      % Interface voltage of inverter [V]
eff_inv = 0.98;                     % Inverter efficiency [-]
R_inv = (1 - eff_inv)*OCV_inv/abs(Iref_inv); % Equivalent inverter resistance
Vmin_inv = 720;                     % Min. interface voltage to inverter [V]
global ff_I ff_dQAh
% --------------------------------------------- Energy Management System
ff_I = 0.3;                         % Forg. factor for I uncertainty
ff_dQAh = 0.1;                      % Forg. factor for dQAh preference
% ------------------------------------------------------------- Recording
record.constants.deltaT = deltaT;
record.constants.simT = simT;
record.constants.nsim = nsim;
record.constants.t = t;
record.constants.ns = ns;
record.constants.n = n;
record.constants.OCV = OCV;
record.constants.OCVnom = OCVnom;
record.constants.Qnom = Qnom;
record.constants.Q = Q;
record.constants.dQ = dQ;
record.constants.R0 = R0;
record.constants.R1 = R1;
record.constants.R2 = R2;
record.constants.tau1 = tau1;
record.constants.tau2 = tau2;
record.constants.R0ref = R0ref;
record.constants.R1ref = R1ref;
record.constants.R2ref = R2ref;
record.constants.tau1ref = tau1ref;
record.constants.tau2ref = tau2ref;
record.constants.Rbase = Rbase;
record.constants.eff_EV = eff_EV;
record.constants.Iref_EV = Iref_EV;
record.constants.OCV_EVnom = OCV_EVnom;
record.constants.Q_EVnom = Q_EVnom;
record.constants.Vmax_EV = Vmax_EV;
record.constants.EV_turnup = EV_turnup;
record.constants.Q_EVturnup = Q_EVturnup;
record.constants.SoC_EVturnup = SoC_EVturnup;
record.constants.SoCref_EVturnup = SoCref_EVturnup;
record.constants.OCV_EV = OCV_EV;
record.constants.R0_EV = R0_EV;
record.constants.R1_EV = R1_EV;
record.constants.R2_EV = R2_EV;
record.constants.tau1_EV = tau1_EV;
record.constants.tau2_EV = tau2_EV;
record.constants.Iref_inv = Iref_inv;
record.constants.OCV_inv = OCV_inv;
record.constants.R_inv = R_inv;
record.constants.Vmin_inv = Vmin_inv;