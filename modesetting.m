% ----------------------------------------------------------- Mode setting
voltage_sensor_std = 3e-3;
switch mode
    case 'charging'
        Iref = Iref_inv;
        V_extmeas = OCV_inv + Itemp*R_inv + voltage_sensor_std*randn;
        Vref = max(Vmin_inv,V_extmeas);
    case 'discharging'
        Iref = Iref_EV;
        V_EVmeas = V_EVtemp + voltage_sensor_std*randn;
        if ~CCCV && V_EVmeas*1.05 > Vmax_EV
            disp(['Discharging: CV at time ' num2str(it*simT)])
            CCCV = 1;
        end
        if ~CCCV
            Vref = min(Vmax_EV,V_EVmeas);
        else
            curv = 0.005;
            Vref = min(Vmax_EV,Vref*(1-curv/deltaT)+Vmax_EV*curv/deltaT);
        end
        V_extmeas = V_EVmeas;
end