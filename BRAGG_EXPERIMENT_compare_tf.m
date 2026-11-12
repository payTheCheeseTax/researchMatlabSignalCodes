% WHAT IT DOES, IN THE ORDER YOU WOULD DO IT BY HAND
%   1. VOLTAGE-TIME      Reads every WaveForms CSV (Ch1 = drive, Ch2 = receiver) 
%   2. TIME-AMPLITUDE    Envelope of Ch2 (Hilbert) in dB
%   3. FREQUENCY-AMPLITUDE   FFT of the gated drive and gated response (averaged over the usable runs of a set).
%   4. TRANSFER FUNCTION H(s) = Y(s)/X(s)
%   5. ATTENUATION       T = Hgrooved / Hplain 
%   6. DISPERSION        
% HOW TO USE: edit section 0 only (file lists, gate, bands), then run. 
% Files: only the USABLE runs (see the sorting workbook).
% FOLDERS: sorted_runs/USABLE/{bench,ff}/{20k,100k}/{plain,5mm,8mm}   and   flush_sorted/usable/{ff,bench}/{20k,100k}/{plain,5mm,8mm}

function BRAGG_EXPERIMENT_compare_tf
%% 0. SETTINGS
% where the data is.  dataRoot = the folder that CONTAINS 'sorted_runs' and 'flush_sorted'
dataRoot = '.';

% false = leaves flush transducer tests out them out (default); true = include them (they are then pooled into 'Flush').
useFlushBench100 = false;

% experiments:
U   = '(^|[/_ -])usable';
BEN = 'bench';
FF  = '(^|[/_ -])ff($|[/_ .-])|free';
F20 = '(^|[/_ -])20 *(k|hz|/)';   F100 = '(^|[/_ -])100 *(k|hz|/)';
PL  = 'plain';   G5 = '(^|[/_ -])5 *mm';   G8 = '(^|[/_ -])8 *mm';
NO3 = '~(^|[/_ -])3c($|[/_ .-])';   % leaves out the 3-cycle bursts: the 20 kHz free-free and flush runs are 5-cycle, and mixing 3 and 5 cycles gave two different drive bursts in one set

E = struct('name',{},'tag',{},'folder',{},'p20',{},'g5_20',{},'g8_20',{},'p100',{},'g5_100',{},'g8_100',{});

k = 1;   % ANGLED transducers, bench
E(k).name = 'Angled bench';  E(k).tag = 'Angled';  E(k).folder = 'sorted_runs';
rt = fullfile(dataRoot,E(k).folder);
E(k).p20  = pick_(rt,{U,BEN,F20,PL,NO3});   E(k).g5_20  = pick_(rt,{U,BEN,F20,G5,NO3});   E(k).g8_20  = pick_(rt,{U,BEN,F20,G8,NO3});
E(k).p100 = pick_(rt,{U,BEN,F100,PL});  E(k).g5_100 = pick_(rt,{U,BEN,F100,G5});  E(k).g8_100 = pick_(rt,{U,BEN,F100,G8});

k = 2;   % ANGLED transducers, free-free
E(k).name = 'Angled free-free';  E(k).tag = 'Angled';  E(k).folder = 'sorted_runs';
rt = fullfile(dataRoot,E(k).folder);
E(k).p20  = pick_(rt,{U,FF,F20,PL,NO3});    E(k).g5_20  = pick_(rt,{U,FF,F20,G5,NO3});    E(k).g8_20  = pick_(rt,{U,FF,F20,G8,NO3});
E(k).p100 = pick_(rt,{U,FF,F100,PL});   E(k).g5_100 = pick_(rt,{U,FF,F100,G5});   E(k).g8_100 = pick_(rt,{U,FF,F100,G8});

k = 3;   % FLUSH transducers, free-free   
E(k).name = 'Flush free-free';  E(k).tag = 'Flush';  E(k).folder = 'flush_sorted';
rt = fullfile(dataRoot,E(k).folder);
E(k).p20  = pick_(rt,{U,FF,F20,PL});    E(k).g5_20  = pick_(rt,{U,FF,F20,G5});    E(k).g8_20  = pick_(rt,{U,FF,F20,G8});
E(k).p100 = pick_(rt,{U,FF,F100,PL});   E(k).g5_100 = pick_(rt,{U,FF,F100,G5});   E(k).g8_100 = pick_(rt,{U,FF,F100,G8});

k = 4;   % FLUSH transducers, bench   [delete this block to leave the flush bench runs out]
E(k).name = 'Flush bench';  E(k).tag = 'Flush';  E(k).folder = 'flush_sorted';
rt = fullfile(dataRoot,E(k).folder);
E(k).p20  = pick_(rt,{U,BEN,F20,PL});   E(k).g5_20  = pick_(rt,{U,BEN,F20,G5});   E(k).g8_20  = pick_(rt,{U,BEN,F20,G8});
E(k).p100 = pick_(rt,{U,BEN,F100,PL});  E(k).g5_100 = pick_(rt,{U,BEN,F100,G5});  E(k).g8_100 = pick_(rt,{U,BEN,F100,G8});

% file check: how many runs each list found 
fprintf('\nFILE CHECK (runs found)                plain   5 mm   8 mm     |   plain   5 mm   8 mm\n');
for q = 1:numel(E)
    fprintf('  %-34s 20 kHz: %3d %6d %6d     100 kHz: %3d %6d %6d\n',E(q).name,numel(E(q).p20),numel(E(q).g5_20),numel(E(q).g8_20),numel(E(q).p100),numel(E(q).g5_100),numel(E(q).g8_100));
end

if ~useFlushBench100
    for q = 1:numel(E)
        if strcmp(E(q).name,'Flush bench'), E(q).p100 = {}; E(q).g5_100 = {}; E(q).g8_100 = {}; end
    end
    fprintf('  (Flush bench at 100 kHz is left out: useFlushBench100 = false in section 0.)\n');
end

% rod and wave constants
L    = 1.0;                  % rod length between the transducers [m]
c0   = 5110;                 % bar speed [m/s] (steel: E 205 GPa, rho 7850)
rodR = 0.010;                % rod radius [m]
cpRef = struct('f20',5104,'f100',4873);   % Pochhammer phase speed at 20 kHz and at 100 kHz (Pochhammer solution, 10 mm radius steel rod; same table as material_ in BRAGG_WORKBENCH.m) [m/s]
latt  = struct('f20',0.11375,'f100',0.02375);   % lattice constants of the 2-D rods [m] (Brillouin edge k = pi/a)

% the two frequency cases.  gateMs = first-pass window (ms after the trigger).  All frequencies in kHz.
C(1).name = '20 kHz';  C(1).key = 'f20';  C(1).f0 = 20;   C(1).gateMs = 1.0;  C(1).burst = [16 24];     C(1).fplot = [10 30];
C(1).search = [12 28]; C(1).bridge = 2;    C(1).smooth = 0.5;  C(1).df = 0.05; C(1).fkeep = 60;
C(1).halfStep = [];                          % no half-step edge at 20 kHz (the gap is too narrow to define floor and shelf)
C(1).fitBand = [14 27];  C(1).anchor = 14;   C(1).gdSmooth = 1.5;
C(2).name = '100 kHz'; C(2).key = 'f100'; C(2).f0 = 100;  C(2).gateMs = 0.9;  C(2).burst = [66.7 133.3]; C(2).fplot = [30 145];
C(2).search = [30 140]; C(2).bridge = 7;   C(2).smooth = 2;    C(2).df = 0.25; C(2).fkeep = 200;
C(2).halfStep = struct('floor',[70 95],'shelf',[122 132],'pass',[35 45],'upSearch',[108 135],'loSearch',[45 70]);
C(2).fitBand = [40 140]; C(2).anchor = 40;   C(2).gdSmooth = 4;

% processing
gateSweep  = [0.6 0.8 1.0 1.5 Inf];   % ms; extra gates for the sensitivity, Inf = whole record
fadeFrac   = 0.15;           % fraction of the gate used for a half-cosine fade at its end 
% FFT length: every spectrum is computed on the SAME frequency grid 
C(1).dfFFT = 100; C(2).dfFFT = 25;   % Hz
C(1).snrBand = [19 22]; C(2).snrBand = [70 100];   % kHz: band inside the stop band used
nBoot      = 300;            % bootstrap resamples over the runs 
thr        = [-10.46 -20 -30];   % stop-band thresholds [dB]  (-10.46 dB = T 0.3)
cohMin     = 0.9;            % coherence below this: phase / group delay not trusted
gainMask   = -25;            % dB below the plain-rod peak: group delay / phase only where the plain rod is above this
poolByTag  = true;           % also pool the experiments that share a tag (e.g. the two Angled ones) into one curve
tfOrder20  = [8 8; 10 10];   % rational H(s) orders [numerator denominator], 20 kHz: row 1 plain rod, row 2 grooved/plain T(s)
tfOrder100 = [14 14; 12 12]; % same for 100 kHz (the received 100 kHz burst has three lumps, so it needs a higher order)
doFit      = true;           % fit and print the rational H(s)
doTF       = true;           % build tf / zpk objects (Control System Toolbox) from the fitted H(s) and T(s), print the equations
tfFile     = 'transfer_functions.txt';   % text file with every equation (also LaTeX) written to the current folder
tfBode     = true;           % one Bode plot per fitted transfer function (needs the toolbox)
figSize    = [0.62 0.72];    % figure width and height as a fraction of the screen (small laptop: keep these < 0.8)
rfont      = 'Times New Roman';
showFigs   = 1:9;            % which figures to draw (8 = stop-band range chart, 9 = stop-band table)
scopeStyle = false;          % Figure 1 drawn like the WaveForms scope window (dark screen, Ch1 yellow, Ch2 blue, volts per division); false = white background
showIndividual = false;      % Figure 5: also draw the single experiments (thin lines) behind the pooled curves
seatKHz    = 2;              % +/- kHz allowed for re-seating the rod (from the two 8 mm seatings and bench vs free-free), used in the reproducibility table
% ==========================================================================================================================

try, rng(1); catch, rand('state',1); randn('state',1); end %#ok<*RAND,*CTCH>
rods  = {'plain','5 mm','8 mm'};  rodCol = {[0 0 0],[0 0.35 0.85],[0.85 0.1 0.1]};
expLS = {'-','--',':','-.'};
expCol = {[0 0.45 0.74],[0.47 0.67 0.19],[0.85 0.33 0.10],[0.5 0.2 0.6]};
nE = numel(E);

