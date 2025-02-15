%% Post-Processing Function
% Take all the data and convert into easy to read vectors
function postProcessing(filename)
%% Load file to workspace
load(filename)

%% do post-processing if it hasn't already
if ~exist('postProcessComplete') %~= 1
    %% Make Desired Times Vector
    if FLAG.ReduceSolnTime
        % I want the index of all times before 1 second, every 10 seconds after 1 second up until 500 sec before t_soln(end), All indicies of the last 500 seconds
        FirstTime   = 1;
        TimeFromEnd = 500;
        TimeDelta   = 10;

        t_mid_final = t_soln(end) - TimeFromEnd; % last time of the middle region
        t_vec_mid_des = FirstTime+TimeDelta : TimeDelta : t_mid_final;

        % Find Index for 1 sec
        [~,k_1] = min(abs(t_soln-FirstTime));

        % Find Mid indicies
        k_mid = zeros(1,length(t_vec_mid_des)); % indicies of the desired middle region
        for i = 1:length(t_vec_mid_des)
            [~,k_mid(i)] = min(abs(t_soln-t_vec_mid_des(i)));
        end

        % Assemble Index Vector
        idx = [ (1:1:k_1) , k_mid , (k_mid(end)+1:1:length(t_soln)) ];
        N_t_steps = length(idx);

        t_soln_OG = t_soln;
        t_soln = t_soln(idx);
    else
        N_t_steps = length(t_soln);
        idx = 1:1:N_t_steps;
    end
    %% Initialize variables
    max_SV = max( N.N_SV_AN , N.N_SV_CA );

    SV          = zeros(max_SV , N.N_CV_tot, N_t_steps );
    
    TemperatureK = zeros( N_t_steps , N.N_CV_tot );
    
    C_Liion      = zeros( N_t_steps , N.N_CV_tot );
    C_Li_surf    = zeros( N_t_steps , N.N_CV_tot );
    X_Li_surf    = zeros( N_t_steps , N.N_CV_tot );
    C_Li         = NaN( N.N_R_max , N.N_CV_tot, N_t_steps );
    
    phi_el       = zeros( N_t_steps , N.N_CV_tot );
    phi_ed       = zeros( N_t_steps , N.N_CV_tot );
    V_SEI        = zeros( N_t_steps , N.N_CV_tot );
    del_phi      = zeros( N_t_steps , N.N_CV_tot );
    eta          = zeros( N_t_steps , N.N_CV_tot );
    i_Far        = zeros( N_t_steps , N.N_CV_tot );
    i_o          = zeros( N_t_steps , N.N_CV_tot );
    Eq           = zeros( N_t_steps , N.N_CV_tot );
    
    i_el         = zeros( N_t_steps , N.N_CV_tot + 1);
    i_ed         = zeros( N_t_steps , N.N_CV_tot + 1);
    Cap          = zeros( N_t_steps , 1 );
    %     J_Liion     = zeros( N_t_steps , N.N_CV_tot + 1);
    % J_Li
    % props
    
    total_mass   = zeros( N_t_steps , 1 );
    CoC          = zeros( N_t_steps , N.N_CV_tot );
    %% Perform calcs and save results to their variable name
    if SIM.SimMode == 4
        i_user = i_user_soln;
        i_user = i_user(idx);
    elseif SIM.SimMode == 5
        % Pull i_user from RunSimulation loop and make into a vector the
        % same size as t_soln
    else
        i_user = (i_user_calc(t_soln,SIM))';
    end
    
    for i = 1:N_t_steps
        % Go through the solution vector and reshape every SV to 2D (3D matrix)
        SV( : , : , i )    = SV1Dto2D( SV_soln( idx(i) , : ) , N , P , FLAG );
        
        TemperatureK( i , : ) = SV( P.T , : , i );
        
        C_Liion( i , : )                = SV( P.C_Liion              , :              , i );
        C_Li( : , : , i )               = SV( P.C_Li:P.C_Li_surf_max , :              , i );
        C_Li_surf( i , N.CV_Region_AN ) = SV( P.C_Li_surf_AN         , N.CV_Region_AN , i ); 
        C_Li_surf( i , N.CV_Region_CA ) = SV( P.C_Li_surf_CA         , N.CV_Region_CA , i ); 
        
        phi_ed( i , : ) = SV( P.phi_ed , : , i );
        phi_el( i , : ) = SV( P.phi_el , : , i );
        
        eta_AN       = SV(P.V_2 , N.CV_Region_AN ,i) - SV(P.V_1 , N.CV_Region_AN ,i);
        eta_CA       = SV(P.V_2 , N.CV_Region_CA ,i) - SV(P.V_1 , N.CV_Region_CA ,i);
        eta( i , : ) = [eta_AN  , NaN(1,N.N_CV_SEP) ,eta_CA  ];
        
        V_SEI(   i , : ) = SV( P.V_1    , : , i) - SV( P.phi_el , : , i);
        del_phi( i , : ) = SV( P.phi_ed , : , i) - SV( P.phi_el , : , i);
    end
    
    % Temperature
    TemperatureC = TemperatureK - 273.15;
    
    % Mole Fraction Calcs
    X_Liion = C_Liion / EL.C; % Normalized with respect to the initial concentration
    X_Li    = C_Li;
    X_Li( : , N.CV_Region_AN , : ) = X_Li( : , N.CV_Region_AN , : ) / AN.C_Li_max;
    X_Li( : , N.CV_Region_CA , : ) = X_Li( : , N.CV_Region_CA , : ) / CA.C_Li_max;
    for i = 1:N_t_steps
        X_Li_surf( i , N.CV_Region_AN ) = X_Li( N.N_R_AN , N.CV_Region_AN , i );
        X_Li_surf( i , N.CV_Region_CA ) = X_Li( N.N_R_CA , N.CV_Region_CA , i );
    end
    
    % Electrostatic Related Calcs
    for i = 1:N_t_steps
        if FLAG.VARIABLE_PROPS_FROM_HANDLES
            props = getProps( SV( : , : , i ) , AN , SEP, CA , EL , P , N , CONS , FLAG , PROPS);
        else
            props = PROPS;
        end
        
        % Equilibrium
        Eq_an = AN.EqPotentialHandle( X_Li_surf( i , N.CV_Region_AN ));
        Eq_ca = CA.EqPotentialHandle( X_Li_surf( i , N.CV_Region_CA ));
        Eq (i , : ) = [ Eq_an , NaN(1,N.N_CV_SEP) , Eq_ca ];
                
        % i_o
        if FLAG.Newman_i_o
            i_o_an = CONS.F * AN.k_o ...
                               * SV(P.C_Liion     ,N.CV_Region_AN , i)  .^AN.alpha_a ...
              .* ( AN.C_Li_max - SV(P.C_Li_surf_AN,N.CV_Region_AN , i) ).^AN.alpha_a ...
                              .* SV(P.C_Li_surf_AN,N.CV_Region_AN , i)  .^AN.alpha_c;
            i_o_ca = CONS.F * CA.k_o ...
                               * SV(P.C_Liion     ,N.CV_Region_CA , i)  .^CA.alpha_a ...
              .* ( CA.C_Li_max - SV(P.C_Li_surf_CA,N.CV_Region_CA , i) ).^CA.alpha_a ...
                              .* SV(P.C_Li_surf_CA,N.CV_Region_CA , i)  .^CA.alpha_c;
        else
            i_o_an  = AN.i_oHandle( SV(:,N.CV_Region_AN , i) , P, AN );
            i_o_ca  = CA.i_oHandle( SV(:,N.CV_Region_CA , i) , P, CA );
        end
        i_o(i , :) = [i_o_an, NaN(1,N.N_CV_SEP), i_o_ca];
        
        % i_Far
        i_Far(i , :) = iFarCalc( SV(: , : , i) , AN , CA , P , N , CONS , FLAG , props);
        
        % i_el, i_ed
        [i_ed(i , :) , i_el(i , :) ] = currentCalc( SV(: , : , i) , AN , SEP , CA , EL , P , N , CONS , FLAG , i_user(i,1) , props);
        
    end
    % Cell Voltage
    cell_voltage = phi_ed(:,end) - phi_ed(:,1);
    
    % Cell Capacity
    Cap = -SIM.A_c/3600 * cumtrapz( t_soln , i_user );
    
