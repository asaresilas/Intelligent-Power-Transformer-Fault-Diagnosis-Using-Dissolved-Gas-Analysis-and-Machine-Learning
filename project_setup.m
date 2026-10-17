%% project_setup.m
% Run this once at the start of every MATLAB session (or add it to startup).
% It puts all project MATLAB folders on the path and loads the parameters.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, '04_MATLAB_Conventional'));
addpath(fullfile(root, '05_Simulink_Model'));
addpath(fullfile(root, '10_Dashboard_Client'));
params_transformer;                       % parameters into the base workspace
fprintf('Project paths added. Parameters loaded from params_transformer.m\n');
