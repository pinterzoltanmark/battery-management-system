% --------------------------------------------------------------- Coloring
global deltaT nt simT nsim t ns n
global OCV OCV_nom
global Qnom Q dQ
global R0 R1 R2 C1 C2 tau1 tau2 Rref
global eff_EV Iref_EV OCV_EVnom Q_EVnom Vmax_EV EV_turnup Q_EVturnup
global Iref_inv OCV_inv eff_inv R_inv Vmin_inv
global ff_I
% -------------------------------------------------------------- Variables
variables

% ------------------------------------------------- We have a problem here
prob = optimproblem('ObjectiveSense','min');
options = optimoptions('intlinprog',"Display",'none',"MaxTime",30+(1-stochastic)*290,...
     "RelativeGapTolerance",1e-4,"AbsoluteGapTolerance",0,...
     "ConstraintTolerance",1e-4,"IntegerTolerance",1e-5);

% --------------------------------------------------------------- Solution
Gprev = Gtemp;
for it = 1:nsim
    noop_it = 0;
    % ------------------------------------------------- Event handling
    eventhandling
    % Frequency of actuation
    if ~rem(it-1,10) && ~strcmp(mode,'idle')
        tic
        % Uncertainty factor
        if Itemp
            uncertainty_factor = (1-ff_I)*uncertainty_factor + ff_I*Iopt/Itemp;
        end
        % Previous current value
        Gprev = Gtemp;
        Iprev = Itemp;
        if ~noop
            disp(['Act. at ' num2str(it*simT) ', SoC '...
                num2str(mean(SoCest_temp(:))) ', std '...
                num2str(std(SoCest_temp(:))) ', I '...
                num2str(Itemp) ', EV ' num2str(SoC_EVtemp)])
            % Note: Vref is different for the heuristic algorithm
            % ---------------------------------------------- Mode setting
            modesetting
            % Optimization ------------------------------------------
            optimize
            if exitflag > 0
                Gtemp = round(sol.G(1,:));
                Itemp = sol.I(1);
                Iopt = sol.I(1);
            elseif exitflag <= 0
                options.MaxTime = 2*options.MaxTime;
                for noop_it = 1:4
                    disp('Solving time iteration again')
                    optimize
                    if exitflag > 0
                        disp('Solution found before cancelling operation')
                        Gtemp = round(sol.G(1,:));
                        Itemp = sol.I(1);
                        Iopt = sol.I(1);
                        options.MaxTime = 5;
                        break
                    end
                end
                if noop_it == 4
                    noop = 1;
                    Gtemp(:) = 0;
                    Itemp = 0;
                    options.MaxTime = 5;
                    disp('Cancelling operation')
                end
            end
        else % if ~noop
            disp(['Cancelled actuation at time ' num2str(it*simT) ' with SoC '...
                num2str(mean(SoCest_temp(:)))])
        end % if ~noop
        toctemp = toc;
    end % if ~rem(it-1,10) && ~strcmp(mode,'idle')
    % -------------------------------------------------------------- Plant
    plant
end % it