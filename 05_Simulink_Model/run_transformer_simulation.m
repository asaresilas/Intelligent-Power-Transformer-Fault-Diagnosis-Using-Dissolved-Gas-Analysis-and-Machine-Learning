function res = run_transformer_simulation(load_profile_in, opts)
%RUN_TRANSFORMER_SIMULATION Simulate the transformer operating model.
%   res = run_transformer_simulation()            uses load_profile from params_transformer.m
%   res = run_transformer_simulation(profile_ts)  uses the given timeseries (time s, K pu)
%   res = run_transformer_simulation(profile_ts, opts)  17 Oct 2026 (dashboard scenarios): opts.t_stop_s = stop time [s],
%       opts.t_sample_s = sampling times [s] (increasing, inside the run). Both are optional fields; they are passed to the
%       model as run-specific values (StopTime, t_sample_s) and change nothing in the saved model or in params_transformer.m.
%   Output struct res: t_h, K_pu, theta_oil_C, theta_hs_C, ageing_V, loss_of_life_h
%   Step 40 (D38): res.events = table of the sampling events of SS8 (time_h, record_index, record_id) from get_sampling_events;
%   an empty table if the held-out list heldout_record_ids is not in the base workspace. The model itself never holds a gas value.
mdl = 'Transformer_Operating_Model';
load_system(mdl);
in = Simulink.SimulationInput(mdl);
if nargin >= 1 && ~isempty(load_profile_in)
    in = in.setVariable('load_profile', load_profile_in);
end
if nargin >= 2 && isstruct(opts)
    if isfield(opts, 't_stop_s'),   in = in.setModelParameter('StopTime', num2str(opts.t_stop_s)); end
    if isfield(opts, 't_sample_s'), in = in.setVariable('t_sample_s', opts.t_sample_s(:)'); end
end
out = sim(in);
res.t_h         = out.theta_oil_C.Time / 3600;
res.K_pu        = squeeze(out.K_pu.Data);
res.theta_oil_C = squeeze(out.theta_oil_C.Data);
res.theta_hs_C  = squeeze(out.theta_hs_C.Data);
res.ageing_V    = squeeze(out.ageing_rate_V.Data);
% Equivalent ageing in hours = integral of V over time (trapezoidal rule)
res.loss_of_life_h = trapz(out.ageing_rate_V.Time, res.ageing_V) / 3600;
if evalin('base', 'exist(''heldout_record_ids'', ''var'')')
    res.events = get_sampling_events(out);
else
    res.events = table('Size', [0 3], 'VariableTypes', {'double', 'double', 'string'}, 'VariableNames', {'time_h', 'record_index', 'record_id'});
end
end
