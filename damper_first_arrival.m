function damper_first_arrival
% damper_first_arrival.m  -  ALL the 6 m ROPE-SUPPORT runs, looked at through the FIRST ARRIVAL of the wave only (and, for comparison, the
% 2nd, 3rd and 4th passes).  MATLAB (also runs in Octave).
% NOTE uncomment the %% settings region edit inputs, current input is that an example:
%% 0. SETTINGS
% dataRoot     = '.';                                % folder that CONTAINS the two data folders
% folderNew    = 'm12_5November_6mRopeSupportNewTests';
% folderSorted = 'M12_sorted';
% saveFigs     = true;                               % PNG files in <dataRoot>/Damper_first_arrival_figures/
% Leff         = 5.58;                               % hammer-to-receiver path in beam-theory metres (the direct wave is found there; the rod is 6 m)
% beamC        = 0.005*5032;                         % bending dispersion constant (m^2/s) of the 20 mm rod
% bandHz       = 100;                                % each point averages fc +/- bandHz
% fcGrid       = 300:25:6000;                        % centre frequencies (Hz)
% arrivals     = [1 3 4];                            % which arrivals are drawn (1 = first arrival; 3 = 5 passes; 4 = 7 passes)
% a1 = [0.65 1.5];   aK = [0.8 1.25];                % window limits (x group delay) for the 1st arrival and for the later ones
% taperFrac    = 0.2;                                % Tukey taper of the window
% xlimFull     = [300 6000];   xlimZoom = [1100 2200];
% searchBand   = [1000 2200];                        % the largest loss is looked for here (the hammer is too weak above about 2.3 kHz)
% edgeFrac     = 0.05;   baseGap = 0.2e-3;
% ==========================================================================================================================
root = dataRoot;
if ~exist(fullfile(root,folderNew),'dir') || ~exist(fullfile(root,folderSorted),'dir')
    d_ = uigetdir(pwd, sprintf('Select the folder that CONTAINS both %s and %s', folderNew, folderSorted));
    if isequal(d_,0), error('Cannot find the data folders.'); end
    root = d_;
end
N_ = [folderNew '/'];  S_ = [folderSorted '/'];
% sets: name, pattern, reference (index into B; 0 = pooled B1+B2)
B = {'No damper 10:07',          [N_ '6mRopeWhite_new_run*.csv'];
     'No damper 10:49',          [N_ '6mRopeWhite_new2_run*.csv'];
     'No damper 06:50 (early)',  [S_ '05Nov/6m_rope_nodamper/*.csv'];
     'No damper 2 Nov (other day)', [S_ '_02Nov_nodamper_DIFFERENT_DAY_not_a_3Nov_baseline/6m_rope_nodamper/*.csv']};
T = {'Damper 450 mm, set 1 (10:14)',     [N_ '*450mm_Damper6mRopeWhite_new_run*.csv'],  0;
     'Damper 450 mm, set 2 (10:46)',     [N_ '*450mm_Damper6mRopeWhite_new2_run*.csv'], 0;
     'Damper 710 mm, set 1 (10:31)',     [N_ '*710mm_Damper6mRopeWhite_new_run*.csv'],  0;
     'Damper 710 mm, set 2 (10:42)',     [N_ '*710mm_Damper6mRopeWhite_new2_run*.csv'], 0;
     'Damper 710 mm, early (07:03)',     [S_ '05Nov/6m_rope_damper_710mm/*.csv'],       3};
col = {[0.1 0.35 0.85],[0.85 0.1 0.1],[0.1 0.6 0.25],[0.85 0.45 0],[0.6 0 0.8]};
nB = size(B,1);  nT = size(T,1);