% ---------------------------------------------------------------- load and process
fprintf('\n=== BRAGG_EXPERIMENT_compare ===\n');
D = cell(nE,2);        % D{e,c} = struct with plain / g5 / g8 sets
for e = 1:nE
    for c = 1:2
        key = C(c).key(2:end);  % '20' or '100'
        lists = {E(e).(['p' key]), E(e).(['g5_' key]), E(e).(['g8_' key])};
        if isempty(lists{1}) || (isempty(lists{2}) && isempty(lists{3}))
            if any(~cellfun(@isempty,lists)), fprintf('%s, %s: needs a plain list and at least one grooved list: skipped.\n',E(e).name,C(c).name); end
            continue
        end
        d = struct('ok',true,'R',{cell(1,3)},'S',{cell(1,3)},'n',[0 0 0]);
        for r = 1:3
            if isempty(lists{r}), d.R{r} = []; d.S{r} = []; continue; end
            d.R{r} = load_runs_(fullfile(dataRoot,E(e).folder),lists{r});
            d.n(r) = numel(d.R{r});
        end
        D{e,c} = d;
    end
end
% process with the main gate
for e = 1:nE
    for c = 1:2
        if isempty(D{e,c}), continue; end
        for r = 1:3
            if ~isempty(D{e,c}.R{r})
                D{e,c}.S{r} = proc_set_(D{e,c}.R{r},C(c),C(c).gateMs*1e-3,fadeFrac);
            end
        end
    end
end

% ---------------------------------------------------------------- 4/5/6 numbers
M = cell(nE,2,2);          % M{e,c,g} metrics of groove g (1 = 5 mm, 2 = 8 mm)
RC = cell(nE,2,2);         % ratio curves, bootstrap sigma
TAU0 = nan(nE,2);
for e = 1:nE
    for c = 1:2
        d = D{e,c}; if isempty(d), continue; end
        fg = (C(c).fplot(1):C(c).df:C(c).fplot(2))';
        for g = 1:2
            Sg = d.S{g+1}; Sp = d.S{1}; if isempty(Sg), continue; end
            [mm,bb,rr,gd,sg] = metrics_boot_(Sp,Sg,C(c),fg,thr,nBoot);
            M{e,c,g} = struct('m',mm,'s',bb,'fg',fg,'r',rr,'sig',sg,'gdB',gd);
        end
    end
end

% ---------------------------------------------------------------- printout
fprintf('\nRuns used (plain / 5 mm / 8 mm) and gate:\n');
for e = 1:nE
    for c = 1:2
        d = D{e,c}; if isempty(d), continue; end
        fprintf('  %-18s %-8s plain %d, 5 mm %d, 8 mm %d runs, gate %.2f ms (resolution about %.2f kHz), fs %.2f MS/s\n', ...
            E(e).name,C(c).name,d.n(1),d.n(2),d.n(3),C(c).gateMs,1/C(c).gateMs,d.S{1}.fs/1e6);
        if any(d.n(d.n>0) < 2), fprintf('     NOTE: a set with ONE run has no run-to-run scatter: its +/- below is only the resolution and the seating, not a real 2-sigma.\n'); end
    end
end
print_table_(E,C,M,thr,'GATE');
% pooled by tag
P = struct('tag',{},'c',{},'g',{},'fg',{},'r',{},'m',{},'s',{});
if poolByTag
    tags = unique({E.tag});
    for it = 1:numel(tags)
        idxe = find(strcmp({E.tag},tags{it}));
        for c = 1:2
            for g = 1:2
                have = idxe(arrayfun(@(e) ~isempty(M{e,c,g}),idxe));
                if isempty(have), continue; end          % a tag with ONE experiment (Flush) is carried through unchanged so it can be compared
                fg = M{have(1),c,g}.fg; R_ = zeros(numel(fg),numel(have)); Mm = zeros(numel(have),numel(M{have(1),c,g}.m)); Ss = Mm;
                for q = 1:numel(have), R_(:,q) = M{have(q),c,g}.r; Mm(q,:) = M{have(q),c,g}.m; Ss(q,:) = M{have(q),c,g}.s; end
                rp = mean(R_,2); mp = nanmean_(Mm); sp = 2*sqrt(sum((Ss/2).^2,1))/numel(have);
                if numel(have) > 1, sb = 2*nstd_(Mm)/sqrt(numel(have)); sp = sqrt(sp.^2 + sb.^2); else, sp = Ss; end
                P(end+1) = struct('tag',tags{it},'c',c,'g',g,'fg',fg,'r',rp,'m',mp,'s',sp); %#ok<AGROW>
            end
        end
    end
    if ~isempty(P)
        fprintf('\n--- POOLED by tag (mean of the experiments with the same tag, a lone experiment is shown as it is; +/- = bootstrap and between-experiment scatter combined) ---\n');
        for q = 1:numel(P)
            fprintf('  %-8s %-8s %s groove: %s\n',P(q).tag,C(P(q).c).name,gname_(P(q).g),line_(P(q).m,P(q).s,C(P(q).c),thr));
        end
    end
end
% differences between technologies
tags = unique({E.tag});
if numel(tags) >= 2 && ~isempty(P)
    fprintf('\n--- DIFFERENCE between pooled technologies (second minus first), design-frequency ratio and burst-band ratio [dB] ---\n');
    for c = 1:2
        for g = 1:2
            a = find([P.c]==c & [P.g]==g & strcmp({P.tag},tags{1})); b = find([P.c]==c & [P.g]==g & strcmp({P.tag},tags{2}));
            if isempty(a) || isempty(b), continue; end
            ia = numel(thr)*2+2+1+1+1;  % index of 'at f0' in the metric vector (see metrics_)
            dd = P(b).m(ia:ia+1) - P(a).m(ia:ia+1); ss = sqrt(P(b).s(ia:ia+1).^2 + P(a).s(ia:ia+1).^2);
            fprintf('  %-8s %s groove: at f0 %+5.1f +/- %.1f dB,  burst band %+5.1f +/- %.1f dB   (%s minus %s)\n',C(c).name,gname_(g),dd(1),ss(1),dd(2),ss(2),tags{2},tags{1});
        end
    end
end

% ---------------------------------------------------------------- noise-floor check and reproducibility table
fprintf('\n=== NOISE-FLOOR CHECK: signal in the stop-band frequencies above the receiver noise (before the burst arrives), dB ===\n');
fprintf('    (a grooved-rod signal near 0-6 dB is NOISE: the attenuation depth printed above is then only a LOWER LIMIT)\n');
for c = 1:2
    for e = 1:nE
        d = D{e,c}; if isempty(d), continue; end
        v = nan(1,3); vm = v;
        for r = 1:3, if ~isempty(d.R{r}), [v(r),vm(r)] = snr_(d.R{r},C(c).snrBand,C(c).gateMs*1e-3); end, end
        fl = '';
        for g = 1:2, if ~isnan(v(g+1)) && v(g+1) < 6, fl = [fl sprintf('  %s: AT THE NOISE FLOOR',gname_(g))]; end, end %#ok<AGROW>
        fprintf('  %-18s %-8s (%2.0f-%3.0f kHz)  plain %5.1f (min %5.1f) | 5 mm %5.1f (min %5.1f) | 8 mm %5.1f (min %5.1f)%s\n',E(e).name,C(c).name,C(c).snrBand,v(1),vm(1),v(2),vm(2),v(3),vm(3),fl);
    end
end
tagsU = unique({E.tag},'stable');
if numel(tagsU) >= 2 && ~isempty(P)
    fprintf('\n=== REPRODUCIBILITY: stop-band edges, %s vs %s (kHz).  +/- = re-seating %.1f kHz and resolution, both technologies combined ===\n',tagsU{1},tagsU{2},seatKHz);
    fprintf('    threshold: -10.46 dB at 20 kHz (all reach it), -30 dB at 100 kHz.   "inside" = difference smaller than the +/-\n');
    fprintf('    %-8s %-6s %-9s | %-15s | %-15s | %-8s %-8s | %-6s | %s\n','rods','groove','threshold',tagsU{1},tagsU{2},'d lower','d upper','+/-','verdict');
    for c = 1:2
        for g = 1:2
            a = find([P.c]==c & [P.g]==g & strcmp({P.tag},tagsU{1})); b = find([P.c]==c & [P.g]==g & strcmp({P.tag},tagsU{2}));
            if isempty(a) || isempty(b), continue; end
            if c == 1, ii = [1 2]; tn = '-10.46 dB'; else, ii = [5 6]; tn = '-30 dB'; end
            ea = P(a).m(ii); eb = P(b).m(ii); res = 0.5/C(c).gateMs; un = sqrt(2*(seatKHz^2 + res^2));
            dd = eb-ea; ok = abs(dd) <= un;
            fprintf('    %-8s %-6s %-9s | %6.1f-%-7.1f | %6.1f-%-7.1f | %+7.1f  %+7.1f | %5.1f  | %s / %s\n',C(c).name,gname_(g),tn,ea,eb,dd,un,vtxt_(ok(1)),vtxt_(ok(2)));
        end
    end
    for it = 1:numel(tagsU)
        ie = find(strcmp({E.tag},tagsU{it})); if numel(ie) < 2, continue; end
        fprintf('  Repeat check inside "%s" (%s vs %s, same transducers, different support): largest edge difference',tagsU{it},E(ie(1)).name,E(ie(2)).name);
        mx = 0; for c = 1:2, for g = 1:2, m1 = M{ie(1),c,g}; m2 = M{ie(2),c,g}; if isempty(m1) || isempty(m2), continue; end
                if c == 1, ii = [1 2]; else, ii = [5 6]; end, mx = max([mx, abs(m1.m(ii)-m2.m(ii))]); end, end
        fprintf(' %.1f kHz.\n',mx);
    end
end

% ---------------------------------------------------------------- transfer function, delay, dispersion, H(s)
DS = cell(nE,2);
for e = 1:nE
    for c = 1:2
        d = D{e,c}; if isempty(d), continue; end
        if c == 1, tfo = tfOrder20; else, tfo = tfOrder100; end
        DS{e,c} = disp_and_tf_(d,C(c),L,c0,rodR,cpRef.(C(c).key),gainMask,cohMin,tfo,doFit);
    end
