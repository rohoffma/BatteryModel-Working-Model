%% Function to calculate current flux 
% The ith index is the flux at the left (minus) face of the ith control volume
function [i_ed , i_el ] = currentCalc( SV , AN , SEP , CA , EL , P , N , CONS , FLAG , i_user , props)
%% Initialize
zeros_vec   = NaN(1 , N.N_CV_tot+1);
i_el        = zeros_vec;
i_ed        = zeros_vec;

%% Calc
% ---- Anode ----
    % CC/AN Boundary Condition
        i = N.CV_Region_AN(1);
        i_ed(i) = i_user; % Electronic flux through the current collector
        i_el(i) = 0;      % No ionic   flux through the current collector

    % AN Region
        if ~FLAG.AN_LI_FOIL
            for i = N.CV_Region_AN(2:end)
                i_ed(i) = -  AN.sigma*(SV(P.phi_ed,i)- SV(P.phi_ed,i-1))/ AN.del_x;
                i_el(i) = -  EL.kappa*(SV(P.phi_el,i)- SV(P.phi_el,i-1))/(AN.del_x) ...
                          -2*EL.kappa*(CONS.R*SV(P.T,i)/CONS.F)*(1 + EL.Activity )*(EL.tf_num-1)*(log(SV(P.C_Liion,i))-log(SV(P.C_Liion,i-1)))/(AN.del_x);
            end
        end

% ---- Separator ----
    % AN/SEP interface
        i = N.CV_Region_SEP(1);
        i_el(i) = -   EL.kappa*(SV(P.phi_el,i)-SV(P.phi_el,i-1))/(AN.del_x/2 + SEP.del_x/2) ...
                  - 2*EL.kappa*(CONS.R*SV(P.T,i)/CONS.F)*(1 + EL.Activity)*(EL.tf_num-1)*(log(SV(P.C_Liion,i))-log(SV(P.C_Liion,i-1)))/(AN.del_x/2 + SEP.del_x/2);
        i_ed(i) = 0; 
%         if FLAG.AN_LI_FOIL%%%%%%%%%%%%%%%%%
%             i_el(i) = i_user;
%         end
        
    % SEP Region
        for i = N.CV_Region_SEP(2:end)
            i_el(i) = -   EL.kappa*(SV(P.phi_el,i)-SV(P.phi_el,i-1))/(SEP.del_x) ...
                      - 2*EL.kappa*(CONS.R*SV(P.T,i)/CONS.F)*(1 + EL.Activity )*(EL.tf_num-1)*(log(SV(P.C_Liion,i))-log(SV(P.C_Liion,i-1)))/(SEP.del_x);
        end
 
% ---- Cathode ----
    % SEP/CA interface
        i = N.CV_Region_CA(1);
        i_el(i) = -   EL.kappa*(SV(P.phi_el,i)-SV(P.phi_el,i-1))/(SEP.del_x/2 + CA.del_x/2) ...
                  - 2*EL.kappa*(CONS.R*SV(P.T,i)/CONS.F)*(1 + EL.Activity)*(EL.tf_num-1)*(log(SV(P.C_Liion,i))-log(SV(P.C_Liion,i-1)))/(CA.del_x/2 + SEP.del_x/2);
        i_ed(i) = 0;      
    % CA region
        if ~FLAG.CA_LI_FOIL
            for i = N.CV_Region_CA(2:end)
                i_ed(i) = -   CA.sigma*(SV(P.phi_ed,i)- SV(P.phi_ed,i-1))/ CA.del_x;
                i_el(i) = -   EL.kappa*(SV(P.phi_el,i)- SV(P.phi_el,i-1))/(CA.del_x) ...
                          - 2*EL.kappa*(CONS.R*SV(P.T,i)/CONS.F)*(1 + EL.Activity)*(EL.tf_num-1)*(log(SV(P.C_Liion,i))-log(SV(P.C_Liion,i-1)))/(CA.del_x); 
            end
        end

% Boundary Condition at the CA/CC
i = N.N_CV_tot + 1;
i_ed(i) = i_user; % Electronic flux through current collector
i_el(i) = 0;      % No ionic   flux through current collector

end