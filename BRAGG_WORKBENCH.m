%% BRAGG_WORKBENCH.m   BRAGG ROD, WORKBENCH PROBE EXPORTS:  which frequencies [kHz] does the rod block?
%  TWO JOBS (switch  task  in the block below):
%    task = 'transfer' : plain + grooved far-probe files -> transfer function, stop bands in kHz, Bloch theory, scattered wave   (as before)
%    task = 'echo'     : ONE plain-rod probe file -> size and sign of the echo from the far end 
%  WHAT YOU GET: the burst and its Fourier transform, the TRANSFER FUNCTION T(f) = |grooved| / |plain| at the far probe,
%  the STOP BAND(S) in kHz
% CHANGE ONLY THE BLOCK UNDER "CHANGE THIS BLOCK".

clear;   %#ok<*UNRCH>
close all;
clc
%% example:
% task    = 'transfer';   
% material = 'steel';  
% ends    = 'absorbing';  
% fcase   = 100;        
% wmm     = 8;         
% agroove = [];        
% ncyc    = 3;         
% thr     = 0.3;      
% xfar    = 0.99;   
% colu    = 2;        
% names   = {'plain_P3.txt','grooved_P3.txt'};          % file names
% names1  = {'plain_P1.txt','grooved_P1.txt'};          % optional (only used when both exist)
% x1      = 0.20;      % position of P1 [m]
% plotdir = '';        
% % --- only used when task = 'echo' ---
% fecho   = 'abs_100k_plain_uP1.txt';   %probe export of the plain rod 
% fecho0  = '';                         
% xecho   = 0.20;                       %  position of that probe along the rod [m]

task     = 'echo';
material = 'steel';
ends     = 'absorbing';      % change to 'absorbing' if these exports are the dashpot runs
fcase    = 100;
wmm      = 5;
agroove  = [];
ncyc     = 3;
thr      = 0.3;
xfar     = 0.99;        % use 1.0 if the far probe turns out to be the end-face probe (up4)
colu     = 2;
names    = {'steel_abs_100k_plain_up3.txt','steel_abs_100k_5mm_up3.txt'};
names1   = {'steel_abs_100k_plain_up1.txt','steel_abs_100k_5mm_up1.txt'};
x1       = 0.20;
plotdir  = '';
fecho    = 'steel_abs_100k_plain_up1.txt';
fecho0   = '';
xecho    = 0.20;

task = lower(strtrim(task));
material = lower(strtrim(material));
ends = lower(strtrim(ends));
fcase = round(fcase);
% Name of the output folder (automatic unless you typed one above).
if isempty(plotdir)
    if strcmp(task,'echo')
        plotdir = 'plots_BRAGG_WB_echo';
    else
        plotdir = sprintf('plots_BRAGG_WB_%s_%dk_w%dmm',ends,fcase,wmm);
    end
end
% task = 'echo': only check the reflection coefficient of ONE plain rod and stop. Nothing below this block is run in that case.
if strcmp(task,'echo')
    echo_check_(fecho,fecho0,xecho,fcase,colu,plotdir);
    return
end
if ~strcmp(task,'transfer')
    error('task must be ''transfer'' or ''echo''');
end
% Material of the rod: E [Pa], rho [kg/m3] and c0 = sqrt(E/rho) = the 1-D bar speed [m/s]. c0 places the time windows below.
% (the old aluminium runs used the rounded value 5052 m/s, so that value is kept for 'aluminium')
[Emat,rhomat,c0] = material_(material);
if strcmpi(material,'aluminium') || strcmpi(material,'aluminum')
    c0 = 5052;
end
fprintf('Material: %s (E = %.1f GPa, rho = %.0f kg/m3), bar speed c0 = %.0f m/s\n',material,Emat/1e9,rhomat,c0);
% FC = design (burst centre) frequency in Hz.  L = rod length.  wg = groove width in metres.  vgate = speed used to place the time windows.
FC = fcase*1e3;
L = 1.0;
wg = wmm*1e-3;
if fcase == 100
    vgate = 0.85*c0;
else
    vgate = c0;
end
% a = groove spacing (lattice constant) in metres. The grooves are already machined, so a does NOT depend on the material.
if isempty(agroove)
    if fcase == 20
        a = 113.75e-3;
    else
        a = 23.75e-3;
    end
else
    a = agroove*1e-3;
end
band = [0.2 1.8]*FC;
if ~exist(plotdir,'dir')
    mkdir(plotdir);
