function [g, info] = load_dga_record(file, row)
%LOAD_DGA_RECORD Read one measured DGA record (the "playback" step).
%   [g, info] = load_dga_record(file, row)
%   file: CSV/XLSX from 03_Data/processed with columns H2, CH4, C2H6, C2H4, C2H2
%         (ppm) and, optionally, record_id and equipment_type.
%   g: struct of gas values (+ record_id and equipment_type when the file has them, decision D37 clause 4);
%      info: the full table row (kept for traceability).
%   Gas values are read as they are: nothing is created, changed or filled in.
T = readtable(file, 'TextType', 'string');
need = {'H2', 'CH4', 'C2H6', 'C2H4', 'C2H2'};
missing = setdiff(need, T.Properties.VariableNames);
if ~isempty(missing)
    error('load_dga_record:columns', 'Missing columns: %s', strjoin(missing, ', '));
end
if row < 1 || row > height(T) || row ~= round(row)
    error('load_dga_record:row', 'Row %d outside 1..%d', row, height(T));
end
g = struct();
for k = 1:numel(need), g.(need{k}) = T.(need{k})(row); end
if ismember('record_id', T.Properties.VariableNames), g.record_id = string(T.record_id(row)); end
if ismember('equipment_type', T.Properties.VariableNames)
    et = string(T.equipment_type(row)); if ismissing(et), et = ""; end
    g.equipment_type = et;
end
info = T(row, :);
end