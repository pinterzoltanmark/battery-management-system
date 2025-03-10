% --------------------------------------------------------------- Coloring
global deltaT nt simT nsim t ns n
global OCV OCVnom
global Qnom Q dQ
global R0 R1 R2 C1 C2 tau1 tau2 Rref Rbase
global eff_EV Iref_EV OCV_EVnom Q_EVnom Vmax_EV EV_turnup Q_EVturnup
global Iref_inv OCV_inv eff_inv R_inv Vmin_inv
global ff_I ff_dQAh
global stochastic
% --------------------------------------------------------------- Solution
Iopt = Itemp;
Vstring_prev = sum(Gtemp.*vtemp);
for it = 1:nsim
    Gprev = Gtemp;
    % ------------------------------------------------- Event handling
    eventhandling
    % Actuation time instants
    if ~rem(it-1,10) && ~strcmp(mode,'idle')
        tic
        % External source choice 
        modesetting
        % Uncertainty factor
        if Itemp
            uncertainty_factor = (1 - ff_I)*uncertainty_factor + ff_I*Iopt/Itemp;
        end
        % SoC and voltage protection
        switch mode
            case 'charging'
                exceed = find(SoCest_temp > 100 | vmeas > vmax);
            case 'discharging'
                exceed = find(SoCest_temp < 0 | vmeas < vmin);
        end
        % Predicted value in case of engagement
        vpred = vmeas -...
            (1 - Gtemp).*((R0est_temp + Rterm)*Iref + v1est_temp + v2est_temp);
        % SoC overcharging / overdepleting protection
        SoCsafe = SoCest_temp;
        switch mode
            case 'charging'
                SoCsafe(exceed) = 1e9;
                [~, sortidx_SoC] = sort(SoCsafe,'ascend');
                [~,sortidx_SoC_back] = sort(sortidx_SoC);
            case 'discharging'
                SoCsafe(exceed) = -1e9;
                [~, sortidx_SoC] = sort(SoCsafe,'descend');
                [~,sortidx_SoC_back] = sort(sortidx_SoC);
        end
        % Protected version of dQAh_pref counting
        dQAh_pref_safe = dQAh_pref;
        dQAh_pref_safe(exceed) = 1e9;
        % Sorting according to Ah
        [~, sortidx_Ah] = sort(dQAh_pref_safe,'ascend');
        [~, sortidx_Ah_back] = sort(sortidx_Ah);
        % Sorting based on integrated ranking
        sortidx_back = stochastic*8*sortidx_Ah_back + sortidx_SoC_back;
        [~, sortidx] = sort(sortidx_back);
        % ----------------------------------- Reducing Manhattan distance
        if it > 1
            sortidx15 = sortidx(1:15);
            sortidx(16:end) = NaN;
            for it_ex = 1:length(exceed)
                sortidx15(sortidx15==exceed(it_ex)) = [];
            end
            sortidx(1:length(sortidx15)) = sortidx15;
            idx = length(sortidx15) + 1;
            for it_sort = 1:n
                if ~any(sortidx15 == sortidx_prev(it_sort)) && ...
                        ~any(sortidx_prev(it_sort) == exceed)
                    sortidx(idx) = sortidx_prev(it_sort);
                    idx = idx + 1;
                end
            end
            for it_sort = 1:n
                if ~any(sortidx == sortidx_prev(it_sort))
                    sortidx(idx) = sortidx_prev(it_sort);
                    idx = idx + 1;
                end
            end
        end
        sortidx_prev = sortidx;
        vsort = vpred(sortidx);
        % Cell iteration strategy
        switch mode
            case 'charging'
                it_cell_iteration = n:-1:1;
            case 'discharging'
                if Itemp
                    it_cell_iteration = 1:1:n;
                else
                    it_cell_iteration = (sum(Gprev)-1):n;
                end
        end
        % Initial variables for event handling
        voltage_match = 0;
        noop = 1;
        for it_cell = it_cell_iteration
            % Voltage match at reference voltage is the starting point
            Vstringopt = sum(vsort(1,1:it_cell)) - Iref*Rbase;
            switch mode
                case 'charging'
                    if Vstringopt < OCV_inv
                        voltage_match = 1;
                    end
                case 'discharging'
                    if Vstringopt > Vref - 2*OCVnom 
                        voltage_match = 1;
                    end
            end
            if voltage_match
                % Checking for feasibility
                if any(exceed == sortidx(it_cell))
                    noop = 1;
                    warning(['Lack of operational cells at ' num2str(it*simT)])
                    break
                end
                % Actuation without delta current minimization
                Gtemp_0 = zeros(1,n);
                Gtemp_0(sortidx(1:it_cell)) = 1;
                Iopt_0 = (sum(Gtemp_0.*(OCVtemp - v1est_temp - v2est_temp)) - V_extmeas)...
                    /(sum(Gtemp_0.*(R0est_temp + Rterm)) + Rbase);
                % Conditions to comply with max voltage and ref. current
                switch mode
                    case 'charging'
                        voltage_limit_condition = Vstringopt > Vmin_inv;
                        CCCV_condition =...
                            Iopt_0 < Iref_inv*uncertainty_factor*0.9 && Iopt_0 > 2*Iref_inv;
                    case 'discharging'
                        voltage_limit_condition = Vstringopt < Vmax_EV + OCVnom;
                        if ~CCCV
                            CCCV_condition =...
                                Iopt_0 > Iref_EV*uncertainty_factor*0.95 && Iopt_0 < 200;
                        else
                            CCCV_condition = Iopt_0 > 20 && Vstringopt > Vref - OCVnom;
                        end
                end
                % Actuation
                if voltage_limit_condition
                    if CCCV_condition
                        % Delta current minimization    
                        Gtemp = zeros(1,n);
                        Gtemp(sortidx(1:it_cell-1)) = 1;
                        % Sorting for the last cell
                        vcand = vsort;
                        for it_ex = 1:length(exceed)
                            vcand(sortidx==exceed(it_ex)) = 1e9;
                        end
                        vcand = vcand(it_cell:end);
                        [~, sortidx_vcand] =...
                            sort(abs((sum(vsort(1:it_cell-1)) + vcand) - Vstring_prev),'ascend');
                        lastcellidx = it_cell-1 + sortidx_vcand(1);
                        if ~any(sortidx(lastcellidx) == exceed)
                            Gtemp(sortidx(lastcellidx)) = 1;
                        else
                            warning('Warning: problem with indexation')
                            Gtemp = Gtemp_0;
                        end
                        Iopt = (sum(Gtemp.*(OCVtemp - v1est_temp - v2est_temp)) -V_extmeas)...
                            /(sum(Gtemp.*(R0est_temp + Rterm)) + Rbase);
                        noop = 0;
                        break
                    end % if(CCCV_condition)
                else % if(voltage_limit_condition)
                    switch mode
                        case 'charging'
                            Gtemp(:) = 0;
                            Itemp = 0;
                            Iopt = 0;
                            noop = 1;
                            break
                        case 'discharging'
                            % Vmax is exceeded
                            disp(['Vmax exceeded at time ' num2str(it*simT)])
                            if ~CCCV
                                disp('Discharging: CV')
                                CCCV = 1;
                                noop = 0;
                            else
                                noop = 1;
                                disp('Terminating EV charging')
                            end
                            break
                    end % switch mode
                end % if(voltage_limit_condition)
            end % if(voltage_match)
        end % it_cell
        % If the SoCs prevent to find a feasible configuration
        if noop
            warning(['No solution at ' num2str(it*simT)])
            Gtemp(:) = 0;
            Iopt = 0;
            Itemp = 0;
        end
        % If the SoC protection failed
        if sum(Gtemp(exceed))
            error('Error: SoC protection failed')
        end
        % Measuring running time
        toctemp = toc;
    end % if ~rem(it-1,10) && if ~strcmp(mode,'idle')
    % Current limit warning
    if abs(Iopt) > 200
        warning(['Estimated current over limit at ' num2str(it*simT)])
        Gtemp(:) = 0;
        Iopt = 0;
        Itemp = 0;
        noop = 1;
    end
    % ------------------------------------------------------------- Plant
    plant
    Vstring_prev = Vstring_temp + 3e-3*randn;
end
