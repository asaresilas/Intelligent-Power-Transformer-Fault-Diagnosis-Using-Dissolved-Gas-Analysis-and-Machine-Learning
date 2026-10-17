function t = bound_test(x, boundType, lower, upper)
%BOUND_TEST  Is a ratio inside one printed interval? (decision D11, rule 3)
%
%   t = bound_test(x, boundType, lower, upper)
%
%   INPUT   x          ratio values (array; NaN = undefined ratio, always false)
%           boundType  how the standard prints the interval (column bound_type of the CSV files)
%           lower,upper  the numerical limits read from the CSV (NaN when not printed)
%   OUTPUT  t          logical array, same size as x
%
%   MEANING OF boundType (decision D11, rule 3: "<" and ">" are strict; printed ranges "a - b" and
%   "a to b" include both end points)
%     lt                          x <  upper
%     gt                          x >  lower
%     gt_lt                       lower < x < upper            (printed ">a to <b")
%     range_endpoints_not_stated  lower <= x <= upper          (printed "a - b" or "a to b")
%     gt_but_ns                   printed ">1 but NS" (IEC T1, CH4/H2): used as x > lower (decision D13, 2026-10-11)
%     ns                          "not significant": the ratio is NOT used to decide. These rows are
%                                 never passed to this function (callers skip them); an error is raised
%                                 if it happens, so that the rule cannot be applied by accident.
%
%   Why exact comparison is safe: x = a/b is correctly rounded by IEEE 754, so a quotient that is
%   exactly equal to a printed limit (for example 3/30 and 0.1) gives exactly the same double number,
%   and the strict / inclusive rules above then decide the boundary case.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

switch boundType
    case "lt"
        t = x < upper;
    case {"gt", "gt_but_ns"}
        t = x > lower;                     % "gt_but_ns" (printed ">1 but NS") is used as ">" (decision D13)
    case "gt_lt"
        t = x > lower & x < upper;
    case "range_endpoints_not_stated"
        t = x >= lower & x <= upper;
    otherwise
        error('bound_test:type', 'bound_type "%s" is not a decision interval.', boundType);
end
t = t & ~isnan(x);
end
