% --------------------------------------------------------- Event handling
if strcmp(mode,'idle') && mean(SoCest_temp(:)) <  70
    disp(['EV charging finished with EV SoC ' num2str(SoC_EVtemp)])
    disp('Charging ------------------------------------')
    mode = 'charging';
    noop = 0;
    Gtemp(:) = 0;
    SoC_EVref = NaN;
    SoC_EV = NaN;
    Itemp = 0;
    Iopt = 0;
    uncertainty_factor = 1;
    CCCV = 0;
end
if ((SoC_EVtemp > min(98,SoC_EVref) ||...
         mean(SoCest_temp(:)) <  5) && strcmp(mode,'discharging') || ...
        (mean(SoCest_temp(:)) > 95) && strcmp(mode,'charging')) ...
        || noop
    disp('Idle operation ----------------------------------')
    noop = 0;
    Gtemp(:) = 0;
    SoC_EVref = NaN;
    mode = 'idle';
    SoC_EV = NaN;
    V_EVtemp = NaN;
    Vref = 0;
    Itemp = 0;
    Iopt = 0;
    uncertainty_factor = 1;
    CCCV = 0;
end
if mean(SoCest_temp(:)) > 70 && EV_turnup(it) && strcmp(mode,'idle')
    disp('Discharging: CC ----------------------------------')
    noop = 0;
    CCCV = 0;
    mode = 'discharging';
    SoC_EVtemp = SoC_EVturnup(it);
    SoC_EVref = SoCref_EVturnup(it);
    V1_EVtemp = 0;
    V2_EVtemp = 0;
    OCV_EVtemp = interp1(soc_EV,ocv_EV,SoC_EVtemp,'linear','extrap');
    V_EVtemp = OCV_EVtemp;
    Q_EV = Q_EVturnup(it);
    Itemp = 0;
    Iopt = 0;
    uncertainty_factor = 1;
end