end
fprintf('\n=== TRANSFER FUNCTION H(s) = Y(s)/X(s)  (s = j*2*pi*f; delay removed, then B(s)/A(s) in s_n = s/(2*pi*f0)) ===\n');
for e = 1:nE
    for c = 1:2
        s = DS{e,c}; if isempty(s), continue; end
        fprintf('\n%s, %s:   bulk delay (transducers + electronics) tau0 = %.1f us;  mean group delay of the plain rod %.1f us (L/cg theory %.1f us)\n', ...
            E(e).name,C(c).name,s.tau0*1e6,s.tauMean*1e6,s.tauTh*1e6);
        for q = 1:numel(s.fit)
            ft = s.fit{q}; if isempty(ft), continue; end
            fprintf('  %s:  H(s) = exp(-s*%.1f us) * B(s_n)/A(s_n),  fit rms error %.1f dB and %.0f deg over the usable part of %.0f-%.0f kHz\n',ft.label,ft.tau*1e6,ft.errdB,ft.errDeg,C(c).fitBand(1),C(c).fitBand(2));
            if ft.errdB > 3, fprintf('     NOTE: fit error above 3 dB: the response is not well described by this order; read the poles as indicative only.\n'); end
            fprintf('     B(s_n) = %s\n     A(s_n) = %s\n',coef_(ft.b),coef_(ft.a));
            fprintf('     poles [kHz]: %s\n',cplx_(ft.p*C(c).f0));
            fprintf('     zeros [kHz]: %s\n',cplx_(ft.z*C(c).f0));
        end
    end
end

if doTF && doFit
    TF = tf_objects_(DS,E,C,tfFile,rfont,tfBode); %#ok<NASGU>
end

fprintf('\n=== DISPERSION: group velocity [m/s] (plain rod as measured; grooved rods relative to the plain rod, so the transducer phase cancels) ===\n');
for e = 1:nE
    for c = 1:2
        s = DS{e,c}; if isempty(s), continue; end
        fprintf('  %-18s %-8s theory (plain rod): c_g %.0f m/s at %.0f kHz;  Brillouin edge pi/a = %.1f rad/m\n',E(e).name,C(c).name,interp1(s.fth,s.cgth,C(c).f0*1e3),C(c).f0,pi/latt.(C(c).key));
        for r = 1:3
            if isempty(s.cg{r}) || all(isnan(s.cg{r})), continue; end
            if r == 1 && abs(nanmedian_(s.cg{r})/interp1(s.fth,s.cgth,C(c).f0*1e3)-1) > 0.25
                fprintf('      WARNING: plain-rod group delay is not clean here (multi-lump received burst); the grooved-rod values are relative to it and remain usable.\n');
            end
            [cm,im] = min(s.cg{r}); fq = s.fg{r}(im)/1e3; fe = s.fg{r}(end)/1e3; ke = s.k{r}(end);
            fprintf('      %-6s measured c_g: median %.0f m/s, slowest %.0f m/s at %.1f kHz; usable up to %.1f kHz (k = %.1f rad/m)\n',rods{r},nanmedian_(s.cg{r}),cm,fq,fe,ke);
        end
    end
end
% ---------------------------------------------------------------- gate sweep
if ~isempty(gateSweep)
    fprintf('\n=== GATE SWEEP: does the answer depend on the window length? (ratio at f0 and in the burst band [dB]; half-step / -30 dB edges [kHz]) ===\n');
    for e = 1:nE
        for c = 1:2
            d = D{e,c}; if isempty(d), continue; end
            fg = (C(c).fplot(1):C(c).df:C(c).fplot(2))';
            for g = 1:2
                if isempty(d.R{g+1}), continue; end
                fprintf('  %-18s %-8s %s groove\n',E(e).name,C(c).name,gname_(g));
                for q = 1:numel(gateSweep)
                    Sp = proc_set_(d.R{1},C(c),gateSweep(q)*1e-3,fadeFrac);
                    Sg = proc_set_(d.R{g+1},C(c),gateSweep(q)*1e-3,fadeFrac);
                    mm = metrics_boot_(Sp,Sg,C(c),fg,thr,0);
                    if isinf(gateSweep(q)), gs = 'whole record'; else gs = sprintf('%.2f ms',gateSweep(q)); end
                    fprintf('     gate %-12s resolution %5.2f kHz:  %s\n',gs,1/min(gateSweep(q),max(d.R{1}(1).t)*1e3),line_(mm,nan(size(mm)),C(c),thr));
                end
            end
        end
    end
end

% ---------------------------------------------------------------- figures
scr = get(0,'ScreenSize'); if scr(3) <= 1, scr = [1 1 1600 900]; end   % headless fallback
fw = figSize(1)*scr(3); fh = figSize(2)*scr(4);
fpos = @(n) [scr(1)+(scr(3)-fw)/2, scr(2)+(scr(4)-fh)/2, fw, fh];   % every figure: same size, centred on the screen, stacked (open them from the Window menu / taskbar)
fn = 0;
cs = 1:2;
% -- 1 voltage-time: Ch1 (drive) and Ch2 (receiver) overlaid on one screen, as in WaveForms (each channel has its own V/div)
if any(showFigs==1)
    if scopeStyle, bg = [0.10 0.10 0.10]; fg = [0.85 0.85 0.85]; gc = [0.35 0.35 0.35]; c1 = [1 0.80 0.05]; c2 = [0.25 0.65 1];
    else, bg = [1 1 1]; fg = [0 0 0]; gc = [0.8 0.8 0.8]; c1 = [0.85 0.55 0]; c2 = [0 0.35 0.85]; end
    for c = cs
        fn = fn+1; figure('Name',['1 Voltage-time (scope view), ' C(c).name],'Position',fpos(fn),'Color',bg);
        act = find(~cellfun(@isempty,D(:,c)))';  na = numel(act); if na == 0, continue; end
        for q = 1:na
            e = act(q); d = D{e,c}; tl = tlim_(d,C(c));
            for r = 1:3
                if isempty(d.R{r}), continue; end
                subplot(3,na,(r-1)*na+q); hold on
                p1 = 0; p2 = 0;
                for i = 1:numel(d.R{r}), p1 = max(p1,max(abs(d.R{r}(i).x))); p2 = max(p2,max(abs(d.R{r}(i).y))); end
                v1 = nice125_(p1/3.6); v2 = nice125_(p2/3.6);
                for i = 1:numel(d.R{r}), plot(d.R{r}(i).t*1e3,d.R{r}(i).x/v1,'Color',c1,'LineWidth',0.8); end
                for i = 1:numel(d.R{r}), plot(d.R{r}(i).t*1e3,d.R{r}(i).y/v2,'Color',c2,'LineWidth',0.8); end
                plot(C(c).gateMs*[1 1],[-4 4],'-','Color',[0.6 0.6 0.6],'LineWidth',0.8);
                set(gca,'Color',bg,'XColor',fg,'YColor',fg,'YTick',-4:4,'YTickLabel',{},'XLim',tl,'YLim',[-4 4],'Box','on');
                grid on; try, set(gca,'GridColor',gc,'GridAlpha',1,'GridLineStyle','-'); catch, end %#ok<NOCOM>
                text(0.02,0.92,sprintf('Ch1  %s/div',vtxt2_(v1)),'Units','normalized','Color',c1,'FontSize',9,'FontWeight','bold');
                text(0.02,0.80,sprintf('Ch2  %s/div',vtxt2_(v2)),'Units','normalized','Color',c2,'FontSize',9,'FontWeight','bold');
                title(sprintf('%s rod, %s  (%d runs)',rods{r},E(e).name,numel(d.R{r})),'Color',fg,'FontSize',10);
                if r == 3, xlabel('Time after trigger (ms)','Color',fg); end
            end
        end
        fontall_(gcf,rfont);
    end
end
% -- 2 time-amplitude  (amplitude of the receiver signal against time, smoothed over 2 carrier cycles, relative to the plain-rod peak)
if any(showFigs==2)
    for c = cs
        fn = fn+1; figure('Name',['2 Time-amplitude, ' C(c).name],'Position',fpos(fn),'Color','w');
        act = find(~cellfun(@isempty,D(:,c)))'; na = numel(act); if na == 0, continue; end
        for q = 1:na
            e = act(q); d = D{e,c}; subplot(na,1,q); hold on; grid on
            nsm = max(1,round(2*d.R{1}(1).fs/(C(c).f0*1e3)));
            ev = cell(1,3); ref = 1;
            for r = 1:3
                if isempty(d.R{r}), continue; end
                ee = 0; for i = 1:numel(d.R{r}), ee = ee + env_(d.R{r}(i).y)/numel(d.R{r}); end
                ev{r} = movavg_(ee,nsm); if r == 1, ref = max(ev{1}(d.R{1}(1).t>=0)); end
            end
            hh = []; lg = {};
            for r = 1:3
                if isempty(ev{r}), continue; end
                hh(end+1) = plot(d.R{r}(1).t*1e3,ev{r}/ref,'Color',rodCol{r},'LineWidth',1.6); lg{end+1} = rods{r}; %#ok<AGROW>
            end
            plot(C(c).gateMs*[1 1],[0 5],'-','Color',[0.4 0.4 0.4],'LineWidth',1); text(C(c).gateMs,1.05,'  end of gate used for the spectra','FontSize',9);
            yt = 1.15; for r = 2:3, if ~isempty(ev{r}), yt = max(yt,1.1*max(ev{r})/ref); end, end
            ylim([0 yt]); xlim(tlim_(d,C(c))); ylabel('Amplitude (normalised)'); title([E(e).name ', ' C(c).name ': amplitude against time']);
            if q == 1, legend(hh,lg,'Location','northeast'); end
            if q == na, xlabel('Time after trigger (ms)'); end
        end
        fontall_(gcf,rfont);
    end
end
% -- 3 frequency-amplitude
if any(showFigs==3)
    for c = cs
        fn = fn+1; figure('Name',['3 Frequency-amplitude, ' C(c).name],'Position',fpos(fn),'Color','w');
        act = find(~cellfun(@isempty,D(:,c)))'; na = numel(act); if na == 0, continue; end
        for q = 1:na
            e = act(q); d = D{e,c}; subplot(na,1,q); hold on; grid on
            S = d.S{1}; hh = plot(S.f/1e3,10*log10(max(S.SxxN,1e-30)/max(S.SxxN)),'Color',[0.65 0.65 0.65],'LineWidth',1.2); lg = {'Drive (Ch1)'};
            for r = 1:3
                if isempty(d.S{r}), continue; end
                hh(end+1) = plot(d.S{r}.f/1e3,10*log10(max(d.S{r}.SyyN,1e-30)/max(d.S{1}.SyyN)),'Color',rodCol{r},'LineWidth',1.4); lg{end+1} = rods{r}; %#ok<AGROW>
            end
            xlim(C(c).fplot); ylim([-90 10]); ylabel('Amplitude (normalised, dB)'); title([E(e).name ', ' C(c).name ': amplitude against frequency (first pass, averaged over runs)']);
            if q == 1, legend(hh,lg,'Location','northeast'); end
            if q == na, xlabel('Frequency (kHz)'); end
        end
        fontall_(gcf,rfont);
    end