end
sv = @(n) save_fig(fullfile(plotdir,n));
% Read the two probe exports: t = time, up / ug = displacement at the far probe of the plain / grooved rod
% (the grooved rod is re-sampled onto the times of the plain rod).
[t,up] = read_wb_table(names{1},colu);
[t2,ug] = read_wb_table(names{2},colu);
t = t(:);
ug = interp1(t2,ug,t,'linear',0);
up = up(:);
ug = ug(:);
dt = mean(diff(t));
fprintf('a = %.2f mm, groove width %d mm, burst %d cycles at %.0f kHz, %d points, dt = %.3f us\n',a*1e3,wmm,ncyc,FC/1e3,numel(t),dt*1e6);
%%  the burst 
% The tone burst: a sine with a raised-cosine (Hann) envelope. Sb = its Fourier transform (which frequencies it contains).
dtb = 1/(200*FC);
tb = (0:dtb:ncyc/FC)';
Fb = 0.5*(1-cos(2*pi*FC*tb/ncyc)).*sin(2*pi*FC*tb);
nb = 2^18;
fb = (0:nb/2)'/(nb*dtb);
Sb = abs(fft(Fb,nb))*dtb;
Sb = Sb(1:nb/2+1);
Sb = Sb/max(Sb);
[~,ib] = max(Sb);
a6 = fb(find(Sb(1:ib) < 0.5,1,'last')+1);
b6 = fb(ib-1+find(Sb(ib:end) < 0.5,1,'first')-1);
a20 = fb(find(Sb(1:ib) < 0.1,1,'last')+1);
b20 = fb(ib-1+find(Sb(ib:end) < 0.1,1,'first')-1);
En = cumsum(Sb.^2)/sum(Sb.^2);
e05 = fb(find(En>0.05,1));
e95 = fb(find(En>0.95,1));
fprintf('\n=== THE BURST: %d-cycle Hann tone burst, duration %.1f us; it is NOT one frequency\n',ncyc,1e6*ncyc/FC);
fprintf('   amplitude above 50 %%: %.1f ... %.1f kHz | above 10 %%: %.1f ... %.1f kHz | 90 %% of the energy: %.1f ... %.1f kHz\n',a6/1e3,b6/1e3,a20/1e3,b20/1e3,e05/1e3,e95/1e3);
%% transfer function at the far probe
% TRANSFER FUNCTION: cut out the burst as it passes the far probe, fade the edges smoothly, Fourier-transform it for both rods.
nfft = 2^nextpow2(16*numel(t));
f = (0:nfft/2)'/(nfft*dt);
P = zeros(nfft/2+1,2);
for q = 1:2
    if q == 1
        sig = up;
    else
        sig = ug;
    end
    m = (t >= xfar/c0-20e-6) & (t <= xfar/c0+380e-6);
    n = sum(m);
    w = ones(n,1);
    nr = floor(0.25*n);
    w(1:nr) = 0.5*(1-cos(pi*(0:nr-1)'/nr));
    w(end-nr+1:end) = flipud(w(1:nr));
    sg = zeros(size(sig));
    sg(m) = sig(m).*w;
    X = fft(sg,nfft);
    P(:,q) = abs(X(1:nfft/2+1))*dt;
end
usable = (P(:,1) > 0.2*max(P(:,1))) & f >= band(1) & f <= band(2);
% T(f) = grooved / plain.  1 = passes freely, 0 = completely blocked.  fu = the frequencies where the plain-rod signal is strong enough to divide by.
T = P(:,2)./(P(:,1)+1e-30);
fu = f(usable);
% B = list of stop bands [f_low f_high] in Hz: the frequencies where T is below thr.
B = stopbands(f,T,thr,usable);
if ~isempty(B)
    B = B(B(:,2)-B(:,1) > 0.02*FC,:);
end
Ebur = interp1(fb,Sb.^2,f,'linear',0);
insb = false(size(f));
for i = 1:size(B,1)
    insb = insb | (f >= B(i,1) & f <= B(i,2));
end
fprintf('\n TRANSFER FUNCTION T(f) = |grooved| / |plain| at the far probe (x = %.2f m)\n   usable frequency range %.1f ... %.1f kHz (plain-rod signal within 14 dB of its maximum)\n',xfar,fu(1)/1e3,fu(end)/1e3);
print_bands(B,FC,sprintf('   STOP BAND(S): less than %.0f %% of the amplitude gets through:',100*thr),fu(1),fu(end));
[~,iF] = min(abs(f-FC));
fprintf('   at exactly %.0f kHz: %.1f %% of the amplitude (%.2f %% of the energy) gets through\n',FC/1e3,100*T(iF),100*T(iF)^2);
if any(insb)
    fprintf('   %.0f %% of the burst energy lies inside the stop band(s); of that, %.3f %% reaches the far probe.\n',100*sum(Ebur(insb))/sum(Ebur),100*sum(P(insb,2).^2)/sum(P(insb,1).^2));
    fprintf('   The model has no damping: |T|^2 + |R|^2 = 1, so what does not pass is REFLECTED. Reflection in the band is about %.0f %% of the amplitude (sqrt(1-T^2)).\n',100*sqrt(1-mean(T(insb).^2)));
    fprintf('   So the band that cannot pass is NOT "%.0f kHz": it is the RANGE above, and %.0f kHz is just one frequency inside it.\n',FC/1e3,FC/1e3);
end
%%  Bloch theory 
% Bloch theory of an infinite periodic rod with the same cell (the 3-D dispersion correction is switched on for the 100 kHz rods).
fth = (0.2*FC:100:1.8*FC)';
[qth,cq] = bloch_bar(fth,a,wg,fcase == 100,material);
stb = abs(cq) > 1;
d = diff([0; stb(:); 0]);
s_ = find(d == 1);
e_ = find(d == -1)-1;
for i = 1:numel(s_)
    fprintf('   Bloch theory (infinite rod, %s): stop band %.1f ... %.1f kHz\n',ternary_str(fcase==100,'with 3-D dispersion','constant bar speed'),fth(s_(i))/1e3,fth(e_(i))/1e3);
end
fprintf('   WHY: every groove edge is an impedance step (area ratio 4:1 -> 60 %% amplitude reflection per edge). When the echoes of all the grooves add in phase\n   (2 a = one wavelength at the groove spacing a = %.2f mm, f ~ c/(2a) = %.0f kHz) they cancel the forward wave: a Bragg stop band.\n',a*1e3,c0/(2*a)/1e3);
%%  optional: scattered wave at P1 
% OPTIONAL: if the P1 files exist (probe near the source), estimate the scattered (reflected) wave there: grooved minus plain.
haveP1 = exist(names1{1},'file') == 2 && exist(names1{2},'file') == 2;
if haveP1
    [ta,u1p] = read_wb_table(names1{1},colu);
    [tb2,u1g] = read_wb_table(names1{2},colu);
    u1g = interp1(tb2,u1g,ta,'linear',0);
    ta = ta(:);
    tg = (2*L-x1)/vgate;
    m = ta <= tg;
    n = sum(m);
    w = ones(n,1);
    nr = floor(0.25*n);
    w(end-nr+1:end) = 0.5*(1+cos(pi*(0:nr-1)'/nr));
    ws = zeros(size(ta));
    ws(m) = w;
    nf1 = 2^nextpow2(16*numel(ta));
    f1 = (0:nf1/2)'/(nf1*mean(diff(ta)));
    Xi = abs(fft(ws.*u1p(:),nf1));
    Xs = abs(fft(ws.*(u1g(:)-u1p(:)),nf1));
    Xi = Xi(1:nf1/2+1);
    Xs = Xs(1:nf1/2+1);
    ok1 = Xi > 0.2*max(Xi) & f1 >= band(1) & f1 <= band(2);
    Rm = Xs./(Xi+1e-30);
    fprintf('\n=== SCATTERED WAVE at P1 (grooved - plain), gated before the far-end echo: ratio to the incident spectrum\n');
    for i = 1:size(B,1)
        jj = f1 >= B(i,1) & f1 <= B(i,2) & ok1;
        fprintf('   inside %.1f ... %.1f kHz: mean ratio %.2f%s\n',B(i,1)/1e3,B(i,2)/1e3,mean(Rm(jj)),ternary_str(strcmp(ends,'free'),' (includes re-reflection at the free source end)',''));
    end
end
%% figures 
figure(1);
clf
subplot(1,2,1);
plot(tb*1e6,Fb,'k','LineWidth',1.3);
grid on;
xlabel('time [\mus]');
title('the burst');
subplot(1,2,2);
plot(fb/1e3,Sb,'b','LineWidth',1.5);
grid on;
xlim([0 2.2*FC/1e3]);
xlabel('frequency [kHz]');
ylabel('|F(f)| normalised');
title('its Fourier transform');
sv('1_burst.png');
figure(2);
clf
subplot(2,1,1);
plot(fu/1e3,T(usable),'r','LineWidth',1.6);
hold on;
grid on
for i = 1:size(B,1)
    patch([B(i,1) B(i,2) B(i,2) B(i,1)]/1e3,[0 0 1.25 1.25],'r','FaceAlpha',0.12,'EdgeColor','none');
end
plot(FC*[1 1]/1e3,[0 1.25],'g--');
plot([fu(1) fu(end)]/1e3,thr*[1 1],'k:');
ylim([0 1.25]);
xlim([fu(1) fu(end)]/1e3);
ylabel('T = amplitude grooved / plain');
title('transfer function (shading = stop band, green = design frequency)');
subplot(2,1,2);
plot(fu/1e3,P(usable,1)/max(P(usable,1)),'b',fu/1e3,P(usable,2)/max(P(usable,1)),'r','LineWidth',1.4);
hold on;
plot(fb/1e3,Sb,'k--');
grid on;
xlim([fu(1) fu(end)]/1e3);
xlabel('frequency [kHz]');
ylabel('|U(f)| normalised');
legend('plain, far probe','grooved, far probe','burst input');
sv('2_transfer_function.png');
fprintf('\nPNG files are in the folder %s\n',plotdir);
resf = fullfile(plotdir,'results_bragg.mat');
cqth = cq;
save(resf,'B','FC','fth','cqth','a','wg','thr','ends','-v7');
fprintf('numbers saved in %s\n',resf);

%% HELPER FUNCTIONS used above 
function echo_check_(fnew,fold,xp,fcase,colu,plotdir)
% ECHO_CHECK_  reflection coefficient R = (echo from the far end) / (incident burst), with sign, from ONE plain-rod probe export.
%   R = +1 free end, R = -1 fixed end, R = 0 perfect absorber.  The burst and its echo are cut out of the time history and compared.
    L = 1.0;
    % approximate GROUP speed of the burst [m/s] (only used to know where to look)
    if fcase == 100
        cg = 4300;
    else
        cg = 5000;
    end
    if xp > 0.72
        error('Probe at %.2f m is too close to the far end: the echo overlaps the incident burst. Use a probe with y < 0.7 m (P1).',xp);
    end
    % files = the run to check (fnew) and, optionally, an OLD free-end run (fold) to compare with.
    files = {fnew};
    if ~isempty(fold)
        files{2} = fold;
    end
    labs  = {'NEW (absorbing ends)','OLD (free ends)'};
    col   = {'r','b'};
    if ~exist(plotdir,'dir')
        mkdir(plotdir);
    end
    figure(1);
    clf;
    hold on;
    grid on
    for k = 1:numel(files)
        [t,u] = read_wb_table(files{k},colu);
        t = t(:);
        u = u(:);
        dt = mean(diff(t));
        tt = (t(1):dt:t(end))';
        u = interp1(t,u,tt,'linear',0);
        t = tt;
        u = u - mean(u(1:max(3,round(5e-6/dt))));
        tcut = 0.5*(xp/cg + (2*L-xp)/cg);
        % incident burst: biggest peak before the echo can arrive
        m1 = t < tcut;
        [~,i1] = max(abs(u.*m1));
        % window scales with the burst length
        Tb = 3/(fcase*1e3);
        Tpre = Tb/2+25e-6;
        Tpost = Tb/2+65e-6;
        n1 = round((Tpre+Tpost)/dt);
        % zero padding so the window never leaves the record
        pad = round(0.5e-3/dt);
        u = [zeros(pad,1); u];
        t = t(1)+((-pad:numel(t)-1)')*dt;
        i1 = i1+pad;
        a1 = i1 - round(Tpre/dt);
        inc = u(a1:a1+n1-1);
        tinc = t(i1);
        lagmax = round(45e-6/dt);
        i2c = i1 + round(2*(L-xp)/cg/dt);
        % Slide the echo window by up to +-45 us and keep the position where the echo matches the incident burst best (cross-correlation).
        best = 0;
        ib = i2c;
        for s = -lagmax:lagmax
            a2 = i2c + s - round(Tpre/dt);
            if a2 < 1 || a2+n1-1 > numel(u)
                continue;
            end
            ec = u(a2:a2+n1-1);
            c = sum(inc.*ec);
            if abs(c) > abs(best)
                best = c;
                ib = a2;
            end
        end
        R = best/sum(inc.^2);                                                    % echo amplitude relative to incident, with sign
        ec = u(ib:ib+n1-1);
        Rrms = sqrt(sum(ec.^2)/sum(inc.^2));
        fprintf('\n%s   (%s)\n   incident burst at t = %.1f us (peak %.3e m),  echo window starts %.1f us after it\n',labs{k},files{k},tinc*1e6,max(abs(inc)),(t(ib)+Tpre-tinc)*1e6);
        fprintf('   REFLECTION COEFFICIENT  R = %+.3f   (|echo| / |incident| = %.1f %%,  energy-based %.1f %%)\n',R,100*abs(R),100*Rrms);
        if k == 1
            if abs(R) < 0.05
                fprintf('   -> VERY GOOD: below 5 %%. The absorbing ends work; repeat for the other systems.\n');
            elseif abs(R) < 0.15
                fprintf('   -> acceptable (5...15 %%); a few percent is normal for a 3-D rod at 100 kHz.\n');
            elseif abs(R) > 0.5 && R > 0
                fprintf('   -> about 70 %% or more comes back with the SAME sign as a free end: dashpot too weak -> ringfac = (2*ACOS(-1))**2 in the Commands object.\n');
            elseif abs(R) > 0.5 && R < 0
                fprintf('   -> about 70 %% or more comes back with the OPPOSITE sign (like a fixed end): dashpot too strong -> ringfac = 1 in the Commands object.\n');
            else
                fprintf('   -> %.0f %% comes back: not perfect. Check the printout and the plot.\n',100*abs(R));
            end
        end
        plot(t*1e6,u/max(abs(inc)),col{k},'LineWidth',1.2,'DisplayName',labs{k});
    end
    xlabel('time [\mus]');
    ylabel('displacement / peak of the incident burst');
    title(sprintf('probe at y = %.2f m: first burst, then the echo from the far end',xp));
    legend show
    save_fig(fullfile(plotdir,'echo_check.png'));
    fprintf('\nPlot saved in %s\n',fullfile(plotdir,'echo_check.png'));
end

function [E,rho,c0,fp,cp] = material_(name)
% MATERIAL_  rod material. E [Pa], rho [kg/m3], c0 = sqrt(E/rho) = 1-D bar speed [m/s], and the Pochhammer phase speed cp [m/s] of the
%   fundamental longitudinal mode of a solid round rod (radius 10 mm) at the frequencies fp [Hz] (3-D dispersion; depends on E, rho and nu).
    fp = [5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100 105 110 115 120 125 130 135 140 145 150 155 160 165 170 175 180 185]*1e3;
    switch lower(name)
        case 'steel'  % BRIGHT MILD STEEL, handbook values: E = 205 GPa, rho = 7850 kg/m3, nu = 0.29
            E = 205e9;
            rho = 7850;
            cp = [5110 5109 5107 5104 5100 5095 5090 5083 5075 5066 5056 5044 5031 5016 4999 4980 4958 4933 4905 4873 4835 4792 4742 4683 4614 4533 4438 4329 4208 4079 3950 3828 3718 3622 3539 3468 3408];
        case {'aluminium','aluminum'}    % Al 6061-T6: E = 68.9 GPa, rho = 2700 kg/m3, nu = 0.33 (the OLD runs)
            E = 68.9e9;
            rho = 2700;
            cp = [5051 5049 5047 5043 5038 5032 5025 5016 5006 4994 4981 4966 4949 4930 4908 4883 4856 4824 4789 4749 4703 4650 4589 4520 4440 4349 4247 4135 4017 3897 3783 3677 3583 3501 3430 3368 3315];
        otherwise
            error('material must be ''steel'' or ''aluminium''');
    end
    c0 = sqrt(E/rho);
end
function [q,cq] = bloch_bar(f,a,wg,disp,material)
    [~,rho,c0,fp,cp] = material_(material);                 % E, rho, c0 and the dispersion table of the chosen material
    A1 = pi*0.010^2;
    A2 = pi*0.005^2;
    f = f(:);
    cq = zeros(size(f));
    for i = 1:numel(f)
        w = 2*pi*f(i);
        if disp
            c1 = interp1(fp,cp,f(i),'linear','extrap');
            c2 = interp1(fp,cp,f(i)/2,'linear','extrap');
        else
            c1 = c0;
            c2 = c0;
        end
        T = seg_(w,c1,A1,rho,a-wg) * seg_(w,c2,A2,rho,wg);
        cq(i) = 0.5*(T(1,1)+T(2,2));
    end
    q = acos(complex(cq))/a;
end
function S = seg_(w,c,A,rho,L)
    % E A k = rho A c w
    k = w/c;
    Z = rho*A*c*w;
    S = [cos(k*L), sin(k*L)/Z; -Z*sin(k*L), cos(k*L)];
end

function print_bands(B,FC,what,fmin,fmax)
% PRINT_BANDS  prints stop bands in kHz, says whether the design frequency FC is inside, and where the data end.
    fprintf('\n%s\n',what);
    if isempty(B)
        fprintf('   no stop band found inside the usable range %.1f ... %.1f kHz\n',fmin/1e3,fmax/1e3);
        return
    end
    for i = 1:size(B,1)
        lo = B(i,1);
        hi = B(i,2);
        note = '';
        if lo <= fmin*1.0001
            note = [note '  (lower edge is only the limit of the usable data: the band may extend lower)'];  %#ok<AGROW>
        end
        if hi >= fmax*0.9999
            note = [note '  (upper edge is only the limit of the usable data)'];  %#ok<AGROW>
        end
        in = '';
        if FC >= lo && FC <= hi
            in = sprintf('  <-- contains the design frequency %.0f kHz',FC/1e3);
        end
        fprintf('   %7.2f ... %7.2f kHz   (centre %.2f kHz, width %.2f kHz)%s%s\n',lo/1e3,hi/1e3,mean([lo hi])/1e3,(hi-lo)/1e3,in,note);
    end
end

function [t,u] = read_wb_table(fname,colu)
    if nargin < 2
        colu = 2;
    end
    fid = fopen(fname,'r');
    if fid < 0
        error('cannot open %s',fname);
    end
    D = [];
    nc = 0;
    while true
        l = fgetl(fid);
        if ~ischar(l)
            break;
        end
        l = strrep(strrep(l,char(9),' '),';',' ');
        if any(l == ',') && ~any(l == '.')
            l(l == ',') = '.';
        end
        v = sscanf(l,'%f')';
        if numel(v) >= 2 && (nc == 0 || numel(v) == nc)
            nc = numel(v);
            D(end+1,1:nc) = v;  %#ok<AGROW>
        end
    end
    fclose(fid);
    if size(D,1) > 5 && D(1,1) == 1 && all(abs(diff(D(:,1)) - 1) < 1e-9)
        D(:,1) = [];
    end
    t = D(:,1);
    u = D(:,colu);
end

function save_fig(fname)
% SAVE_FIG  writes the current figure as a PNG file (works in MATLAB and in Octave).
    if exist('OCTAVE_VERSION','builtin') ~= 0
        print('-dpng','-S1200,750',fname);
    else
        set(gcf,'Position',[50 50 1200 750]);
        print('-dpng','-r90',fname);
    end
end

function B = stopbands(f,T,thr,usable)
% STOPBANDS  frequency ranges where the transmitted AMPLITUDE FRACTION T is below thr (and the data are usable).
%   B = stopbands(f,T,thr,usable)   ->  N x 2 matrix [f_low f_high] in Hz, edges interpolated to the threshold crossing.
    f = f(:);
    T = T(:);
    if nargin < 4
        usable = true(size(f));
    end
    usable = usable(:);
    m = (T < thr) & usable;
    d = diff([0; m; 0]);
    s = find(d == 1);
    e = find(d == -1) - 1;
    B = zeros(numel(s),2);
    for i = 1:numel(s)
        lo = f(s(i));
        hi = f(e(i));
        if s(i) > 1 && usable(s(i)-1)
            lo = f(s(i)-1) + (thr-T(s(i)-1))*(f(s(i))-f(s(i)-1))/(T(s(i))-T(s(i)-1));
        end
        if e(i) < numel(f) && usable(e(i)+1)
            hi = f(e(i)) + (thr-T(e(i)))*(f(e(i)+1)-f(e(i)))/(T(e(i)+1)-T(e(i)));
        end
        B(i,:) = [lo hi];
    end
end

function s = ternary_str(c,a,b)
    if c
        s = a;
    else
        s = b;
    end
end
