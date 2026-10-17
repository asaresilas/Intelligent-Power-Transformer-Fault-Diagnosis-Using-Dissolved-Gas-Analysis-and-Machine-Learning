% export_thesis_snapshots.m - exports pictures of the FINAL Simulink model for the thesis (Stage I).
% Read-only: the model is loaded, printed and closed WITHOUT saving; its SHA-256 is recorded before and after.
% Output: 12_Thesis/figures/simulink_top_level.png and simulink_<subsystem>.png (300 dpi).
here   = fileparts(mfilename('fullpath'));
mdlDir = fileparts(here);
root   = fileparts(mdlDir);
outDir = fullfile(root, '12_Thesis', 'figures');
if ~exist(outDir, 'dir'), mkdir(outDir); end
addpath(mdlDir);
mdl  = 'Transformer_Operating_Model';
file = fullfile(mdlDir, [mdl '.slx']);
h0 = sha256_of(file);
load_system(file);
print(['-s' mdl], '-dpng', '-r300', fullfile(outDir, 'simulink_top_level.png'));
subs = find_system(mdl, 'SearchDepth', 1, 'BlockType', 'SubSystem');
for k = 1:numel(subs)
    nm = get_param(subs{k}, 'Name');
    print(['-s' subs{k}], '-dpng', '-r300', fullfile(outDir, ['simulink_' nm '.png']));
end
close_system(mdl, 0);
h1 = sha256_of(file);
fid = fopen(fullfile(outDir, 'simulink_snapshots_log.txt'), 'w');
fprintf(fid, 'Exported %s (MATLAB %s)\nmodel SHA-256 before %s\nmodel SHA-256 after  %s\nsubsystems: %s\n', ...
    datestr(now, 'yyyy-mm-dd HH:MM:SS'), version, h0, h1, strjoin(cellfun(@(s) get_name(s), subs, 'UniformOutput', false), ', '));
fclose(fid);
assert(strcmp(h0, h1), 'model file changed');
disp('snapshots exported');

function n = get_name(s)
    parts = strsplit(s, '/'); n = parts{end};
end

function h = sha256_of(f)
    md = java.security.MessageDigest.getInstance('SHA-256');
    fid = fopen(f, 'r'); b = fread(fid, inf, '*uint8'); fclose(fid);
    md.update(b);
    d = typecast(md.digest(), 'uint8');
    h = upper(reshape(dec2hex(d, 2)', 1, []));
end