end
% -- 4 transfer function (amplitude of H = Ch2/Ch1 against frequency; the fitted H(s) of the plain rod is drawn when the fit is good)
if any(showFigs==4)
    for c = cs
        fn = fn+1; figure('Name',['4 Transfer function, ' C(c).name],'Position',fpos(fn),'Color','w');
        act = find(~cellfun(@isempty,D(:,c)))'; na = numel(act); if na == 0, continue; end
        ax = zeros(1,na); lo = inf; hi = -inf;
        for q = 1:na
            e = act(q); d = D{e,c}; s = DS{e,c};
            ax(q) = subplot(1,na,q); hold on; grid on; hh = []; lg = {};
            for r = 1:3
                if isempty(d.S{r}), continue; end
                gg = 10*log10(max(abs(d.S{r}.H1).^2,1e-30)); gg(~d.S{r}.valid) = nan;
                hh(end+1) = plot(d.S{r}.f/1e3,gg,'Color',rodCol{r},'LineWidth',1.3); lg{end+1} = rods{r}; %#ok<AGROW>
                inb = d.S{r}.f >= C(c).fplot(1)*1e3 & d.S{r}.f <= C(c).fplot(2)*1e3 & ~isnan(gg); if any(inb), lo = min(lo,min(gg(inb))); hi = max(hi,max(gg(inb))); end
            end
            nofit = '';
            for qq = 1:numel(s.fit)
                ft = s.fit{qq}; if isempty(ft) || ~ft.isPlain, continue; end
                if ft.errdB <= 3, hh(end+1) = plot(ft.f/1e3,ft.HdB,'-','Color',[0.2 0.7 0.2],'LineWidth',1); lg{end+1} = 'fitted H(s), plain'; %#ok<AGROW>
                else, nofit = sprintf('fitted H(s) not drawn (error %.1f dB, see command window)',ft.errdB); end
            end
            if ~isempty(nofit), text(0.03,0.04,nofit,'Units','normalized','FontSize',8); end
            xlim(C(c).fplot); xlabel('Frequency (kHz)'); if q == 1, ylabel('Transfer function |H| = Ch2 / Ch1 (dB)'); end
            title([E(e).name ', ' C(c).name]); if q == 1, legend(hh,lg,'Location','southwest','FontSize',8); end
        end
        for q = 1:na, set(ax(q),'YLim',[floor((lo-5)/10)*10, ceil((hi+5)/10)*10]); end
        fontall_(gcf,rfont);
    end
