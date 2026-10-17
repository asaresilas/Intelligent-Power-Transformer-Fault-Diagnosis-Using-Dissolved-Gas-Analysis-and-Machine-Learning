function ok = verify_data_version(varargin)
%VERIFY_DATA_VERSION  Check that every frozen file still has its recorded SHA-256 fingerprint.
%
%   ok = verify_data_version()                 stops with an error if any file differs or is missing
%   ok = verify_data_version('Stop', false)    returns false instead of raising an error
%   ok = verify_data_version('Quiet', true)    no printed list
%
%   PURPOSE
%     Rule 2 of the toolkit instructions (Steps_14-17_MATLAB.md): "Use only data version 1.0. At the
%     start of every script, recompute the SHA-256 of each file listed in 03_Data/data_version_1.0.sha256
%     and stop with an error if any differs."  The Python twin is common.verify_data_version().
%
%   METHOD
%     Each manifest line is "<64 hex characters>  <relative path>". The file is read as bytes and hashed
%     with java.security.MessageDigest('SHA-256') (the JVM ships with MATLAB desktop); the result is
%     compared, case-insensitively, with the recorded value.
%
%   OUTPUT  ok  (logical) true when all files match.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

p = inputParser;
addParameter(p, 'Stop',  true);
addParameter(p, 'Quiet', false);
parse(p, varargin{:});

C = conv_config();
lines = readlines(C.manifestFile);
lines = strtrim(lines(strlength(strtrim(lines)) > 0));
nBad = 0;
for i = 1:numel(lines)
    tok = regexp(lines(i), '^([0-9a-fA-F]{64})\s{2}(.+)$', 'tokens', 'once');
    if isempty(tok)
        error('verify_data_version:badLine', 'Manifest line %d is not "<sha256>  <path>": %s', i, lines(i));
    end
    want = lower(tok(1));
    rel  = tok(2);
    f = fullfile(C.root, strrep(rel, '/', filesep));
    if ~isfile(f)
        got = "MISSING";
    else
        got = file_sha256(f);
    end
    same = (got == want);
    if ~same, nBad = nBad + 1; end
    if ~p.Results.Quiet
        fprintf('  %-4s %s\n', ternary(same, 'OK', 'DIFF'), rel);
    end
end
ok = (nBad == 0);
if ~p.Results.Quiet
    fprintf('Data version %s: %d files checked, %d differ.\n', C.dataVersion, numel(lines), nBad);
end
if ~ok && p.Results.Stop
    error('verify_data_version:changed', ...
        '%d file(s) differ from data version %s. Stop: results would not be reproducible.', nBad, C.dataVersion);
end
end

function h = file_sha256(f)
% SHA-256 of a file as 64 lowercase hex characters.
fid = fopen(f, 'r');
cleaner = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, '*uint8');
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(typecast(bytes, 'int8'));
h = string(lower(reshape(dec2hex(typecast(md.digest(), 'uint8'), 2).', 1, [])));
end

function out = ternary(c, a, b)
if c, out = a; else, out = b; end
end