%     if SIM.SimMode == 4 %%%%%%%%%%%!!!!!!!!!!!Why is Mode 4 special? Can trap be called with a vector and not a fnc?
%         for i = 1:length(t_soln)
%             if i == 1
%                 Cap(i,1) = 0;
%             else
%                 Cap(i,1) = SIM.A_c * trapz( i_user(1:i) , t_soln(1:i) );
%             end
%         end
%     elseif SIM.SimMode == 5
%         
%     else
%         for i = 1:length(t_soln)
%             Cap(i,1) = SIM.A_c * integral( @(t)i_user_calc(t,SIM) , 0 , t_soln(i) );
%         end
%     end
% Cap = Cap/3600; % Put into Ahr    
        
    % SOC
    SOC = Cap/SIM.Cell_Cap + SIM.SOC_start;

    % Current Vectors
    I_user = i_user * SIM.A_c;
    I_user_norm_Crate = I_user / SIM.Cell_Cap;

    % s_dot
    s_dot = i_Far / CONS.F ;

    % Conservation of Charge Check
    % Divergence of the sum of current flux should equal 0
    for i = 1:N_t_steps
        for j = 1:N.N_CV_tot
            CoC(i , j) = (i_el(i,j+1) + i_ed(i,j+1)) - (i_el(i,j) + i_ed(i,j));
        end
    end

    %% Calculate mass at each time step
    % Volume Vector
    Vol_el = [ AN.dVol_el*ones(1 , N.N_CV_AN) , SEP.dVol_el*ones(1 , N.N_CV_SEP) , CA.dVol_el*ones(1 , N.N_CV_CA)];
    Vol_ed = NaN(N.N_R_max , N.N_CV_tot);
       
    for i = N.CV_Region_AN
        Vol_ed(1:N.N_R_AN,i) = AN.dVol_r * AN.Np_CV;
    end
    for i = N.CV_Region_CA
        Vol_ed(1:N.N_R_CA,i) = CA.dVol_r * CA.Np_CV;
    end
    Vol_vec = [Vol_el ; Vol_ed];
    
    % Mass in each CV
    mass = zeros(N.N_R_max+1 , N.N_CV_tot, N_t_steps ); %%%% The plus 1 is to include C_Liion
    for i = 1:N_t_steps
        mass(:,:,i) = Vol_vec .* SV(P.C_Liion:P.C_Li_surf_max,:,i);
        % Sum of masses
        total_mass(i,1) = sum(mass(:,:,i),'all','omitnan');
    end
    mass_error = total_mass(:) - total_mass(1);
    
    %% Calculations specific to sinusoidal pertebations
    if SIM.SimMode == 2
        %% ID Voltage Section
        Y = fft(cell_voltage(1:end-1));
        L = length(cell_voltage(1:end-1));
        P2 = abs(Y/L); % 2-sided spectrum (neg and pos frequencies)
        P1 = P2(1:L/2+1); % single-sided spectrum
        P1(2:end-1) = 2*P1(2:end-1); % Multiply everything by 2 execpt the DC (0 Hz)
        phase = angle(Y);
        
