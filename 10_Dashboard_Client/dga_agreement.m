function a = dga_agreement(d, m)
%DGA_AGREEMENT  Do the three conventional diagnoses agree with the machine-learning diagnosis? (decision D37, clause 2)
%
%   a = dga_agreement(d, m)
%
%   INPUT   d  result of conventional_diagnosis for ONE sample (fields rogers, iec, duval)
%           m  result of ml_diagnose (fields status, fault_class)
%
%   RULE    A conventional answer agrees with the ML class if it is equal to it. The IEC dual answer "D1/D2" agrees if the
%           ML class is D1 or D2 (decisions D11 rule 4 and D25). "DT" (Duval) and "ND" (no diagnosis) never agree: they are
%           no single diagnosis (D25).
%
%   OUTPUT  a.state    "green" all three agree | "amber" at least one does not | "grey" ML not available
%           a.agrees   1x3 logical in the order Rogers, IEC, Duval (false when state is grey)
%           a.count    number of conventional methods that agree (NaN when state is grey)
%           a.label    text for the dashboard
%           a.color    1x3 RGB of the lamp (Build Guide C4.5)
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 39.
conv = [string(d.rogers), string(d.iec), string(d.duval)];
a.agrees = false(1, 3);
if m.status ~= "OK"
    a.state = "grey"; a.count = NaN; a.color = [0.6 0.6 0.6];
    a.label = 'Agreement: not available';
    return
end
cls = string(m.fault_class);
for k = 1:3
    if conv(k) == "D1/D2"
        a.agrees(k) = any(cls == ["D1", "D2"]);
    elseif any(conv(k) == ["DT", "ND", ""])
        a.agrees(k) = false;
    else
        a.agrees(k) = (conv(k) == cls);
    end
end
a.count = sum(a.agrees);
if a.count == 3
    a.state = "green"; a.color = [0 0.7 0];
    a.label = 'Agreement: all methods agree';
else
    a.state = "amber"; a.color = [0.9 0.5 0];
    a.label = sprintf('Agreement: methods disagree (%d of 3 agree with ML)', a.count);
end
end