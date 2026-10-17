% Build the model, simulate the rated-load case and compare with an
% independent numerical solution of the IEC 60076-7 differential equations.
fid = fopen('verify_log.txt', 'w');
cleanup = onCleanup(@() fclose(fid));
mdl = 'Transformer_Operating_Model';
try
    build_transformer_model(mdl, 'NE_FREQUENCY_TIME_EF');
    fprintf(fid, 'BUILD OK\n');
catch ME
    fprintf(fid, 'BUILD FAILED: %s\n', getReport(ME, 'extended', 'hyperlinks', 'off')); return
end
params_transformer;
try
    set_param(mdl, 'SimulationCommand', 'update'); fprintf(fid, 'UPDATE OK\n');
catch ME
    fprintf(fid, 'UPDATE FAILED: %s\n', getReport(ME, 'basic', 'hyperlinks', 'off')); 
end
tic;
try
    out = sim(mdl);
    fprintf(fid, 'SIM OK in %.1f s (wall)\n', toc);
catch ME
    fprintf(fid, 'SIM FAILED: %s\n', getReport(ME, 'basic', 'hyperlinks', 'off')); return
end
K  = out.K_pu; To = out.theta_oil_C; Th = out.theta_hs_C; V = out.ageing_rate_V;
fprintf(fid, 'K final %.4f (min %.4f, max %.4f)\n', K.Data(end), min(K.Data), max(K.Data));
fprintf(fid, 'theta_oil final %.3f C, theta_hs final %.3f C, V final %.4f\n', To.Data(end), Th.Data(end), V.Data(end));
% Independent reference: IEC 60076-7 differential equations solved with ode45
Kc = mean(K.Data(K.Time > 3600));
Rr = Pk/P0;
f = @(t, z) [ ( dTheta_or*((1+Kc^2*Rr)/(1+Rr))^x_oil - z(1) ) / (k11*tau_o_min*60);
              ( k21*dTheta_hr*Kc^y_wdg - z(2) ) / (k22*tau_w_min*60);
              ( (k21-1)*dTheta_hr*Kc^y_wdg - z(3) ) / (tau_o_min*60/k22) ];
[tr, zr] = ode45(f, [0 t_stop], [0 0 0], odeset('RelTol', 1e-8, 'AbsTol', 1e-8));
oil_ref = theta_amb_C + zr(:,1); hs_ref = oil_ref + zr(:,2) - zr(:,3);
oil_m = interp1(To.Time, To.Data, tr); hs_m = interp1(Th.Time, Th.Data, tr);
sel = tr > 600;
fprintf(fid, 'Reference (K=%.4f): oil final %.3f C, hs final %.3f C\n', Kc, oil_ref(end), hs_ref(end));
fprintf(fid, 'Max |model-ref| after 10 min: oil %.3f K, hot-spot %.3f K\n', max(abs(oil_m(sel)-oil_ref(sel))), max(abs(hs_m(sel)-hs_ref(sel))));
% Top-oil 63 %% time
rise = To.Data - theta_amb_C; t63 = To.Time(find(rise >= 0.632*rise(end), 1));
fprintf(fid, 'Top-oil 63%% rise time %.1f min (expected k11*tau_o = %.1f min)\n', t63/60, k11*tau_o_min);
fprintf(fid, 'Derived: Pk=%.0f W, R=%.3f, X=%.5f pu, Rm=%.1f pu, Xm=%.1f pu, R_th_oil=%.4e K/W, C_th_oil=%.4e J/K, I_LV_rated=%.2f A\n', ...
    Pk, Rr, X_pu_tot, Rm_pu, Xm_pu, R_th_oil, C_th_oil, I_LV_rated);
save('verify_results.mat', 'out', 'tr', 'oil_ref', 'hs_ref');
