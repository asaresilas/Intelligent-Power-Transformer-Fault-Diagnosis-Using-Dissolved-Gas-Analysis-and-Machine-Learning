% Test 2: load step 0.6 -> 1.2 pu at 6 h, compared with the IEC equations
% driven by the measured K(t). Also exports figures for the guide.
fid = fopen('verify_log2.txt', 'w'); c = onCleanup(@() fclose(fid));
mdl = 'Transformer_Operating_Model'; load_system(mdl);
params_transformer;
t_step = 6*3600;
load_profile = timeseries([0.6; 0.6; 1.2; 1.2], [0; t_step; t_step + 1; t_stop]);
in = Simulink.SimulationInput(mdl);
in = in.setVariable('load_profile', load_profile);
out2 = sim(in);
K = out2.K_pu; To = out2.theta_oil_C; Th = out2.theta_hs_C;
Kf = @(t) interp1(K.Time, squeeze(K.Data), t, 'linear', 'extrap');
Rr = Pk/P0;
f = @(t, z) [ ( dTheta_or*((1+Kf(t)^2*Rr)/(1+Rr))^x_oil - z(1) ) / (k11*tau_o_min*60);
              ( k21*dTheta_hr*Kf(t)^y_wdg - z(2) ) / (k22*tau_w_min*60);
              ( (k21-1)*dTheta_hr*Kf(t)^y_wdg - z(3) ) / (tau_o_min*60/k22) ];
[tr, zr] = ode15s(f, [0 t_stop], [0 0 0], odeset('RelTol', 1e-8, 'AbsTol', 1e-8, 'MaxStep', 30));
oil_ref = theta_amb_C + zr(:,1); hs_ref = oil_ref + zr(:,2) - zr(:,3);
oil_m = interp1(To.Time, squeeze(To.Data), tr); hs_m = interp1(Th.Time, squeeze(Th.Data), tr);
sel = tr > 600;
fprintf(fid, 'TEST2 K before %.4f after %.4f\n', Kf(t_step-60), Kf(t_stop));
fprintf(fid, 'TEST2 Max |model-ref| after 10 min: oil %.3f K, hot-spot %.3f K\n', max(abs(oil_m(sel)-oil_ref(sel))), max(abs(hs_m(sel)-hs_ref(sel))));
fprintf(fid, 'TEST2 final: oil %.2f C, hs %.2f C; peak hs %.2f C\n', To.Data(end), Th.Data(end), max(Th.Data));
% Figures
S1 = load('verify_results.mat');
fg = figure('Visible', 'off', 'Position', [100 100 900 360]); try, theme(fg, 'light'); catch, end
subplot(1,2,1);
plot(S1.out.theta_oil_C.Time/3600, squeeze(S1.out.theta_oil_C.Data), 'b', S1.out.theta_hs_C.Time/3600, squeeze(S1.out.theta_hs_C.Data), 'r', 'LineWidth', 1.4); hold on
plot(S1.tr/3600, S1.oil_ref, 'k--', S1.tr/3600, S1.hs_ref, 'k:', 'LineWidth', 1.1); grid on
xlabel('Time (h)'); ylabel('Temperature (\circC)'); title('Test 1: rated load from cold start');
legend('Top-oil (Simscape)', 'Hot-spot (Simscape)', 'Top-oil (IEC equations)', 'Hot-spot (IEC equations)', 'Location', 'southeast');
subplot(1,2,2);
plot(To.Time/3600, squeeze(To.Data), 'b', Th.Time/3600, squeeze(Th.Data), 'r', 'LineWidth', 1.4); hold on
plot(tr/3600, oil_ref, 'k--', tr/3600, hs_ref, 'k:', 'LineWidth', 1.1); grid on
xlabel('Time (h)'); ylabel('Temperature (\circC)'); title('Test 2: load step 0.6 \rightarrow 1.2 pu at 6 h');
exportgraphics(fg, 'fig_verification.png', 'Resolution', 200);
% Model diagrams
open_system(mdl);
print(['-s' mdl], '-dpng', '-r150', 'diag_top.png');
subs = {'SS1_Grid_Supply', 'SS2_Power_Transformer', 'SS3_LV_Measurement', 'SS4_Variable_Load', ...
        'SS5_Losses_to_Heat', 'SS6_Thermal_Network', 'SS7_Outputs_and_Ageing'};
for k = 1:numel(subs)
    open_system([mdl '/' subs{k}]);
    print(['-s' mdl '/' subs{k}], '-dpng', '-r150', sprintf('diag_%s.png', subs{k}));
end
fprintf(fid, 'FIGURES OK\n');
