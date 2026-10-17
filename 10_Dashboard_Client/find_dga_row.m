function row = find_dga_row(file, record_id)
%FIND_DGA_ROW  Row number of a record_id in a DGA file (decision D38, clause 3).
%   row = find_dga_row(file, record_id)   NaN if the record_id is not in the file or the file has no record_id column.
%   Only the record_id column is read.
row = NaN;
opts = detectImportOptions(file);
if ~ismember('record_id', opts.VariableNames), return, end
opts.SelectedVariableNames = {'record_id'};
opts = setvartype(opts, 'record_id', 'string');
T = readtable(file, opts);
r = find(T.record_id == string(record_id), 1);
if ~isempty(r), row = r; end
end