%% 1. read every hit
fprintf('Reading the hits ...\n');
setsB = cell(nB,1);  setsT = cell(nT,1);
for q = 1:nB, setsB{q} = load_set_(files_(root,B{q,2}), edgeFrac, baseGap); fprintf('  %-34s %2d hits, force pulse %.2f ms\n', B{q,1}, numel(setsB{q}.x), 1e3*mean(setsB{q}.pw)); end
for q = 1:nT, setsT{q} = load_set_(files_(root,T{q,2}), edgeFrac, baseGap); fprintf('  %-34s %2d hits, force pulse %.2f ms\n', T{q,1}, numel(setsT{q}.x), 1e3*mean(setsT{q}.pw)); end
dt = setsB{1}.dt;  Fs = 1/dt;
nUse = inf;
for q = 1:nB, nUse = min([nUse, cellfun(@numel,setsB{q}.y)]); end
for q = 1:nT, nUse = min([nUse, cellfun(@numel,setsT{q}.y)]); end
Nf = 2^15;  f = Fs*(0:Nf/2)'/Nf;
tt = (0:nUse-1)'*dt;
fprintf('Using %.1f ms of every record.  The window of the hammer force is %.2f ms wide (Ch1 only).\n', 1e3*nUse*dt, 1e3*mean(setsT{1}.pw));

%% 2. window-by-window power ratio
nfc = numel(fcGrid);
R = @(S) zeros(numel(S.x), nfc);
Hb = cell(nB, max(arrivals));  Ht = cell(nT, max(arrivals));
for ak = arrivals
    for q = 1:nB, Hb{q,ak} = R(setsB{q}); end
    for q = 1:nT, Ht{q,ak} = R(setsT{q}); end
    for j = 1:nfc
        fcj = fcGrid(j);  t0 = Leff/(2*sqrt(2*pi*fcj*beamC));
        if ak == 1, lim = a1*t0; else, lim = (2*ak-1)*aK*t0; end
        w = tukey_(tt, lim(1), lim(2), taperFrac);
        bm = f >= fcj-bandHz & f <= fcj+bandHz;
        for q = 1:nB, Hb{q,ak}(:,j) = ratio_(setsB{q}, w, bm, nUse, Nf); end
        for q = 1:nT, Ht{q,ak}(:,j) = ratio_(setsT{q}, w, bm, nUse, Nf); end
    end
end

%% 3. changes against the no-damper hits of the same session
chg = cell(nT, max(arrivals));  ctl = cell(nB, max(arrivals));
for ak = arrivals
    refPool = [Hb{1,ak}; Hb{2,ak}];
    for q = 1:nT
        if T{q,3} == 0, rr = refPool; else, rr = Hb{T{q,3},ak}; end
        chg{q,ak} = 10*log10(mean(Ht{q,ak},1) ./ mean(rr,1));
    end
    ctl{1,ak} = 10*log10(mean(Hb{1,ak},1) ./ mean(Hb{2,ak},1));      % no damper 10:07 against 10:49
    ctl{2,ak} = 10*log10(mean(Hb{3,ak},1) ./ mean(refPool,1));       % no damper 06:50 against the 10:07/10:49 pool
    ctl{3,ak} = 10*log10(mean(Hb{4,ak},1) ./ mean(refPool,1));       % no damper 2 Nov against the pool
end
ctlName = {'control: no damper 10:07 vs 10:49','control: no damper 06:50 vs pool','control: no damper 2 Nov vs pool'};

%% 4. table
sm3 = @(v) conv(v, ones(1,3)/3, 'same');
inS = fcGrid >= searchBand(1) & fcGrid <= searchBand(2);
fprintf('\n=== LARGEST LOSS between %d and %d Hz (curves averaged over 150 Hz), against the no-damper hits of the same session ===\n', searchBand);
fprintf('%-34s %-22s %12s %10s %12s\n', 'Damper set', 'Arrival (passes)', 'at (Hz)', 'loss (dB)', 'noise (dB)');
for q = 1:nT
    for ak = arrivals
        v = sm3(chg{q,ak});  vv = v;  vv(~inS) = inf;  [mn, im] = min(vv);
        nz = max(abs([ctl{1,ak}(inS) ctl{2,ak}(inS)]));          % largest change seen between two NO-damper sets in this band
        fprintf('%-34s %-22s %12d %10.1f %12.1f\n', T{q,1}, sprintf('%d (%d pass%s)', ak, 2*ak-1, repmat('es',1,ak>1)), fcGrid(im), mn, nz);
    end
end
fprintf('\n"noise" = the largest change found between two no-damper sets in the same band, i.e. a loss smaller than this proves nothing.\n');

