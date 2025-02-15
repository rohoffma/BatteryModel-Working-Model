% function plotfcn(t_soln,y_soln,AN,CA,SEP,EL,SIM,CONS,P,N,FLAG)
function plotfcn(filename)
%% Load Results
load(filename)

%% Plot Flags
FLAG.COE       = 0; % Conservation of Energy Check %%%%%%%%%%%%%These plots need to be fixed
FLAG.COM       = 1; % Conservation of Mass Check
FLAG.COC       = 1; % Conservation of Charge Check

FLAG.TEMP      = 0; % Cell Temperature Profile %%%%%%%%%%%%%These plots need to be fixed

FLAG.C_Liion   = 1; % Mass/Species (Concentration Normalized): Li_ion
FLAG.X_Li_surf = 1; % Mass/Species (Mole Fraction): Li_surf (x-direction)
FLAG.X_Li_rad  = 0; % Mass/Species (Mole Fraction): Li (r-direction) (Any of the plots)
FLAG.s_dot     = 0; % Li_ion production rate

FLAG.phi_ed    = 1; % phi_ed
FLAG.phi_el    = 1; % phi_el
FLAG.del_phi   = 0; % Delta phi (phi_ed - phi_el)
FLAG.E_eq      = 0; % Equilibrium delta_phi based on surface concentration
FLAG.eta       = 0; % eta
FLAG.i_o       = 0; % exchange current density
FLAG.i_Far     = 0; % charge-transfer current density
FLAG.plotV_SEI = 0; % Voltage across the SEI

FLAG.cellVoltage         = 1; % Terminal voltage of the battery vs time
FLAG.voltage_vs_capacity = 0; % Terminal voltage of the battery vs capacity
FLAG.V_and_A             = 0;

% ---- Harmonic Perturbation ----
FLAG.V_and_A_EIS   = 1;
FLAG.X_Li_surf_EIS = 0;

% ---- State Space EIS ----
FLAG.SS_NYQUIST  = 1;
FLAG.SS_BODE     = 1; 

% ---- Known Profile Controller ----
FLAG.KPCONT_cellVoltage      = 1; % Terminal voltage of the battery vs time
FLAG.KPCONT_i_user           = 1; 
FLAG.KPCONT_V_and_A_norm_abs = 0;
FLAG.KPCONT_V_and_A_norm     = 1;


% ---- MOO Controller ----
FLAG.MOOCONT_cellVoltage = 1;

% ---- Manual Current Profile ----
FLAG.MAN_del_phi               = 1; % Delta phi vs time
FLAG.MAN_del_phi_overlap       = 1; % Delta phi for each region plotted ontop of each other
FLAG.MAN_current_profile       = 0; % Current Profile vs time
FLAG.MAN_full_current_profile  = 1; % Current Profile determined by refinement (include profile past the final time needed)
FLAG.MAN_current_profile_norm  = 1; % Normalized Current Profile wrt C-rate vs time
FLAG.MAN_voltage_profile       = 0; % Voltage Profile vs time
FLAG.MAN_volt_and_curr_profile = 1; % Voltage Profile and |C-rate| vs time
FLAG.MAN_refinement            = 1; % Refinement Rate vs number of iterations

%% Inputs
N_times = 6; % Number of times to plot

% if FLAG.X_Li_rad % Which CV to plot radial mole fraction
    CV_vec = [N.CV_Region_AN(1) , N.CV_Region_AN(end) , N.CV_Region_CA(1) , N.CV_Region_CA(end)];
%     CV_vec = [N.CV_Region_AN(3) , N.CV_Region_CA(3) ];
% end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---- Polarization ----
if SIM.SimMode == 1
    
    %% Make Desired Times for Plotting
    time_des = linspace(0, t_soln(end), N_times);
