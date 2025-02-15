%% Event Function
% This function will be used to determine if an event occurs that one would
% like to know.
% 
% List of events
% * Cell voltage reaches a maximum
% * Cell voltage reaches a minimum
% * A particle has no lithium left %%%%%%%%%%%%%%%%%%Not implemented
% * A particle is completely full of lithium %%%%%%%%%%%%%%%%%%Not implemented

function [value,isterminal,direction] = batt_events(t,SV,SIM,P,N,FLAG)
SV = SV1Dto2D(SV , N , P , FLAG);
CellVoltage = SV(P.phi_ed,end) - SV(P.phi_ed,1);

if SIM.SimMode == 4 % Known BC Profile
    MO = SIM.Controller_MO_File(SIM.current_MO_step).MO;
    if MO == 1 % CC
        if SIM.Controller_MO_File(SIM.current_MO_step).CorD == 'C'
            VoltageMax = SIM.Controller_MO_File(SIM.current_MO_step).Volt_lim;
            VoltageMin = SIM.VoltageMin;
        else
            VoltageMax = SIM.VoltageMax;
            VoltageMin = SIM.Controller_MO_File(SIM.current_MO_step).Volt_lim;
        end
    else
        VoltageMax = SIM.VoltageMax;
        VoltageMin = SIM.VoltageMin;
    end
else
    VoltageMax = SIM.VoltageMax;
    VoltageMin = SIM.VoltageMin;
end
       


value = [ VoltageMax  - CellVoltage; % If cell goes above max voltage
          CellVoltage - VoltageMin]; % If cell goes below min voltage

isterminal = [ 1;  % If cell goes above max voltage
               1]; % If cell goes below min voltage
           
direction = [-1;  % If cell goes above max voltage
             -1]; % If cell goes below min voltage

end % batt_events