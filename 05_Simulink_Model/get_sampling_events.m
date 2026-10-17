function T = get_sampling_events(out)
%GET_SAMPLING_EVENTS  Sampling events of a simulation of Transformer_Operating_Model, with the record_id of each held-out record.
%
%   T = get_sampling_events(out)
%
%   out  Simulink.SimulationOutput of the model (it holds the logged signal record_index).
%   T    table with one row per sampling event: time_h (time at which record_index increased, h),
%        record_index (row number in heldout_record_ids) and record_id (text, e.g. "IECTC10_0001").
%
%   The model (SS8_Sampling_Events) only counts sampling times; it never holds a record_id or a gas value. This function does the
%   look-up OUTSIDE the model with heldout_record_ids from params_transformer.m (columns record_id and data_role of
%   dga_master.csv only). The dashboard then reads the five gases of that record from the CSV file (decision D35).
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 37.   MATLAB R2025b.

ids = evalin('base', 'heldout_record_ids');
idx = squeeze(out.record_index.Data);
t   = out.record_index.Time;
k   = find(diff(idx) > 0) + 1;                      % first logged point after each sampling time
T = table(t(k) / 3600, idx(k), ids(idx(k)), 'VariableNames', {'time_h', 'record_index', 'record_id'});
end
