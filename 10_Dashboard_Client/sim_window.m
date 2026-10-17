function rw = sim_window(r, from_h)
%SIM_WINDOW  The part of a simulation result from from_h onward, with time restarted at 0 (17 Oct 2026).
%
%   rw = sim_window(r, from_h)
%
%   r       result of run_transformer_simulation (t_h, K_pu, theta_oil_C, theta_hs_C, ageing_V, loss_of_life_h, events)
%   from_h  start of the window [h]; 0 returns r unchanged.
%   Used for the daily cycle: three days are simulated so that the temperatures settle, the last day is shown (as in Step 36).
%   The loss of life is recomputed over the window (integral of the ageing rate, trapezoidal rule, as in run_transformer_simulation).
%   Events inside the window keep their record_index and record_id; their time_h is measured from the window start.
%   Project: MPhil, DGA transformer fault diagnosis - dashboard redesign.

rw = r;
if from_h <= 0, return, end
w = r.t_h >= from_h;
rw.t_h = r.t_h(w) - from_h;
rw.K_pu = r.K_pu(w);  rw.theta_oil_C = r.theta_oil_C(w);  rw.theta_hs_C = r.theta_hs_C(w);  rw.ageing_V = r.ageing_V(w);
rw.loss_of_life_h = trapz(rw.t_h * 3600, rw.ageing_V) / 3600;
if isfield(r, 'events') && ~isempty(r.events)
    e = r.events(r.events.time_h >= from_h, :);
    e.time_h = e.time_h - from_h;
    rw.events = e;
end
rw.show_from_h = from_h;
end