%     time_des = linspace(SIM.initial_offset, t_soln(end), N_times);
%     time_des = SIM.initial_offset:(t_soln(end)-SIM.initial_offset)/(N_times-1):t_soln(end);
%     time_des = 0:t_soln(end)/N_times:t_soln(end);
    for i = 1:length(time_des)
        [~,t_index(i)] = min(abs(time_des(i)-t_soln));
    end
    
    %% Conservation of Energy Check
    if FLAG.COE
%     figure
%     plot(t_soln,mass_error,'LineWidth',2)
%     title('Conservation of Mass Check')
%     xlabel('Time (s)')
%     ylabel('Error [kmol]')
    end
    
    %% Conservation of Mass Check
    if FLAG.COM
    figure
    plot(t_soln,mass_error,'LineWidth',2)
    title('Conservation of Mass Check')
    xlabel('Time (s)')
    ylabel('Error [kmol]')
    end
    
    %% Conservation of Charge Check
    if FLAG.COC
    figure
    plot(t_soln,CoC,'LineWidth',2)
    title('Conservation of Charge Check')
    xlabel('Time (s)')
    ylabel('Error [A m^{-2}]')
    end
    
    %% Temperature
    if FLAG.TEMP
    figure
    hold on
    for i = 1:length(time_des)
        plot(SIM.x_vec,TemperatureC(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southwest';
    title('Temperature')
    xlabel('X Position')
    ylabel('Temperature (C)')
    xlim([0,SIM.x_half_vec(end)])

    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';
    end
    
    %% Mass/Species (Concentration): Li_ion
    % Plot concentrations for desired times
    if FLAG.C_Liion
    figure
    hold on
    for i = 1:N_times
        plot(SIM.x_vec,C_Liion(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southwest';
    title('C_{Li^+}')
    xlabel('X Position')
    ylabel('C_{Li^+} (kmol)')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';
    end
    
    %% Mass/Species (Concentration): Li_surf
    % Plot surface concentrations for desired times
    if FLAG.X_Li_surf
    figure
    hold on
    for i = 1:N_times
        plot(SIM.x_vec, X_Li_surf(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southwest';
    title('x_{Li,surf}')
    xlabel('X Position')
    ylabel('x_{Li,surf} (-)')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';
    end
    
    %% Radial Concentration Plots:
    if FLAG.X_Li_rad
        for j = 1:length(CV_vec)
            figure
            hold on
            if CV_vec(j) <= N.CV_Region_AN(end)
                r_vec = AN.r_vec;
            else
                r_vec = CA.r_vec;
            end
            for i = 1:length(time_des)
                plot(r_vec,X_Li(:,CV_vec(j),t_index(i)),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
            end
            lgn = legend;
            lgn.Location = 'southwest';
            if CV_vec(j) == 1
                title('Radial x_{Li} vs Time (CC/AN)')
            elseif CV_vec(j) == N.CV_Region_AN(end)
                title('Radial x_{Li} vs Time (AN/SEP)')
            elseif CV_vec(j) == N.CV_Region_CA(1)
                title('Radial x_{Li} vs Time (SEP/CA)')
            elseif CV_vec(j) == N.CV_Region_CA(end)
                title('Radial x_{Li} vs Time (CA/CC)')
            else
                title(['Radial x_{Li} vs Time (CV: ', num2str(CV_vec(j)) ,')'])
            end
            xlabel('Radial Position')
            ylabel('x_{Li}')
        end
    end
    
    %% s_dot_Li^+
    if FLAG.s_dot
    figure
    hold on
    for i = 1:N_times
        plot(SIM.x_vec,s_dot(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'northeast';
    title('s dot Li^+')
    xlabel('X Position')
    ylabel('s dot Li^+ (kmol m^{-2} s^{-1})')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';
    end

    %% Charge Plots: phi_ed
    if FLAG.phi_ed
    figure
    hold on
    for i = 1:N_times
        plot(SIM.x_vec,phi_ed(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southeast';
    title('\phi_{ed}')
    xlabel('X Position')
    ylabel('\phi_{ed} (V)')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';
    end
    
    %% Charge Plots: phi_el
    if FLAG.phi_el
    figure
    hold on
    for i = 1:length(time_des)
        plot(SIM.x_vec,phi_el(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southwest';
    title('\phi_{el}')
    xlabel('X Position')
    ylabel('\phi_{el} (V)')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';
    end
        
    %% Charge Plots: Delta phi
    if FLAG.del_phi
    figure
    hold on
    for i = 1:N_times
        plot(SIM.x_vec,del_phi(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southeast';
    title('\Delta \phi')
    xlabel('X Position')
    ylabel('\Delta \phi (V)')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';
    end
    
    %% E^eq
    if FLAG.E_eq
    figure
    hold on
    for i = 1:N_times
        plot(SIM.x_vec,Eq(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southeast';
    title('E^{eq}')
    xlabel('X Position')
    ylabel('E^{eq} (V)')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';
    end
    
    %% Eta
    if FLAG.eta 
    figure
    hold on
    for i = 1:N_times
        plot(SIM.x_vec,eta(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southeast';
    title('\eta')
    xlabel('X Position')
    ylabel('\eta (V)')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';    
    end
    
    %% i_o
    if FLAG.i_o
    figure
    hold on
    for i = 1:N_times
        plot(SIM.x_vec,i_o(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southeast';
    title('i_o')
    xlabel('X Position')
    ylabel('i_o (A m^{-2})')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';     
    end
    
    %% i_Far
    if FLAG.i_Far
    figure
    hold on
    for i = 1:N_times
        plot(SIM.x_vec,i_Far(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southeast';
    title('i_{Far}')
    xlabel('X Position')
    ylabel('i_{Far} (A m^{-2})')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';     
    end    

    %% V_SEI
    if FLAG.plotV_SEI
    figure
    hold on
    for i = 1:N_times
        plot(SIM.x_vec,V_SEI(t_index(i),:),'-o','LineWidth',2,'DisplayName',['t = ' , num2str(t_soln(t_index(i))) , 's'])
    end
    lgn = legend;
    lgn.Location = 'southeast';
    title('V_{SEI}')
    xlabel('X Position')
    ylabel('V_{SEI} (V)')
    xlim([0,SIM.x_half_vec(end)])
    
    xl_AS = xline(SIM.x_half_vec(N.N_CV_AN+1),'-',{'Anode','Separator'},'HandleVisibility','off');
    xl_AS.LabelHorizontalAlignment = 'center';
    xl_SC = xline(SIM.x_half_vec(N.N_CV_AN+N.N_CV_SEP+1),'-',{'Separator','Cathode'},'HandleVisibility','off');
    xl_SC.LabelHorizontalAlignment = 'center';     
    end  
    
    %% Charge Plots: Cell Voltage
    if FLAG.cellVoltage
    figure
    plot(t_soln,cell_voltage,'LineWidth',2)
    title('Cell Voltage')
    xlabel('Time (s)')
    ylabel('Voltage (V)')
    xlim([0,t_soln(end)])
    end
    
    %% Cell Potential vs Capacity
    if FLAG.voltage_vs_capacity
    figure
    plot(Cap, cell_voltage,'-k','LineWidth',2);
    title('Cell Voltage vs Capacity')
    xlabel('Capacity (Ahr)')
    ylabel('Voltage (V)')
    if Cap(1)<Cap(end)
        xlim([Cap(1),Cap(end)]);
    else
        xlim([Cap(end),Cap(1)]);
    end
    end
    
    %% Cell Potential and Load Current vs Time
    if FLAG.V_and_A
    figure
    hold on
    yyaxis left
    plot(t_soln, cell_voltage,'LineWidth',2,'DisplayName','Voltage'); %,'-o'
    ylabel('Voltage (V)')
    yyaxis right
    plot(t_soln, i_user,'LineWidth',2,'DisplayName','Current'); %,'-o'
    ylabel('Current (A m^-2)')
    title('Cell Voltage and Load Current vs Time')
    xlabel('Time (s)')
    lgn = legend;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---- Harmonic Perturbation ----
elseif SIM.SimMode == 2
    %% Cell Potential and Load Current vs Time
    if FLAG.V_and_A_EIS
    figure
    hold on
    yyaxis left
    plot(t_soln, cell_voltage,'-o','LineWidth',2,'DisplayName','Voltage'); %,'-o'
    ylabel('Voltage (V)')
    yyaxis right
    plot(t_soln, i_user,'LineWidth',2,'DisplayName','Current'); %,'-o'
    ylabel('Current (A m^-2)')
    title('Cell Voltage and Load Current vs Time')
    xlabel('Time (s)')
    lgn = legend;
    end
    
    %% Surface Concentration of Multiple CV
    if FLAG.X_Li_surf_EIS
    figure
    hold on
    for j = 1:length(CV_vec)
        if CV_vec(j) == 1
            plot(t_soln, X_Li_surf(:,CV_vec(j)),'LineWidth',2,'DisplayName','CC/AN')
        elseif CV_vec(j) == N.CV_Region_AN(end)
            plot(t_soln, X_Li_surf(:,CV_vec(j)),'LineWidth',2,'DisplayName','AN/SEP')
        elseif CV_vec(j) == N.CV_Region_CA(1)
            plot(t_soln, X_Li_surf(:,CV_vec(j)),'LineWidth',2,'DisplayName','SEP/CA')
        elseif CV_vec(j) == N.CV_Region_CA(end)
            plot(t_soln, X_Li_surf(:,CV_vec(j)),'LineWidth',2,'DisplayName','CA/CC')
        else
            if sum(CV_vec(j) == N.CV_Region_AN)
                plot(t_soln, X_Li_surf(:,CV_vec(j)),'LineWidth',2,'DisplayName',['CV: ', num2str(CV_vec(j)) ', Anode' ])
            elseif sum(CV_vec(j) == N.CV_Region_CA)
                plot(t_soln, X_Li_surf(:,CV_vec(j)),'LineWidth',2,'DisplayName',['CV: ', num2str(CV_vec(j)) ', Cathode'])
            else
                disp('No surface in the separator region')
            end            
        end
    end
    lgn = legend;
    lgn.Location = 'east';
    title('X_{Li,surf}')
    xlabel('Time (s)')
    ylabel('X_{Li,surf} (-)')
    end
    
    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% ---- SS EIS ----
elseif SIM.SimMode == 3
    %% EIS
    if FLAG.SS_NYQUIST
    figure
    plot(Z_results(:,P.SS.Z_Re),-Z_results(:,P.SS.Z_Im),'-ok','Linewidth',2)
    title('EIS')
    xlabel('Z_{Re} (Ohm)')
    ylabel('-Z_{Im} (Ohm)')
%     xlim([5,20])
%     ylim([0,12])    
    axis equal    
    end   
    
    %% Bode
    if FLAG.SS_BODE
    figure
    title('Bode')

    subplot(2,1,1)
    semilogx(Z_results(:,P.SS.omega) , Z_results(:,P.SS.Z_dB) , '-ok' , 'LineWidth' , 2)
    ylabel('Magnitude (dB)')

    subplot(2,1,2)
    semilogx(Z_results(:,P.SS.omega) , Z_results(:,P.SS.Z_ps_deg) , '-ok' , 'LineWidth' , 2)
    ylabel('Phase (degrees)')
    xlabel('Frequency (rad s^{-1})')   
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---- Known BC Profile Controller ----
elseif SIM.SimMode == 4
    %% Cell Voltage
    if FLAG.KPCONT_cellVoltage
    figure
    plot(t_soln,cell_voltage,'LineWidth',2)
    title('Cell Voltage')
    xlabel('Time (s)')
    ylabel('Voltage (V)')
    xlim([0,t_soln(end)])
    end
    
    %% Current Plot
    if FLAG.KPCONT_i_user
    figure
    plot(t_soln,i_user,'LineWidth',2)
    title('i_{user}')
    xlabel('Time (s)')
    ylabel('Load Current (A m^{-2})')
    xlim([0,t_soln(end)])
    end
    
    %% Voltage and Normalized C-rate Absolute Value
    if FLAG.KPCONT_V_and_A_norm_abs
    figure
    title('Voltage and |C-rate|')
    xlabel('Time (s)')

    yyaxis left
    plot(t_soln , cell_voltage , 'Linewidth' , 2 )
    ylabel('Cell Voltage (V)')

    yyaxis right
    plot(t_soln , abs(I_user_norm_Crate), 'Linewidth' , 2 )
    ylabel('Absolute Value of C-rate')
    end
    
    %% Voltage and Normalized wrt 1C-rate
    if FLAG.KPCONT_V_and_A_norm
    figure
    title('Voltage and C-rate')
    xlabel('Time (s)')

    yyaxis left
    plot(t_soln , cell_voltage , 'Linewidth' , 2 )
    ylabel('Cell Voltage (V)')

    yyaxis right
    plot(t_soln , I_user_norm_Crate, 'Linewidth' , 2 )
    ylabel('C-rate')
    end
    
    %% SOC vs Cell Voltage (Think I need a SOC calc in postProcessing which requires saving i_user)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---- MOO Controller ----
elseif SIM.SimMode == 5
    %% Cell Voltage
    if FLAG.CONT_cellVoltage
    figure
    plot(t_soln,cell_voltage,'LineWidth',2)
    title('Cell Voltage')
    xlabel('Time (s)')
    ylabel('Voltage (V)')
    xlim([0,t_soln(end)])
    end
    
    %% Current Plot
    
    %% SOC vs Cell Voltage (Think I need a SOC calc in postProcessing which requires saving i_user)   
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% ---- Manual Current Profile ----
elseif SIM.SimMode == 7 
    idx = find(t_soln > SIM.ramp_time/2,1); % Don't plot the first ramp
    %% Delta Phi
    if FLAG.MAN_del_phi
        figure
        plot(t_soln , del_phi(:,N.N_CV_AN), 'Linewidth' , 2)
        yline(0)
        title('\Delta \phi')
        xlabel('Time (s)')
        ylabel('Voltage (V)')
    end
    
    %% Overlaping delta phi
    if FLAG.MAN_del_phi_overlap
        % Determine region for each time value
            time_step_regions = zeros(length(t_soln),1);
            region = 1;
            for i = 1:length(t_soln)
                if t_soln(i) < SIM.region_time_vec(region+1)
                    time_step_regions(i) = region;
                else
                    region = region + 1;
                    time_step_regions(i) = region;
                end
            end
        
        % Max of each region
            max_vec = zeros(1,SIM.N_regions);
            for r = 1:SIM.N_regions
                idx1 = find(time_step_regions == r);
                max_vec(r) = length(idx1);
            end
            max_of_regions = max(max_vec);
            
        % Organize Data into matrices
            raw_time = nan(SIM.N_regions,max_of_regions);
            raw_del_phi = nan(SIM.N_regions,max_of_regions);
            for r = 1:SIM.N_regions
                idx1 = find(time_step_regions == r);
                raw_time(r,1:length(idx1))    = (t_soln(idx1))';
                raw_del_phi(r,1:length(idx1)) = (del_phi(idx1,N.N_CV_AN))';
            end
            
        % Normalize Time of each region
            norm_time = nan(size(raw_time));
            del_time = SIM.region_time_vec(2) - SIM.region_time_vec(1);
            for r = 1:SIM.N_regions
                norm_time(r,:) = (raw_time(r,:) - SIM.region_time_vec(r))/del_time;
            end
        
        % Make Color Matrix
            region_vec = 1:1:max(time_step_regions);
            b = [0 0 1]; % Blue
            r = [1 0 0]; % Red
            xOk = [min(region_vec);max(region_vec)];
            myColors = interp1(xOk,[b;r],region_vec);
            
        % Plot
            figure
            hold on
            for r = 1:max(time_step_regions)
                plot(norm_time(r,:),raw_del_phi(r,:), 'Linewidth' , 2 , 'Color' , myColors(r,:))
            end
            title('Overlapping \Delta \phi')
            xlabel('Normalized Time')
            ylabel('\Delta \phi (V)')           

    end
    
    %% Current Profile
    if FLAG.MAN_current_profile
        figure
        plot(t_soln(idx:end) , I_user(idx:end), 'Linewidth' , 2)
        title('Current Profile')
        xlabel('Time (s)')
        ylabel('Current (A)')
    end
    
    %% Full Current Profile from Refinement
    if FLAG.MAN_full_current_profile
        time_vec    = 0:1:SIM.tspan(2);
        current_vec = interp1(SIM.profile_time , SIM.profile_current , time_vec);
        
        figure
        plot(time_vec , current_vec, 'Linewidth' , 2)
        title('Full Refined Current Profile')
        xlabel('Time (s)')
        ylabel('Current (A m^{-2})')
    end
    
    %% Current Profile Normalized
    if FLAG.MAN_current_profile_norm
        figure
        plot(t_soln(idx:end) , I_user_norm_Crate(idx:end), 'Linewidth' , 2 )
        if I_user_norm_Crate(idx(end)) < 0
            yline(-1)
        else 
            yline(1)
        end
        title('Normalized Current Profile')
        xlabel('Time (s)')
        ylabel('C-rate')
    end
    
    %% Voltage Profile
    if FLAG.MAN_voltage_profile
        figure
        plot(t_soln , cell_voltage , 'Linewidth' , 2 )
        title('Voltage Profile')
        xlabel('Time (s)')
        ylabel('Voltage (V)')
    end
    
    %% Voltage and Current Profile
    if FLAG.MAN_volt_and_curr_profile
        figure
        title('Voltage and |C-rate|')
        xlabel('Time (s)')
        
        yyaxis left
        plot(t_soln , cell_voltage , 'Linewidth' , 2 )
        ylabel('Cell Voltage (V)')
                    
        yyaxis right
        plot(t_soln(idx:end) , abs(I_user_norm_Crate(idx:end)), 'Linewidth' , 2 )
        ylabel('Absolute Value of C-rate')
        
        % Add text for equivalent CC C-rate
            equ_C_rate = 3600/t_soln(end);
            time_str = sprintf( '%.2f' , equ_C_rate );
            text(t_soln(end)/3, (max(abs(I_user_norm_Crate(idx:end)))-min(abs(I_user_norm_Crate(idx:end))))/2,['Equivalent to ' time_str 'C CC cycle'],'Color','blue','FontSize',14)
    end
    
    %% Refinement
    if FLAG.MAN_refinement
        figure
        plot(1:length(SIM.sum_of_refinement_vec),SIM.sum_of_refinement_vec/SIM.N_regions)
        % Adding time to plot
            time_str = sprintf( '%.2f' , (SIM.tSimEnd)/3600 );
            text(length(SIM.sum_of_refinement_vec)/2, (max(SIM.sum_of_refinement_vec/SIM.N_regions) - min(SIM.sum_of_refinement_vec/SIM.N_regions))/2 + min(SIM.sum_of_refinement_vec/SIM.N_regions),['Took ' time_str ' hours to complete'],'Color','blue','FontSize',14)
        title('Refinement Convergance')
        xlabel('Iterations')
        ylabel('Normal of Steps')
    end
    
end % if SIM.SimMode statement


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Arrange Figures
FigArrange = 1;
fig = gcf;
NumFig = fig.Number;
if FigArrange == 1
    Ncol = 3;
    
    for i = 1:NumFig
        f = figure(i);
        k = mod(i-1,Ncol);
        row = mod(fix((i-1)/Ncol),2);
        if row == 0
            r = 575;
%             r = 540;
        elseif row == 1
            r = 62;
        end
        f.Position = [k*575+15 r 560 420];
    end
end

end