end
% -- 5 attenuation comparison: pooled technologies only (angled vs flush), one panel per rod and frequency
if any(showFigs==5)
    fn = fn+1; figure('Name','5 Attenuation: grooved / plain, Angled vs Flush','Position',fpos(fn),'Color','w');
    pn = 0; tagsU = unique({E.tag},'stable');
    for c = 1:2
        for g = 1:2
            pn = pn+1; subplot(2,2,pn); hold on; grid on; hh = []; lg = {};
            if showIndividual
                for e = 1:nE
                    m = M{e,c,g}; if isempty(m), continue; end
                    plot(m.fg,m.r,'-','Color',0.5*tagcol_(E(e).tag)+0.5,'LineWidth',0.8,'HandleVisibility','off');
                end
            end
            for it = 1:numel(tagsU)
                ip = find([P.c]==c & [P.g]==g & strcmp({P.tag},tagsU{it})); if isempty(ip), continue; end
                col = tagcol_(tagsU{it}); sg = P(ip).m*0; %#ok<NASGU>
                ie = find(strcmp({E.tag},tagsU{it}) & ~cellfun(@isempty,squeeze(M(:,c,g)))');
                if isempty(ie), continue; end
                nm = E(ie(1)).name; for q = 2:numel(ie), nm = [nm ' + ' strrep(E(ie(q)).name,[tagsU{it} ' '],'')]; end %#ok<AGROW>
                sgc = zeros(size(P(ip).r)); for q = 1:numel(ie), sgc = sgc + M{ie(q),c,g}.sig.^2; end; sgc = sqrt(sgc)/numel(ie);
                if any(sgc > 0)
                    fill([P(ip).fg; flipud(P(ip).fg)],[P(ip).r-sgc; flipud(P(ip).r+sgc)],col,'FaceAlpha',0.18,'EdgeColor','none','HandleVisibility','off');
                end
                hh(end+1) = plot(P(ip).fg,P(ip).r,'-','Color',col,'LineWidth',2); %#ok<AGROW>
                if numel(ie) > 1, lg{end+1} = sprintf('%s (pooled: %s)',tagsU{it},strrep(nm,[tagsU{it} ' '],'')); else, lg{end+1} = nm; end %#ok<AGROW>
            end
            for tt = [1 3], plot(C(c).fplot,[thr(tt) thr(tt)],'-','Color',[0.55 0.55 0.55],'LineWidth',0.8,'HandleVisibility','off'); text(C(c).fplot(2),thr(tt)+2,sprintf('%.4g dB ',thr(tt)),'HorizontalAlignment','right','FontSize',8,'Color',[0.35 0.35 0.35]); end
            xlim(C(c).fplot); ylim([-70 20]); xlabel('Frequency (kHz)'); ylabel('Grooved / plain (dB)'); title([C(c).name ' rods, ' gname_(g) ' groove']);
            if ~isempty(hh), if c == 1, lc = 'southwest'; else, lc = 'north'; end, legend(hh,lg,'Location',lc,'FontSize',8); end
        end
    end
    fontall_(gcf,rfont);
end
% -- 6 dispersion: frequency against wavenumber (left) next to the attenuation on the same frequency axis (right)
if any(showFigs==6)
    for c = cs
        act = find(~cellfun(@isempty,D(:,c)))'; if isempty(act), continue; end
        tagsC = unique({E(act).tag},'stable'); nt = numel(tagsC);
        fn = fn+1; figure('Name',['6 Dispersion, ' C(c).name],'Position',fpos(fn),'Color','w');
        a = latt.(C(c).key); kb = pi/a; fk = (C(c).fplot(1):C(c).df:C(c).fplot(2))';
        for it = 1:nt
            tg = tagsC{it}; ie = act(strcmp({E(act).tag},tg)); s1 = DS{ie(1),c};
            subplot(nt,2,2*it-1); hold on; grid on; hh = []; lg = {};
            plot(kb*[1 1],C(c).fplot,'-','Color',[0.55 0.55 0.55],'LineWidth',1,'HandleVisibility','off'); text(kb,C(c).fplot(1)+0.04*diff(C(c).fplot),' k = \pi/a','FontSize',9,'Color',[0.35 0.35 0.35]);
            hh(end+1) = plot(s1.kth,s1.fth/1e3,'-','Color',[0 0 0],'LineWidth',2); lg{end+1} = 'plain rod (theory)'; %#ok<AGROW>
            for g = 1:2
                K = nan(numel(fk),numel(ie));
                for j = 1:numel(ie)
                    sj = DS{ie(j),c}; if isempty(sj.k{g+1}), continue; end
                    K(:,j) = interp1(sj.fk{g+1}/1e3,sj.k{g+1},fk,'linear',NaN);
                end
                kp = nanmean_(K')'; ok = ~isnan(kp);
                if any(ok), hh(end+1) = plot(kp(ok),fk(ok),'-','Color',rodCol{g+1},'LineWidth',1.8); lg{end+1} = [gname_(g) ', measured']; end %#ok<AGROW>
                ip = find([P.c]==c & [P.g]==g & strcmp({P.tag},tg));
                if ~isempty(ip)
                    mm = P(ip).m; tn = {'-10.46','-20','-30'}; ti = 0;
                    for t3 = [3 2 1], if ~isnan(mm(2*t3-1)) && ~isnan(mm(2*t3)) && mm(2*t3) < C(c).search(2)-1, ti = t3; break; end, end
                    if ti > 0
                        xo = (g-1.5)*0.03*kb; hb = plot((kb+xo)*[1 1],[mm(2*ti-1) mm(2*ti)],'-','Color',rodCol{g+1},'LineWidth',6);
                        hh(end+1) = hb; lg{end+1} = sprintf('%s stop band (%s dB)',gname_(g),tn{ti}); %#ok<AGROW>
                    end
                end
            end
            xlabel('Wavenumber k (rad/m)'); ylabel('Frequency (kHz)'); ylim(C(c).fplot); xlim([0 1.08*max(s1.kth(s1.fth/1e3 <= C(c).fplot(2)))]);
            title([tg ': dispersion (f against k)']); legend(hh,lg,'Location','northwest','FontSize',8);
            subplot(nt,2,2*it); hold on; grid on; hh = []; lg = {};
            for g = 1:2
                ip = find([P.c]==c & [P.g]==g & strcmp({P.tag},tg)); if isempty(ip), continue; end
                hh(end+1) = plot(P(ip).r,P(ip).fg,'-','Color',rodCol{g+1},'LineWidth',1.8); lg{end+1} = [gname_(g) ' groove']; %#ok<AGROW>
            end
            for tt = [1 3], plot([thr(tt) thr(tt)],C(c).fplot,'-','Color',[0.55 0.55 0.55],'LineWidth',0.8,'HandleVisibility','off'); end
            xlim([-70 20]); ylim(C(c).fplot); xlabel('Grooved / plain (dB)'); ylabel('Frequency (kHz)'); title([tg ': attenuation at the same frequencies']);
            if ~isempty(hh), legend(hh,lg,'Location','southeast','FontSize',8); end
        end
        fontall_(gcf,rfont);
    end
end
% -- 7 summary bars
if any(showFigs==7)
    fn = fn+1; figure('Name','7 Attenuation summary','Position',fpos(fn),'Color','w');
    pn = 0;
    for c = 1:2
        pn = pn+1; subplot(1,2,pn); hold on; grid on; xt = {}; xi = 0;
        i0 = numel(thr)*2+2+1+1+1;
        for g = 1:2
            for e = 1:nE
                m = M{e,c,g}; if isempty(m), continue; end
                xi = xi+1; col = expCol{mod(e-1,4)+1};
                bar(xi-0.2,m.m(i0),0.35,'FaceColor',col); errorbar(xi-0.2,m.m(i0),m.s(i0),'k.');
                bar(xi+0.2,m.m(i0+1),0.35,'FaceColor',col*0.5+0.5); errorbar(xi+0.2,m.m(i0+1),m.s(i0+1),'k.');
                xt{end+1} = sprintf('%s\n%s',E(e).name,gname_(g)); %#ok<AGROW>
            end
        end
        set(gca,'XTick',1:xi,'XTickLabel',xt,'FontSize',8); ylabel('Grooved / plain (dB)'); title([C(c).name ': dark = at design frequency, light = whole burst band (error bars 2 sigma)']);
    end
    fontall_(gcf,rfont);
end
% -- 8 stop-band range chart: frequency on the VERTICAL axis with the same limits as Figure 6, so it can sit beside the dispersion / attenuation figure
if any(showFigs==8)
    tagsU = unique({E.tag},'stable');
    for c = cs
        ent = struct('g',{},'tag',{},'ip',{});
        for g = 1:2, for it = 1:numel(tagsU)
            ip = find([P.c]==c & [P.g]==g & strcmp({P.tag},tagsU{it})); if ~isempty(ip), ent(end+1) = struct('g',g,'tag',tagsU{it},'ip',ip); end %#ok<AGROW>
        end, end
        if isempty(ent), continue; end
        fn = fn+1; figure('Name',['8 Stop-band ranges, ' C(c).name],'Position',fpos(fn),'Color','w');
        hold on; grid on; unc = sqrt(seatKHz^2 + (0.5/C(c).gateMs)^2); lab = cell(1,numel(ent));
        if c == 1, tw = 1; tn = 2; wtxt = '-10.46 dB edges'; ntxt = '-20 dB edges'; else, tw = 3; tn = 0; wtxt = '-30 dB edges'; ntxt = 'half-step edges'; end
        for xi = 1:numel(ent)
            m = P(ent(xi).ip).m; col = tagcol_(ent(xi).tag); lab{xi} = sprintf('%s, %s',gname_(ent(xi).g),ent(xi).tag);
            lo = m(2*tw-1); hi = m(2*tw);
            if ~isnan(lo) && ~isnan(hi)
                op = hi >= C(c).search(2)-2*C(c).df; if op, hi = C(c).fplot(2); end
                fill(xi+0.32*[-1 1 1 -1],[lo lo hi hi],0.45*col+0.55,'EdgeColor',col,'LineWidth',1.2);
                plot(xi*[1 1],[lo-unc lo+unc],'k-','LineWidth',1.3); if ~op, plot(xi*[1 1],[hi-unc hi+unc],'k-','LineWidth',1.3); end
                text(xi,lo-unc-0.02*diff(C(c).fplot),sprintf('%.1f',lo),'HorizontalAlignment','center','VerticalAlignment','top','FontSize',9);
                if ~op, text(xi,hi+unc+0.02*diff(C(c).fplot),sprintf('%.1f',hi),'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',9);
                else, text(xi,hi-0.03*diff(C(c).fplot),'  no recovery','HorizontalAlignment','center','FontSize',8); end
            end
            if tn == 0, nlo = m(7); nhi = m(8); else, nlo = m(2*tn-1); nhi = m(2*tn); end
            if ~isnan(nlo) && ~isnan(nhi), fill(xi+0.10*[-1 1 1 -1],[nlo nlo nhi nhi],col,'EdgeColor','k','LineWidth',0.8); end
        end
        hl = zeros(1,numel(tagsU)); for it = 1:numel(tagsU), hl(it) = plot(NaN,NaN,'s','MarkerSize',10,'MarkerFaceColor',0.45*tagcol_(tagsU{it})+0.55,'MarkerEdgeColor',tagcol_(tagsU{it})); end
        hn = plot(NaN,NaN,'s','MarkerSize',6,'MarkerFaceColor',[0.3 0.3 0.3],'MarkerEdgeColor','k');
        lgt = cell(1,numel(tagsU)); for it = 1:numel(tagsU), lgt{it} = sprintf('%s: wide bar = %s',tagsU{it},wtxt); end
        legend([hl hn],[lgt {['dark narrow bar = ' ntxt]}],'Location','northwest');
        set(gca,'XTick',1:numel(ent),'XTickLabel',lab,'XLim',[0.4 numel(ent)+0.6],'YLim',C(c).fplot,'XGrid','off','YGrid','on');
        ylabel('Frequency (kHz)'); title(sprintf('%s rods: stop-band frequency range (wide bar = %s, dark narrow bar = %s, black whiskers = +/-%.1f kHz)',C(c).name,wtxt,ntxt,unc),'FontSize',9);
        fontall_(gcf,rfont);
    end
end
% -- 9 stop-band table (pop-up table; also written to stopband_ranges_table.csv)
if any(showFigs==9)
    [cols,dat] = stopband_rows_(E,C,M,P,thr,seatKHz);
    fn = fn+1; figure('Name','9 Stop-band ranges (table)','Position',fpos(fn),'Color','w');
    ok = false;
    if ~exist('OCTAVE_VERSION','builtin')
        try, uitable('Data',dat,'ColumnName',cols,'RowName',[],'Units','normalized','Position',[0.02 0.02 0.96 0.96],'FontSize',11,'ColumnWidth','auto'); ok = true; catch, ok = false; end %#ok<CTCH>
    end
    if ~ok
        axes('Position',[0 0 1 1],'Visible','off'); hold on; xlim([0 1]); ylim([0 1]);
        nr = size(dat,1); xc = [0.01 0.085 0.15 0.31 0.43 0.55 0.67 0.79 0.89]; rh = 0.9/(nr+2);
        title('Stop-band frequency ranges (kHz)','Visible','on');
        for j = 1:numel(cols), text(xc(j),0.95,cols{j},'FontWeight','bold','FontSize',10); end
        plot([0 1],[0.935 0.935],'k-');
        for i = 1:nr
            y = 0.935-i*rh; if i > 1 && ~strcmp(dat{i,1},dat{i-1,1}), plot([0 1],[y+rh*0.5 y+rh*0.5],'-','Color',[0.5 0.5 0.5]); end
            for j = 1:numel(cols), text(xc(j),y,dat{i,j},'FontSize',9); end
        end
    end
    fid = fopen('stopband_ranges_table.csv','w');
    if fid > 0, fprintf(fid,'%s\n',strjoin_c_(cols)); for i = 1:size(dat,1), fprintf(fid,'%s\n',strjoin_c_(dat(i,:))); end, fclose(fid); end
    fontall_(gcf,rfont);
end
hf = findall(0,'Type','figure'); nm = get(hf,'Name'); if ischar(nm), nm = {nm}; end
if ~strcmp(get(0,'defaultfigurevisible'),'off')
    for q = 1:numel(hf), if strncmp(nm{q},'1 ',2), figure(hf(q)); break; end, end
end   % leave Figure 1 on top
fprintf('\nDone. How to read it:  1-3 show the raw data in time and frequency;  4 is the transfer function H;  5 the attenuation (grooved / plain);\n');
fprintf('6 the dispersion;  7 the summary;  8 stop-band range chart;  9 stop-band table (also saved as stopband_ranges_table.csv).  The numbers above are the same as the figures.\n');
end   % main function

% ==========================================================================================================================
%% HELPER FUNCTIONS
function f = pick_(root,pats)
% all .csv under root (all sub-folders) whose relative path matches every pattern in pats ('~' in front = must not match)
f = {};
if ~exist(root,'dir'), return; end
all_ = listcsv_(root,'');
for i = 1:numel(all_)
    p = lower(strrep(all_{i},'\','/')); ok = true;
    for q = 1:numel(pats)
        pt = pats{q}; neg = ~isempty(pt) && pt(1) == '~'; if neg, pt = pt(2:end); end
        hit = ~isempty(regexp(p,lower(pt),'once'));
        if hit == neg, ok = false; break; end
    end
    if ok, f{end+1} = all_{i}; end %#ok<AGROW>
end
f = sort(f);
end

function out = listcsv_(root,sub)
out = {};
d = dir(fullfile(root,sub));
for i = 1:numel(d)
    nm = d(i).name;
    if d(i).isdir
        if ~strcmp(nm,'.') && ~strcmp(nm,'..'), out = [out, listcsv_(root,fullfile(sub,nm))]; end %#ok<AGROW>
    elseif ~isempty(regexp(nm,'\.csv$','once','ignorecase'))
        out{end+1} = fullfile(sub,nm); %#ok<AGROW>
    end
end
end

function R = load_runs_(folder,files)
R = struct('name',{},'t',{},'x',{},'y',{},'fs',{});
for i = 1:numel(files)
    fn = fullfile(folder,files{i});
    if ~exist(fn,'file'), error('File not found: %s',fn); end
    fid = fopen(fn,'r'); skip = 0;
    while true
        l = fgetl(fid); if ~ischar(l), break; end
        skip = skip+1; if strncmp(l,'Time',4), break; end
    end
    fclose(fid);
    a = dlmread(fn,',',skip,0);
    t = a(:,1); x = a(:,2); y = a(:,3);
    pre = t < 0;
    if nnz(pre) > 20, x = x - mean(x(pre)); y = y - mean(y(pre)); else, x = x - mean(x); y = y - mean(y); end
    R(i).name = files{i}; R(i).t = t; R(i).x = x; R(i).y = y; R(i).fs = 1/mean(diff(t)); %#ok<AGROW>
end
end

function S = proc_set_(R,cfg,gateS,fadeFrac)
nr = numel(R); fs = R(1).fs; df = cfg.dfFFT; nfft = round(fs/df); nk = floor(cfg.fkeep*1e3/df+1e-6)+1;   % nominal df: same grid for every set
for i = 2:nr, if abs(R(i).fs/fs-1) > 1e-3, error('Runs in one list have different sample rates (%s vs %s): put them in separate lists.',R(1).name,R(i).name); end, end
X = zeros(nk,nr); Y = zeros(nk,nr);
fgrid = (cfg.fplot(1):cfg.df:cfg.fplot(2))';
nsm = max(1,round(cfg.smooth*1e3/df));
f = (0:nk-1)'*df;
PxxG = zeros(numel(fgrid),nr); PyyG = PxxG;
for i = 1:nr
    idx = R(i).t >= 0 & R(i).t <= gateS; n = nnz(idx);
    w = ones(n,1); nf = max(2,round(fadeFrac*n)); w(end-nf+1:end) = 0.5*(1+cos(pi*(0:nf-1)'/nf));
    x = R(i).x(idx).*w; y = R(i).y(idx).*w;
    Xf = fft(x,nfft); Yf = fft(y,nfft); X(:,i) = Xf(1:nk); Y(:,i) = Yf(1:nk);
    PxxG(:,i) = interp1(f,movavg_(abs(X(:,i)).^2,nsm),fgrid*1e3,'linear',NaN);
    PyyG(:,i) = interp1(f,movavg_(abs(Y(:,i)).^2,nsm),fgrid*1e3,'linear',NaN);
end
Sxx = mean(abs(X).^2,2); Syy = mean(abs(Y).^2,2); Sxy = mean(conj(X).*Y,2);
S.f = f; S.fs = fs; S.SxxN = Sxx; S.SyyN = Syy; S.H1 = Sxy./max(Sxx,1e-300);
if nr > 1, S.coh = min(1,abs(Sxy).^2./max(Sxx.*Syy,1e-300)); else, S.coh = ones(nk,1); end
S.valid = Sxx > 10^(-3.5)*max(Sxx(f <= cfg.fplot(2)*1e3));      % drive has power here (the burst spectrum has nulls)
S.fg = fgrid; S.Pxx = PxxG; S.Pyy = PyyG; S.nr = nr; S.gate = gateS;
end

function [m,b,r,gdB,sig] = metrics_boot_(Sp,Sg,cfg,fg,thr,nBoot)
np = Sp.nr; ng = Sg.nr;
[m,r,gdB] = metrics_(Sp,Sg,1:np,1:ng,cfg,fg,thr);
if nBoot > 0
    mb = zeros(nBoot,numel(m)); rb = zeros(numel(fg),nBoot);
    for q = 1:nBoot
        ip = ceil(rand(1,np)*np); ig = ceil(rand(1,ng)*ng);
        [mb(q,:),rb(:,q)] = metrics_(Sp,Sg,ip,ig,cfg,fg,thr);
    end
    b = 2*nstd_(mb); sig = 2*nstd_(rb')';
else
    b = nan(size(m)); sig = zeros(size(r));
end
end

function [m,r,gdB] = metrics_(Sp,Sg,ip,ig,cfg,fg,thr)
Pxp = mean(Sp.Pxx(:,ip),2); Pyp = mean(Sp.Pyy(:,ip),2); Pxg = mean(Sg.Pxx(:,ig),2); Pyg = mean(Sg.Pyy(:,ig),2);
gp = 10*log10(Pyp./Pxp); gdB = 10*log10(Pyg./Pxg); r = gdB - gp;
v = fg >= cfg.search(1) & fg <= cfg.search(2); rr = r; rr(~v | isnan(r)) = inf; [deep,id] = min(rr); fdeep = fg(id);
m = [];
for q = 1:numel(thr)
    [lo,hi] = edge_(fg,r,thr(q),cfg.search,cfg.bridge,fdeep); m = [m lo hi]; %#ok<AGROW>
end
hsLo = nan; hsHi = nan;
if ~isempty(cfg.halfStep)
    h = cfg.halfStep; fl = nanmedian_(gdB(fg>=h.floor(1)&fg<=h.floor(2))); sh = nanmedian_(gdB(fg>=h.shelf(1)&fg<=h.shelf(2))); pb = nanmedian_(gdB(fg>=h.pass(1)&fg<=h.pass(2)));
    i1 = find(fg>=h.upSearch(1) & fg<=h.upSearch(2) & gdB > (fl+sh)/2,1,'first'); if ~isempty(i1), hsHi = fg(i1); end
    i2 = find(fg>=h.loSearch(1) & fg<=h.loSearch(2) & gdB < (fl+pb)/2,1,'first'); if ~isempty(i2), hsLo = fg(i2); end
end
m = [m hsLo hsHi deep fdeep];
hw = 1; if cfg.f0 > 50, hw = 5; end            % f0 +/- 1 kHz (20 kHz) or +/- 5 kHz (100 kHz)
w0 = abs(fg-cfg.f0) <= hw;
at0 = mean(r(w0));
wb = fg >= cfg.burst(1) & fg <= cfg.burst(2);
bur = 10*log10(sum(Pyg(wb))/sum(Pyp(wb)));
m = [m at0 bur];
end

function [lo,hi] = edge_(f,r,thr,srch,bridge,fdeep)
lo = nan; hi = nan;
b = f >= srch(1) & f <= srch(2) & r < thr; if ~any(b), return; end
d1 = find(diff([0;b(:);0])==1); d2 = find(diff([0;b(:);0])==-1)-1;
iv = [f(d1) f(d2)];
j = 1; out = iv(1,:);
for q = 2:size(iv,1)
    if iv(q,1) - out(end,2) <= bridge, out(end,2) = iv(q,2); else, out(end+1,:) = iv(q,:); end %#ok<AGROW>
end
k = find(out(:,1) <= fdeep & out(:,2) >= fdeep,1,'first'); if isempty(k), [~,k] = min(abs(mean(out,2)-fdeep)); end
lo = out(k,1); hi = out(k,2);
end

function s = line_(m,sd,cfg,thr)
% metric vector: [lo hi]*numel(thr), hsLo hsHi, deep fdeep, at0, burst
nt = numel(thr); str = '';
for q = 1:nt
    lo = m(2*q-1); hi = m(2*q);
    if isnan(lo), seg = 'none      ';
    else
        hs = sprintf('%.1f',hi); if hi >= cfg.search(2)-2*cfg.df, hs = ['>' sprintf('%.0f',cfg.search(2))]; end
        seg = sprintf('%.1f-%s',lo,hs);
    end
    str = [str sprintf('%4.0f dB: %-12s',thr(q),seg)]; %#ok<AGROW>
end
i0 = 2*nt;
if ~isnan(m(i0+1)) || ~isnan(m(i0+2)), str = [str sprintf('half-step %.1f-%.1f  ',m(i0+1),m(i0+2))]; end
if any(~isnan(sd)), pm = @(i) sprintf('+/-%.1f',sd(i)); else, pm = @(i) ''; end
str = [str sprintf('deepest %.1f dB at %.1f kHz %s  | at f0 %.1f %s  | burst %.1f %s dB',m(i0+3),m(i0+4),pm(i0+3),m(i0+5),pm(i0+5),m(i0+6),pm(i0+6))];
s = str;
end

function print_table_(E,C,M,thr,tit)
fprintf('\n=== ATTENUATION PER CASE (ratio grooved / plain, dB; frequencies in kHz; +/- = 2 sigma over the runs, ''>140'' = no recovery) ===\n');
for c = 1:2
    for g = 1:2
        any_ = false;
        for e = 1:numel(E), if ~isempty(M{e,c,g}), any_ = true; end, end
        if ~any_, continue; end
        fprintf('\n%s rods, %s groove  (%s gate %.2f ms)\n',C(c).name,gname_(g),tit,C(c).gateMs);
        for e = 1:numel(E)
            m = M{e,c,g}; if isempty(m), continue; end
            fprintf('  %-18s %s\n',E(e).name,line_(m.m,m.s,C(c),thr));
        end
    end
end
end

function col = tagcol_(tag)
if strcmpi(tag,'Angled'), col = [0.05 0.55 0.30]; elseif strcmpi(tag,'Flush'), col = [0.60 0.15 0.70]; else, col = [0.4 0.4 0.4]; end   % green = angled, purple = flush (kept apart from the black / blue / red rod colours)
end

function t = vtxt_(ok), if ok, t = 'inside'; else, t = 'OUTSIDE'; end, end

function [m,mn] = snr_(R,band,gateS)
% signal in the gate vs receiver noise before the burst (t < -20 us), same band, same window: dB, mean and minimum over the runs
v = nan(1,numel(R));
for i = 1:numel(R)
    t = R(i).t; fs = R(i).fs; y = R(i).y(:); pre = y(t < -2e-5); sig = y(t >= 0 & t <= gateS);
    if numel(pre) < 50 || numel(sig) < 50, continue; end
    v(i) = 10*log10(psdb_(sig,fs,band)/psdb_(pre-mean(pre),fs,band));
end
m = nanmean_(v(:)); mn = min(v(~isnan(v))); if isempty(mn), mn = nan; end
end

function p = psdb_(x,fs,band)
x = x(:); n = numel(x); w = 0.5-0.5*cos(2*pi*(0:n-1)'/max(n-1,1)); N = 2^16;
X = fft(x.*w,N); f = (0:N-1)'*fs/N; k = f >= band(1)*1e3 & f <= band(2)*1e3;
p = mean(abs(X(k)).^2)/sum(w.^2)/fs;
end

function v = nice125_(x)
% smallest 1-2-5 value >= x (volts per division)
if ~(x > 0), v = 1; return; end
e = floor(log10(x)); b = x/10^e; if b <= 1, m = 1; elseif b <= 2, m = 2; elseif b <= 5, m = 5; else, m = 10; end
v = m*10^e;
end

function t = vtxt2_(v)
if v >= 1, t = sprintf('%.3g V',v); elseif v >= 1e-3, t = sprintf('%.3g mV',v*1e3); else, t = sprintf('%.3g uV',v*1e6); end
end

function [cols,dat] = stopband_rows_(E,C,M,P,thr,seatKHz)
% one row per experiment and groove, plus the pooled technologies
cols = {'Rods','Groove','Set-up','Half-step edges','-30 dB edges','-20 dB edges','-10.46 dB edges','Width -30 dB','+/- kHz'};
dat = {}; tagsU = unique({E.tag},'stable');
for c = 1:2
    unc = sqrt(seatKHz^2 + (0.5/C(c).gateMs)^2);
    for g = 1:2
        for e = 1:numel(E)
            m = M{e,c,g}; if isempty(m), continue; end
            dat(end+1,:) = rowfun_(C(c),gname_(g),E(e).name,m.m,unc); %#ok<AGROW>
        end
        for it = 1:numel(tagsU)
            ip = find([P.c]==c & [P.g]==g & strcmp({P.tag},tagsU{it})); ie = find(strcmp({E.tag},tagsU{it}));
            if isempty(ip) || numel(ie) < 2, continue; end
            dat(end+1,:) = rowfun_(C(c),gname_(g),[tagsU{it} ' (pooled)'],P(ip).m,unc); %#ok<AGROW>
        end
    end
end
end

function r = rowfun_(cfg,g,name,m,unc)
w = '-'; if ~isnan(m(5)) && ~isnan(m(6)), w = sprintf('%.1f',m(6)-m(5)); end
r = {cfg.name,g,name,sbedge_(m(7),m(8),cfg),sbedge_(m(5),m(6),cfg),sbedge_(m(3),m(4),cfg),sbedge_(m(1),m(2),cfg),w,sprintf('%.1f',unc)};
end

function t = sbedge_(lo,hi,cfg)
if isnan(lo) || isnan(hi), t = '-'; return; end
hs = sprintf('%.1f',hi); if hi >= cfg.search(2)-2*cfg.df, hs = ['>' sprintf('%.0f',cfg.search(2))]; end
t = sprintf('%.1f - %s',lo,hs);
end

function s = strjoin_c_(c), s = c{1}; for q = 2:numel(c), s = [s ',' c{q}]; end, end

function s = gname_(g), if g == 1, s = '5 mm'; else, s = '8 mm'; end, end

function x = movavg_(x,n)
if n <= 1, return; end
x = conv(x(:),ones(n,1)/n,'same');
end

function s = nstd_(M)
s = zeros(1,size(M,2));
for j = 1:size(M,2), v = M(:,j); v = v(~isnan(v)); if numel(v) > 1, s(j) = std(v); end, end
end

function m = nanmean_(M), m = zeros(1,size(M,2)); for j = 1:size(M,2), v = M(:,j); v = v(~isnan(v)); if isempty(v), m(j) = nan; else, m(j) = mean(v); end, end, end

function m = nanmedian_(v), v = v(~isnan(v)); if isempty(v), m = nan; else, m = median(v); end, end

function e = env_(x)
x = x(:); n = numel(x); X = fft(x); h = zeros(n,1);
if mod(n,2) == 0, h([1 n/2+1]) = 1; h(2:n/2) = 2; else, h(1) = 1; h(2:(n+1)/2) = 2; end
e = abs(ifft(X.*h));
end

function tl = tlim_(d,cfg)
tl = [-0.05 max(2.2,2.2*cfg.gateMs)]; t = d.R{1}(1).t*1e3; tl(2) = min(tl(2),max(t));
end

function fontall_(h,fnt)
a = findall(h,'-property','FontName'); try, set(a,'FontName',fnt); catch, end
end

function s = strjoin_(c), s = c{1}; for q = 2:numel(c), s = [s ' / ' c{q}]; end, end

function s = coef_(c)
s = sprintf('%.4g ',c(:).');
end

function s = cplx_(z)
if isempty(z), s = '(none)'; return; end
z = z(:); s = '';
for q = 1:numel(z)
    if abs(imag(z(q))) < 1e-9*max(1,abs(z(q))), s = [s sprintf('%.2f; ',real(z(q)))]; %#ok<AGROW>
    else, s = [s sprintf('%.2f%+.2fj; ',real(z(q)),imag(z(q)))]; end %#ok<AGROW>
end
end

function out = disp_and_tf_(d,cfg,L,c0,rodR,cpRef,gainMask,cohMin,tfOrder,doFit)
% group delay, group velocity, wavenumber and rational H(s) for plain and grooved sets of ONE experiment / frequency case
nu = 0.29; %#ok<NASGU>
kap = (1-cpRef/c0)/(cfg.f0*1e3)^2;             % c_p(f) = c0 (1 - kap f^2), matched to the Pochhammer value at f0
fth = (cfg.fplot(1):0.1:cfg.fplot(2))'*1e3;
cp = c0*(1-kap*fth.^2); kth = 2*pi*fth./cp;
cgth = 1./gradient(kth,2*pi*fth);              % group velocity from dk/domega
out = struct('fth',fth,'kth',kth,'cgth',cgth,'fit',{cell(1,2)},'k',{cell(1,3)},'fk',{cell(1,3)},'fg',{cell(1,3)},'cg',{cell(1,3)},'tau0',nan,'tauMean',nan,'tauTh',nan);
Sp = d.S{1}; f = Sp.f; df = f(2)-f(1);
gdw = max(1,round(cfg.gdSmooth*1e3/df));
gainP = 10*log10(abs(Sp.H1).^2); gainP(~Sp.valid) = -300; band = f >= cfg.fitBand(1)*1e3 & f <= cfg.fitBand(2)*1e3;
gmax = max(gainP(band)); ok = band & gainP > gmax+gainMask & Sp.coh >= cohMin;
tauP = gdelay_(Sp.H1,df,gdw);
cgT = interp1(fth,cgth,f,'linear','extrap');
okc = ok & gainP > gmax-10;                     % calibration: strongest part of the passband
tau0 = median(tauP(okc) - L./cgT(okc));
out.tau0 = tau0; out.tauMean = sum(tauP(ok).*abs(Sp.H1(ok)).^2)/sum(abs(Sp.H1(ok)).^2);
out.tauTh = mean(L./cgT(ok));
if tau0 < 0 || tau0 > 200e-6, fprintf('  WARNING: calibrated bulk delay %.0f us looks odd (check rod length L, gate, trigger).\n',tau0*1e6); end
kthAt = @(ff) 2*pi*ff./(c0*(1-kap*ff.^2));
kP = nan(size(f)); tauPf = tauP;           % plain-rod measured wavenumber on the native grid (filled below)
for r = 1:3
    S = d.S{r}; if isempty(S), continue; end
    tau = gdelay_(S.H1,df,gdw); g = 10*log10(abs(S.H1).^2); g(~S.valid) = -300;
    msk = f >= cfg.anchor*1e3 & f <= cfg.fitBand(2)*1e3 & g > gmax+gainMask & S.coh >= cohMin;
    i0 = find(msk,1,'first'); if isempty(i0), continue; end
    j = i0; while j < numel(f) && msk(j+1), j = j+1; end      % contiguous passband from the anchor
    ii = i0:j; ka = kthAt(f(i0));
    kraw = ka + 2*pi/L*cumtrapz(f(ii),tau(ii)-tau0);
    if r == 1
        cgm = L./max(tau(ii)-tau0,1e-9);                       % plain rod: as measured (includes the transducer phase response)
        k = kraw; kP(ii) = kraw;
    else
        % grooved rods: only the CHANGE relative to the plain rod is trusted (the transducer phase cancels), added to theory
        okp = ~isnan(kP(ii)); k = nan(size(kraw)); k(okp) = kthAt(f(ii(okp))) + (kraw(okp) - kP(ii(okp)));
        trel = tau(ii) - tauP(ii) + L./interp1(fth,cgth,f(ii),'linear','extrap');
        cgm = L./max(trel,1e-9);
    end
    cgm(cgm > 8000 | cgm < 200) = nan;
    out.k{r} = k; out.fk{r} = f(ii); out.fg{r} = f(ii); out.cg{r} = cgm;
end
% rational fits
out.fit = cell(1,2);
if doFit && (~isempty(d.S{2}) || ~isempty(d.S{3}))
    w = 2*pi*f; wn = 2*pi*cfg.f0*1e3;
    tauF = out.tauMean;
    out.fit{1} = fitone_(w(ok)/wn,Sp.H1(ok),ones(nnz(ok),1),tfOrder(1,:),tauF+(-80:10:20)*1e-6,'plain rod H(s)',wn,f(ok),true);
    gsel = find(~cellfun(@isempty,d.S(2:3)),1,'first')+1;
    Sg = d.S{gsel}; T = Sg.H1./Sp.H1; okT = band & gainP > gmax+gainMask & Sp.coh >= cohMin & Sg.valid;
    gG = 10*log10(abs(Sg.H1).^2); nz = f > 0.8*cfg.fkeep*1e3; noiseG = median(gG(nz));
    if cfg.f0 > 50, okT = okT & gG > noiseG+12; end   % 100 kHz: drop frequencies where the grooved rod is at the receiver noise floor
    if nnz(okT) > 20
        out.fit{2} = fitone_(w(okT)/wn,T(okT),ones(nnz(okT),1),tfOrder(2,:),(-40:10:40)*1e-6,sprintf('grooved(%s)/plain T(s)',gname_(gsel-1)),wn,f(okT),false);
    end
end
end

function tau = gdelay_(H,df,nw)
P = H(2:end).*conj(H(1:end-1)); P = [P; P(end)];
P = conv(P,ones(nw,1)/nw,'same');
tau = -angle(P)/(2*pi*df);
end

function ft = fitone_(sn,H0,wt,ord,tauList,label,wn,f,isPlain)
% Levi / Sanathanan-Koerner least-squares fit of H(s) = B(s)/A(s) (s normalised by wn) to H0 after removing a delay exp(-s*tau);
% tau is chosen from tauList as the value giving the smallest relative (dB) error.  Relative weighting: every frequency counts equally in dB.
nb = ord(1); na = ord(2); sn = sn(:); H0 = H0(:); s = 1j*sn; best = [];
for tau = tauList(:).'
    H = H0.*exp(1j*sn*wn*tau); W = wt(:)./max(abs(H),1e-12*max(abs(H)));
    Aw = ones(size(sn));
    for it = 1:10
        Bm = zeros(numel(sn),nb+1); Am = zeros(numel(sn),na);
        for q = 0:nb, Bm(:,q+1) = s.^q; end
        for q = 1:na, Am(:,q) = -H.*(s.^q); end
        Mx = [Bm Am].*repmat(W./Aw,1,nb+1+na); yv = H.*W./Aw;
        th = [real(Mx); imag(Mx)]\[real(yv); imag(yv)]; b = th(1:nb+1); a = [1; th(nb+2:end)];
        Aw = abs(polyval(flipud(a),s)); Aw(Aw < 1e-6) = 1e-6;
    end
    p = roots(flipud(a)); u = real(p) > 0; p(u) = -real(p(u)) + 1j*imag(p(u));    % reflect unstable poles
    a = real(poly(p)); a = a(:)/a(end); a = flipud(a);                             % ascending powers, a(1) = 1
    Am2 = zeros(numel(sn),1); for q = 0:na, Am2 = Am2 + a(q+1)*s.^q; end
    Bm = zeros(numel(sn),nb+1); for q = 0:nb, Bm(:,q+1) = s.^q; end
    Mx = Bm.*repmat(W,1,nb+1); yv = H.*Am2.*W; b = [real(Mx); imag(Mx)]\[real(yv); imag(yv)];
    Hf = (Bm*b)./Am2;
    ed = sqrt(mean((20*log10(abs(Hf)./abs(H))).^2)); eg = sqrt(mean((angle(Hf./H)*180/pi).^2));
    if isempty(best) || ed < best.ed
        best = struct('ed',ed,'eg',eg,'b',b,'a',a,'p',p,'Hf',Hf,'tau',tau);
    end
end
z = roots(flipud(best.b));
ft.label = label; ft.b = best.b; ft.a = best.a; ft.p = best.p; ft.z = z; ft.tau = best.tau; ft.isPlain = isPlain; ft.f = f;
ft.HdB = 10*log10(abs(best.Hf).^2); ft.errdB = best.ed; ft.errDeg = best.eg;
end

% ======================================================================================================================
%  TRANSFER-FUNCTION OBJECTS  (added: turns the fitted H(s) and T(s) into tf / zpk models and prints the equations)
% ======================================================================================================================
function TF = tf_objects_(DS,E,C,fname,rfont,doBode)
% For every experiment / frequency case / fitted function this builds
%   Gn : tf  in the NORMALISED variable  s_n = s/(2*pi*f0)   (small, readable coefficients; delay in units of 1/(2*pi*f0))
%   Gs : zpk in the real Laplace variable s [rad/s]            (delay in seconds)
% and prints the equations.  The results are returned as the struct TF (also placed in the base workspace as TF).
% Without the Control System Toolbox the equations are still printed and written to the text file; only the objects are skipped.
hasCST = exist('tf','file') ~= 0 && exist('zpk','file') ~= 0;
TF = struct();
fid = -1; try, fid = fopen(fname,'w'); catch, end %#ok<*CTCH>
say_(fid,'\n=== FITTED TRANSFER FUNCTIONS ===\n');
say_(fid,'Each model is exp(-s*tau) times the fraction shown (Hn for the plain rod, Tn for the grooved/plain ratio), in s_n = s/(2*pi*f0).\n');
if ~hasCST, say_(fid,'(Control System Toolbox not found: fractions printed by the script, no tf objects stored.)\n'); end
for e = 1:numel(E)
    for c = 1:2
        s = DS{e,c}; if isempty(s), continue; end
        for q = 1:numel(s.fit)
            ft = s.fit{q}; if isempty(ft), continue; end
            f0 = C(c).f0*1e3; wn = 2*pi*f0;
            b = ft.b(:).'; a = ft.a(:).';                     % ascending powers of s_n, a(1) = 1
            numN = fliplr(b); denN = fliplr(a);               % descending powers, the order tf() expects
            while numel(numN) > 1 && abs(numN(1)) < 1e-12*max(abs(numN)), numN(1) = []; end
            nn = numel(numN)-1; nd = numel(denN)-1;
            z = ft.z(:); p = ft.p(:);
            kS = (numN(1)/denN(1)) * wn^(nd-nn);              % gain of the zpk form in s [rad/s]
            if ft.isPlain, kind = 'H_plain'; else, tk = regexp(ft.label,'\((.*?)\)','tokens','once'); kind = ['T_' tk{1}]; end
            fld = regexprep(sprintf('%s_%s_%s',E(e).name,C(c).key,kind),'[^A-Za-z0-9_]','_');
            tauN = ft.tau*wn;                                  % the same delay expressed in s_n time units
            % ---- check: rebuilt model against the fit used by the script (magnitude, dB), independent of the toolbox
            sn = 1j*2*pi*ft.f(:)/wn;  Hn = polyval(numN,sn)./polyval(denN,sn);
            Hz = kS*prod(bsxfun(@minus,1j*2*pi*ft.f(:).',(z*wn)),1).' ./ prod(bsxfun(@minus,1j*2*pi*ft.f(:).',(p*wn)),1).';
            dN = max(abs(20*log10(abs(Hn)) - ft.HdB(:)));          % ft.HdB = 10*log10|H|^2 = 20*log10|H|
            dZ = max(abs(20*log10(abs(Hz)) - ft.HdB(:)));
            ttl = sprintf('%s, %s:  %s',E(e).name,C(c).name,ft.label);
            if ft.isPlain, gname = 'Hn'; else, gname = 'Tn'; end      % name shown in the display: H(s_n) or T(s_n) without the delay
            say_(fid,'\n%s\n%s\n',ttl,repmat('-',1,numel(ttl)));
            if ft.isPlain, ex = 'H(s) = Y(s)/X(s)'; else, ex = 'T(s) = H_grooved(s)/H_plain(s)'; end
            say_(fid,'%s = exp(-s*%.2f us) * %s(s_n),   s_n = s/(2*pi*%.0f kHz)   [fit rms error %.2f dB]\n',ex,ft.tau*1e6,gname,f0/1e3,ft.errdB);
            if ft.errdB > 3, say_(fid,'NOTE: fit error above 3 dB, treat the poles and zeros as indicative only.\n'); end
            % ---- the fraction B/A exactly as MATLAB prints a tf object (own printer when the toolbox is missing)
            Gd = [];
            if hasCST
                try, Gd = tf(numN,denN); catch, Gd = []; end %#ok<NASGU>
            end
            if hasCST && ~isempty(Gd)
                eval(sprintf('%s = Gd;',gname)); frac = evalc(gname);
            else
                frac = frac_str_(numN,denN,gname);
            end
            say_(fid,'%s',frac);
            % ---- details go to the text file only
            sayf_(fid,'delay tau = %.4f us (= %.4f in s_n units);  orders: numerator %d, denominator %d\n',ft.tau*1e6,tauN,nn,nd);
            sayf_(fid,'zpk in s [rad/s]:  gain %.5g;  zeros %s;  poles %s\n',kS,cplx_(z*wn),cplx_(p*wn));
            sayf_(fid,'poles [kHz]: %s\nzeros [kHz]: %s\n',cplx_(p*f0/1e3),cplx_(z*f0/1e3));
            sayf_(fid,'LaTeX:  H(s)=e^{-%.2f\\times10^{-6}\\,s}\\,\\frac{%s}{%s},\\quad s_n=\\frac{s}{2\\pi\\cdot %.0f}\n',ft.tau*1e6,tex_(numN),tex_(denN),f0);
            if max(dN,dZ) > 1e-6, say_(fid,'WARNING: rebuilt model differs from the fit by %.2g dB (tf) / %.2g dB (zpk).\n',dN,dZ); end
            TF.(fld) = struct('label',ft.label,'case',[E(e).name ', ' C(c).name],'f0',f0,'tau',ft.tau,'b',b,'a',a,'num',numN,'den',denN, ...
                'zpkGain',kS,'zeros',z*wn,'poles',p*wn,'errdB',ft.errdB,'errDeg',ft.errDeg,'Gn',[],'Gs',[]);
            if hasCST
                try
                    Gn = tf(numN,denN,'IODelay',tauN);                  % in s_n, with the delay
                    Gs = zpk(z*wn,p*wn,kS,'IODelay',ft.tau);            % in s [rad/s], with the delay
                    TF.(fld).Gn = Gn; TF.(fld).Gs = Gs;
                    wv = 2*pi*ft.f(:);                                   % the measured band, rad/s
                    dT = max(abs(20*log10(abs(squeeze(freqresp(Gs,wv)))) - ft.HdB(:)));
                    if dT > 1e-6, say_(fid,'WARNING: freqresp of the zpk object differs from the fit by %.2g dB.\n',dT); end
                    if doBode
                        figure('Name',['Bode ' fld],'Color','w'); opt = bodeoptions; opt.FreqUnits = 'Hz'; opt.FreqScale = 'linear';
                        bodeplot(Gs,wv,opt); title(strrep(ft.label,'_','\_')); set(findall(gcf,'-property','FontName'),'FontName',rfont);
                    end
                catch ME
                    say_(fid,'(tf / zpk object could not be built: %s)\n',ME.message);
                end
            end
        end
    end
end
if fid > 0, fclose(fid); fprintf('Equations written to %s\n',fname); end
try
    assignin('base','TF',TF);
    fn = fieldnames(TF);
    if ~isempty(fn)
        fprintf('Models are in the workspace variable TF (fields: %s)\n',strjoin_c_(fn.'));
    end
catch
end
end

function say_(fid,varargin)
fprintf(1,varargin{:}); if fid > 0, fprintf(fid,varargin{:}); end
end

function sayf_(fid,varargin)
% text file only
if fid > 0, fprintf(fid,varargin{:}); end
end

function s = frac_str_(num,den,nm)
% numerator / dashes / denominator, laid out like MATLAB's own tf display (used only without the Control System Toolbox)
n = poly_mat_(num); d = poly_mat_(den); w = max(numel(n),numel(d));
pad = @(x) [repmat(' ',1,floor((w-numel(x))/2)) x];
s = sprintf('\n%s =\n \n  %s\n  %s\n  %s\n \nContinuous-time transfer function.\n\n',nm,pad(n),repmat('-',1,w),pad(d));
end

function s = poly_mat_(c)
% descending-power coefficients -> "c2 s^2 + c1 s + c0" (coefficients to 4 significant digits)
c = c(:).'; N = numel(c)-1; s = ''; first = true;
for q = 0:N
    k = c(q+1); pw = N-q; if k == 0 && ~(N == 0), continue; end
    if first, sg = ''; if k < 0, sg = '-'; end
    else, sg = ' + '; if k < 0, sg = ' - '; end, end
    ak = abs(k);
    if pw == 0, body = sprintf('%.4g',ak);
    else
        if abs(ak-1) < 5e-5, cs = ''; else, cs = [sprintf('%.4g',ak) ' ']; end
        if pw == 1, body = [cs 's']; else, body = sprintf('%ss^%d',cs,pw); end
    end
    s = [s sg body]; first = false; %#ok<AGROW>
end
if isempty(s), s = '0'; end
end

function s = poly_str_(c,v)
% descending-power coefficient vector -> text  "c0 + c1*s_n + ..."  (printed in ascending powers)
c = fliplr(c(:).'); s = '';
for q = 0:numel(c)-1
    if q == 0, t = sprintf('%.5g',c(1)); elseif q == 1, t = sprintf('%+.5g*%s',c(2),v); else, t = sprintf('%+.5g*%s^%d',c(q+1),v,q); end
    s = [s ' ' t]; %#ok<AGROW>
end
s = strtrim(s);
end

function s = tex_(c)
c = fliplr(c(:).'); s = '';
for q = 0:numel(c)-1
    if q == 0, t = sprintf('%.4g',c(1)); elseif q == 1, t = sprintf('%+.4g\\,s_n',c(2)); else, t = sprintf('%+.4g\\,s_n^{%d}',c(q+1),q); end
    s = [s t]; %#ok<AGROW>
end
end