%         V_off_fft = P1(1);
%         freq_ID_fft = f(I+1);
        [Amp_ID , I] = max(P1(2:end));
        ps = phase(I+1);
        ps = ps + pi/2 - pi; % Adds pi/2 because fft identifies cos, Subtract pi because voltage decreases when current increases
        
        %% Impedance Calculation
        Z_mag = Amp_ID / SIM.I_user_amp; % Impedance Magnitude
        Z_Re = Z_mag * cos(ps); % Real Impedance Component
        Z_Im = Z_mag * sin(ps); % Imaginary Impedance Component
        Z_dB = 20*log10(Z_mag); % Impedance Magnitude in decibel
        Z_angle_deg = ps * 360 / (2*pi); % Phase Shift in degrees
        
        if Z_angle_deg <= -358
            Z_angle_deg = Z_angle_deg + 360; % Angle wrapping
        end
    elseif SIM.SimMode == 7
        if FLAG.Optimize_Profile && FLAG.Save_Current_Profile
            profile_save_filepath   = [filename(1:end-4), '_CurrentProfile_Output.mat'];
            
            region_time_vec    = SIM.region_time_vec;
            region_current_vec = SIM.region_current_vec;
            profile_time       = SIM.profile_time;
            profile_current    = SIM.profile_current;
            t_final            = region_time_vec(end);
            
            SIM.SimMode = 0;
            
            save(profile_save_filepath,'region_time_vec','region_current_vec','profile_time','profile_current','t_final','profile_save_filepath','SIM')
        end
        SIM.SimMode = 7;
    end
    
    %% Set the variable for finished post-processing
    postProcessComplete = 1;
    
    %% Resave data to the .mat file
    clearvars i 
    save(filename);
end
end