%% 5. figures
fpos = [0.04 0.05 0.60 0.85];
od = fullfile(root,'Damper_first_arrival_figures');  if saveFigs && ~exist(od,'dir'), mkdir(od); end
% --- figure 1
h1 = figure('Name','1 Force pulse and response windows','Color','w','Units','normalized','Position',fpos,'NumberTitle','off');
sB = setsB{1};  sD = setsT{1};
subplot(3,1,1); hold on;
plot(1e3*sD.tf{1}, sD.x{1}, 'r', 'LineWidth',1.4);  xlim([-0.2 1.5]); grid on;
plot(1e3*[0 sD.pw(1)], 0.05*max(sD.x{1})*[1 1], 'k', 'LineWidth',2);
xlabel('Time after the hit (ms)'); ylabel('Hammer force, Ch1 (V)');
title(sprintf('Hammer force pulse: %.2f ms wide (5 %% to 5 %%).', 1e3*sD.pw(1)));
fp = 1550;  t0 = Leff/(2*sqrt(2*pi*fp*beamC));
subplot(3,1,2); hold on;
plot(1e3*tt, sB.y{1}(1:nUse), 'Color',[0.4 0.4 0.4]); yl = max(abs(sB.y{1}(1:nUse)))*1.1;  ylim(yl*[-1 1]);
for ak = 1:4
    if ak == 1, lim = a1*t0; else, lim = (2*ak-1)*aK*t0; end
    patch(1e3*[lim(1) lim(2) lim(2) lim(1)], yl*[-1 -1 1 1], col{ak}, 'FaceAlpha',0.15, 'EdgeColor','none');
end
xlim([0 1e3*nUse*dt]); grid on; xlabel('Time after the hit (ms)'); ylabel('Response, Ch2 (V)');
title(sprintf('No-damper hit and the windows used at %d Hz (1st arrival, then 3, 5, 7 passes)', fp));
subplot(3,1,3); hold on;
plot(1e3*tt, sD.y{1}(1:nUse), 'Color',[0.85 0.1 0.1]); ylim(yl*[-1 1]);
for ak = 1:4
    if ak == 1, lim = a1*t0; else, lim = (2*ak-1)*aK*t0; end
    patch(1e3*[lim(1) lim(2) lim(2) lim(1)], yl*[-1 -1 1 1], col{ak}, 'FaceAlpha',0.15, 'EdgeColor','none');
