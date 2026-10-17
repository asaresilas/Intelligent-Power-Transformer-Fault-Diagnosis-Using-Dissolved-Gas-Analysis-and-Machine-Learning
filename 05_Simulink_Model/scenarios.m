function S = scenarios()
%SCENARIOS  The three operating scenarios of Roadmap Step 36 (decision D34).
%
%   S = scenarios()   returns a 1x3 struct array with the fields
%       id          short name used in file names (rated, daily, overload)
%       label       text for figures
%       t_stop_s    simulation stop time [s]
%       show_from_s start of the 24 h window that is shown and summarised [s]
%       profile     timeseries: demand load factor [pu] against time [s] (becomes load_profile of the model)
%
%   The scenarios are ILLUSTRATIVE operating contexts chosen for this project: they are not measured load data and have no
%   external source (decision D34). Every number is a named variable below, with its unit. The model, params_transformer.m
%   (ambient temperature, thermal constants) and this file together define each run completely.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 36.   MATLAB R2025b.

h = 3600;                                           % [s] one hour

%% S1 constant rated load
K_rated_demand   = 1.0;                             % [pu] demand load factor (rated load)
T_rated_h        = 24;                              % [h]  duration

%% S2 daily load cycle (same cycle on three days; the last day is shown)
t_day_h  = [0  6   8   12  17  18  21  23  24];     % [h]  breakpoints within one day
K_day_pu = [0.5 0.5 0.9 0.8 0.9 1.0 1.0 0.5 0.5];   % [pu] demand at the breakpoints (night 0.5, day 0.8-0.9, evening peak 1.0)
n_days   = 3;                                       % [-]  number of repeated days (first days settle the temperatures)

%% S3 short overload
K_base_pu     = 0.8;                                % [pu] base demand
K_over_pu     = 1.3;                                % [pu] overload demand
t_over_start_h = 8;                                 % [h]  start of the overload
d_over_h      = 2;                                  % [h]  duration of the overload
T_over_h      = 24;                                 % [h]  duration of the run
t_ramp_s      = 1;                                  % [s]  ramp time of the load steps (as in the Step 35 load step)

%% build the profiles
S = struct('id', {}, 'label', {}, 't_stop_s', {}, 'show_from_s', {}, 'profile', {});

S(1).id = 'rated';  S(1).label = 'Constant rated load';
S(1).t_stop_s = T_rated_h * h;  S(1).show_from_s = 0;
S(1).profile = timeseries([K_rated_demand; K_rated_demand], [0; T_rated_h * h]);

t = [];  K = [];
for d = 0:n_days - 1
    t = [t; (d * 24 + t_day_h(:)) * h];             %#ok<AGROW>
    K = [K; K_day_pu(:)];                           %#ok<AGROW>
end
keep = [true; diff(t) > 0];                         % the day boundary appears twice (24 h = 0 h of the next day)
S(2).id = 'daily';  S(2).label = 'Daily load cycle';
S(2).t_stop_s = n_days * 24 * h;  S(2).show_from_s = (n_days - 1) * 24 * h;
S(2).profile = timeseries(K(keep), t(keep));

t0 = t_over_start_h * h;  t1 = t0 + d_over_h * h;
S(3).id = 'overload';  S(3).label = 'Short overload';
S(3).t_stop_s = T_over_h * h;  S(3).show_from_s = 0;
S(3).profile = timeseries([K_base_pu; K_base_pu; K_over_pu; K_over_pu; K_base_pu; K_base_pu], ...
    [0; t0; t0 + t_ramp_s; t1; t1 + t_ramp_s; T_over_h * h]);
end