end
xlim([0 1e3*nUse*dt]); grid on; xlabel('Time after the hit (ms)'); ylabel('Response, Ch2 (V)');
title(sprintf('%s, same windows', T{1,1}));
% --- figures 2..4
fh = h1;  names = {'1_force_pulse_and_windows'};
for ak = arrivals
    for z = 1:2
        if z == 1, xl = xlimFull; zn = 'full'; else, xl = xlimZoom; zn = 'zoom'; end
        hz = figure('Name',sprintf('Arrival %d, %s',ak,zn),'Color','w','Units','normalized','Position',fpos,'NumberTitle','off'); hold on;
        for k = 1:3, plot(fcGrid, ctl{k,ak}, '-', 'Color',[0.6 0.6 0.6]+0.1*(k-2), 'LineWidth',1.0); end
        for q = 1:nT, plot(fcGrid, chg{q,ak}, 'Color',col{q}, 'LineWidth',1.7); end
        plot(xl, [0 0], 'k:');  xlim(xl);  grid on;
        ylim([-14 8]);
        xlabel('Frequency (Hz)');  ylabel('Change with the damper (dB)  [negative = damper lowers the signal]');
        title(sprintf('Arrival %d (the wave has passed the damper %d time%s): damper against no damper of the same session', ak, 2*ak-1, repmat('s',1,ak>1)));
        legend([ctlName, T(:,1)'], 'Location','southwest', 'FontSize',8);
        fh(end+1) = hz;  names{end+1} = sprintf('arrival%d_%s', ak, zn); %#ok<AGROW>
    end
end
for q = 1:numel(fh)
    try, set(findall(fh(q),'-property','FontName'),'FontName','Times New Roman'); catch, end %#ok<CTCH>
    if saveFigs, try, print(fh(q), fullfile(od,[names{q} '.png']), '-dpng', '-r150'); catch e_, fprintf('(could not save %s: %s)\n', names{q}, e_.message); end, end %#ok<CTCH>
end
fprintf('\nFigures saved in %s\n', od);
% dump for checking
if exist('OCTAVE_VERSION','builtin')
    M = fcGrid(:);  for ak = arrivals, for q = 1:nT, M(:,end+1) = chg{q,ak}(:); end, for k = 1:3, M(:,end+1) = ctl{k,ak}(:); end, end %#ok<AGROW>
    csvwrite(fullfile(root,'first_arrival_dump.csv'), M);
end
end

% ---------------------------------------------------------------------------------------------------------------------------
function S = load_set_(fl, edgeFrac, baseGap)
n = numel(fl);  S.x = cell(1,n);  S.y = cell(1,n);  S.tf = cell(1,n);  S.pw = zeros(1,n);
for k = 1:n
    [time, c1, c2] = read_hit_(fl{k});
    dt = time(2)-time(1);  S.dt = dt;  L = numel(time);
    pre = time < -baseGap;  if nnz(pre) < 20, pre = false(L,1); pre(1:round(0.05*L)) = true; end
    x = c1 - mean(c1(pre));  y = c2 - mean(c2(pre));
    [pk, ip] = max(x);
    i0 = find(x(1:ip) < edgeFrac*pk, 1, 'last');  if isempty(i0), i0 = 1; end
    i1 = find(x(ip:end) <= edgeFrac*pk, 1, 'first') + ip - 1;
    if isempty(i1), error('%s: force never fell back below %g %% of its peak.', fl{k}, 100*edgeFrac); end
    S.pw(k) = time(i1) - time(i0);
    xx = x(i0:end);  xx(i1-i0+1+round(0.2e-3/dt):end) = 0;        % force pulse only (plus 0.2 ms), zero afterwards
    S.x{k} = xx;  S.y{k} = y(i0:end);  S.tf{k} = time(i0:end) - time(i0);
end
end

function r = ratio_(S, w, bm, nUse, Nf)
n = numel(S.x);  r = zeros(n,1);
for k = 1:n
    Y = fft(S.y{k}(1:nUse) .* w, Nf);   xx = zeros(nUse,1);  m = min(nUse, numel(S.x{k}));  xx(1:m) = S.x{k}(1:m);
    X = fft(xx, Nf);
    r(k) = mean(abs(Y(bm)).^2) / mean(abs(X(bm)).^2);
end
end

function w = tukey_(t, t0, t1, frac)
w = zeros(size(t));  ii = find(t >= t0 & t <= t1);
if numel(ii) < 8, return; end
L = numel(ii);  m = max(2, round(frac*L));  w(ii) = 1;
rp = 0.5*(1 - cos(pi*(0:m-1)'/m));
w(ii(1:m)) = rp;  w(ii(end-m+1:end)) = flipud(rp);
end

function [t, c1, c2] = read_hit_(fn)
fid = fopen(fn,'r');  if fid < 0, error('Cannot open %s', fn); end
n = 0;
while true
    l = fgetl(fid);  n = n + 1;
    if ~ischar(l), fclose(fid); error('No "Time" header line in %s', fn); end
    if strncmpi(strtrim(l),'Time',4), break; end
end
fclose(fid);
D = dlmread(fn, ',', n, 0);
D = D(~any(isnan(D),2), :);
t = D(:,1);  c1 = D(:,2);  c2 = D(:,3);
end

function out = files_(root, pattern)
pattern = strrep(pattern,'/',filesep);
d = dir(fullfile(root, pattern));
if isempty(d), error('No files match %s in %s', pattern, root); end
d = d(~[d.isdir]);
fdir = fileparts(fullfile(root, pattern));
nm = {d.name};  num = zeros(1,numel(nm));
for q = 1:numel(nm)
    tk = regexp(nm{q}, 'run(\d+)', 'tokens', 'once');
    if ~isempty(tk), num(q) = str2double(tk{1}); end
end
[~, ix] = sort(num);
out = cell(1,numel(nm));
for q = 1:numel(nm), out{q} = fullfile(fdir, nm{ix(q)}); end
end
