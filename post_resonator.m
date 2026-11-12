%% post_resonator.m  (version B)

clear; close all; clc

%% CHANGE THIS BLOCK
nres  = 1;                               % number of mass-spring systems: 1 or 2
xr    = [1.0   3.0];                     % positions [m]      (Lrod/4 = 1.5, Lrod/3 = 2.0, Lrod/2 = 3.0 ...)
mr    = [0.5   0.5];                     % masses [kg]
kr    = [0     0  ];                     % spring stiffnesses [N/m]   (0 = calculate from fnin)
fnin  = [1000   1000];                    % natural frequencies [Hz]   (used only where kr = 0)
zr    = [0.01  0.01];                    % damping ratios [-]
xhit_m = 0.7;
xb_m = 0.85;
xa_m = 1.4;                                 % optional manual hammer / before-probe / after-probe positions [m] (0 = automatic)
flo = 200;
fhi = 2000;                              % frequency range of the result [Hz]
Lrod = 6.0;                              %  rod length [m]
fref = 'B_resref.txt';
fwith = 'B_reswith.txt';                 %  file names (APDL runs)
workbench = 0;                           %  0 = APDL files above,  1 = Workbench exports below
wbnames = {'ref_before.txt','ref_after.txt','with_before.txt','with_after.txt'};
colu = 2;                                % column of the displacement in Workbench exports

%% fixed (same as the ANSYS script)
Emod = 193e9;
rho = 8000;
rrod = 0.010;
xr = xr(1:nres);
mr = mr(1:nres);
kr = kr(1:nres);
fnin = fnin(1:nres);
zr = zr(1:nres);
z0 = (kr == 0);
kr(z0) = mr(z0).*(2*pi*fnin(z0)).^2;                               % stiffness from the natural frequency where kr = 0
fn = sqrt(kr./mr)/(2*pi);                                          % natural frequencies [Hz]
xb   = min(xr)-0.4;
xhit = xb-0.4;
xa = max(xr)+0.4;           % same automatic placement as ANSYS
if xhit_m > 0, xhit = xhit_m; end,  if xb_m > 0, xb = xb_m; end,  if xa_m > 0, xa = xa_m; end
if ~(xhit < xb && xb < min(xr) && max(xr) < xa && xhit >= 0.15 && xa <= Lrod-0.15)
    error('The layout does not fit: hammer %.2f, before-probe %.2f, systems %.2f ... %.2f, after-probe %.2f m. Order: hammer < before < systems < after, 0.15 m from the ends.',xhit,xb,min(xr),max(xr),xa);
end
cg   = @(f) 9.908*sqrt(2*pi*f);                                    % flexural group speed [m/s]
pathe = min(xhit+xa,(Lrod-xhit)+(Lrod-xa));                        % first echo path to the "after" probe [m]
ratio = pathe/(xa-xhit);
fprintf('hammer x = %.2f m, before probe x = %.2f m, after probe x = %.2f m\n',xhit,xb,xa);
for i = 1:nres
    fprintf('mass-spring system %d: x = %.2f m, m = %.3f kg, k = %.3g N/m  ->  natural frequency %.0f Hz\n',i,xr(i),mr(i),kr(i),fn(i));
end
fprintf('echo path %.2f m, direct path %.2f m, ratio %.1f (2 is the minimum, 3 or more is better)\n',pathe,xa-xhit,ratio);
if ratio < 2, disp('WARNING: ratio below 2: results are unreliable. Put the systems closer together or set xhit_m, xb_m, xa_m closer to them.'); elseif ratio < 3, disp('NOTE: ratio below 3: narrow, deep dips (below about -30 dB) will be less reliable.'); end

%% load
if workbench == 0
    R = read_ansys_table(fref,4);   Q = read_ansys_table(fwith,4);     % NOT load(): see read_ansys_table at the end of this file
else
    W = cell(1,4);
    for q = 1:4
        fid = fopen(wbnames{q},'r');  if fid < 0, error('cannot open %s',wbnames{q}); end
        D = [];  nc = 0;
        while true
            l = fgetl(fid);  if ~ischar(l), break; end
            l = strrep(strrep(l,char(9),' '),';',' ');
            v = sscanf(l,'%f')';
            if numel(v) >= 2 && (nc == 0 || numel(v) == nc), nc = numel(v);  D(end+1,1:nc) = v; end   %#ok<AGROW>
        end
        fclose(fid);  W{q} = D;
    end
    tt = W{1}(:,1);
    R = [tt, W{1}(:,colu), interp1(W{2}(:,1),W{2}(:,colu),tt,'linear',0), 0*tt];
    Q = [tt, interp1(W{3}(:,1),W{3}(:,colu),tt,'linear',0), interp1(W{4}(:,1),W{4}(:,colu),tt,'linear',0), 0*tt];
end
t  = R(:,1);  t = t(:);

%% Fig 1
figure(1); clf
for a = 1:2
    subplot(2,1,a); plot(t*1e3,R(:,1+a)*1e6,'k',t*1e3,Q(:,1+a)*1e6,'r'); grid on; ylabel('u [\mum]');
end
subplot(2,1,1); title('BEFORE the resonators (black: no resonators, red: with)'); legend('no resonators','with resonators');
subplot(2,1,2); title('AFTER the resonators'); xlabel('time [ms]');

%% frequency-by-frequency analysis
f    = (flo:10:fhi)';
Xref = zeros(size(f));  Xwith = zeros(size(f));
% The VELOCITY of the rod is analysed, not the displacement: a free-free rod that is hit also drifts and turns as a whole
% (rigid-body motion), which would pollute the low frequencies. Velocity removes that drift; the ratio is the same.
dt_  = mean(diff(t));
vR   = gradient(R(:,3),dt_);   vQ = gradient(Q(:,3),dt_);
for i = 1:numel(f)
    Te = pathe/cg(f(i));                                % first echo of THIS frequency
    m  = t <= Te;  n = sum(m);
    w  = ones(n,1);  nr_ = floor(0.25*n);               % cosine taper over the last 25 %
    w(end-nr_+1:end) = 0.5*(1+cos(pi*(0:nr_-1)'/nr_));
    e  = exp(-2i*pi*f(i)*t(m));
    Xref(i)  = abs(sum(vR(m).*w.*e));
    Xwith(i) = abs(sum(vQ(m).*w.*e));
end
T_ans = 20*log10(Xwith./Xref);
usable = Xref > 10^(-50/20)*max(Xref);                  % hammer content within 50 dB of its maximum
T_ans(~usable) = NaN;

%% analytical transfer-matrix curve
T_an = zeros(size(f));
for i = 1:numel(f)
    T_an(i) = 20*log10(max(1e-6,transmission_multi(f(i),xr,mr,fn,zr,Emod,rho,rrod)));
end

%% Fig 2 and 3
figure(2); clf
plot(f,T_ans,'r','LineWidth',1.5); hold on
plot(f,T_an,'k--','LineWidth',1.2);
for i = 1:nres, plot(fn(i)*[1 1],[-45 10],'g:','LineWidth',1.2); end
grid on; ylim([-45 10]); xlim([flo fhi]); xlabel('Frequency [Hz]'); ylabel('Transmission [dB]')
legend('ANSYS (with / without)','analytical (infinite beam)','resonator natural frequency fn','Location','SouthEast')
%title(sprintf('%d Resonator(s): which frequencies get through',nres))

figure(3); clf
plot(f,20*log10(Xref/max(Xref)),'b','LineWidth',1.3); grid on; xlim([flo fhi]); ylim([-80 5])
xlabel('frequency [Hz]'); ylabel('hammer content at the after probe [dB re max]')
%title('Frequency content of the hammer hit (reference run)')

%%  numbers for the report
okf = usable;   fsel = f(okf);  Ts = T_ans(okf);
[mn,im] = min(Ts);   idx = find(Ts < -10);
fprintf('\nDeepest attenuation: %.1f dB at %.0f Hz\n',mn,fsel(im));
if ~isempty(idx)
    fprintf('Frequencies attenuated by more than 10 dB: %.0f ... %.0f Hz\n',fsel(idx(1)),fsel(idx(end)));
    d = find(diff(idx) > 1);
    if ~isempty(d), disp('(more than one separate band: look at figure 2)'); end
else
    disp('No frequency attenuated by more than 10 dB: use a heavier mass or a different stiffness.');
end
fprintf('Frequency resolution of the ANSYS curve: about %.0f Hz at %d Hz and %.0f Hz at %d Hz.\n', ...
        cg(flo)/pathe, flo, cg(fhi)/pathe, fhi);
disp('Dips narrower than this look shallower than the black dashed curve. That is a limit of the 6 m rod, not an error.');

%% ========================================================================================== functions
% HELPER FUNCTIONS (local functions, so that this file runs on its own; the same code is used in the other resonator scripts)

function D = read_ansys_table(fname, ncol)
% READ_ANSYS_TABLE  reads the text files written by the ANSYS scripts (E16.8). Fortran prints a 3-digit exponent
%   without the letter E (0.235-105 means 2.35e-106); load() would misread that, so the E is put back first.
    txt = fileread(fname);
    txt = regexprep(txt,'(\d)([+-]\d{3})(?=\s|$)','$1E$2');
    v   = sscanf(txt,'%f');
    if mod(numel(v),ncol) ~= 0
        error('%s: %d numbers cannot be arranged in %d columns. The file is incomplete or damaged.',fname,numel(v),ncol);
    end
    D = reshape(v,ncol,[])';
end

function [T,R] = transmission_multi(f,xs,ms,frs,zs,Emod,rho,rrod)
% TRANSMISSION_MULTI  [T,R] = |transmitted| and |reflected| amplitude (incident = 1) of an infinite Euler-Bernoulli beam with point mass-spring-damper resonators at positions xs.
% Unknowns: wave amplitudes in every segment (bounded exponentials only), 4 equations per resonator.
    N = numel(xs);  if N == 0, T = 1; R = 0; return; end
    A = pi*rrod^2;  I = pi*rrod^4/4;  EI = Emod*I;  rA = rho*A;
    w = 2*pi*f;  b = (rA*w^2/EI)^0.25;
    [xs,o] = sort(xs);  ms = ms(o);  frs = frs(o);  zs = zs(o);
    L = diff(xs);
    nunk = 4*N;  Mx = zeros(nunk,nunk);  rhs = zeros(nunk,1);
    col = @(lam) [1; lam; EI*lam^2; EI*lam^3];
    cap = col(-1i*b);  cae = col(-b);  cbp = col(1i*b);  cbe = col(b);
    iLeft = 0;  iRight = 2+4*(N-1);
    for j = 1:N
        Lcols = {};  const = zeros(4,1);
        if j == 1
            const = const + cap;
            Lcols = {iLeft+1, cbp; iLeft+2, cbe};
        else
            ell = L(j-1);  i0 = 2+4*(j-2);
            Lcols = {i0+1, cap*exp(-1i*b*ell); i0+2, cae*exp(-b*ell); i0+3, cbp; i0+4, cbe};
        end
        if j == N
            Rcols = {iRight+1, cap; iRight+2, cae};
        else
            ell = L(j);  i0 = 2+4*(j-1);
            Rcols = {i0+1, cap; i0+2, cae; i0+3, cbp*exp(-1i*b*ell); i0+4, cbe*exp(-b*ell)};
        end
        wr = 2*pi*frs(j);
        Meff = ms(j)*wr^2/(wr^2 - w^2 + 2i*zs(j)*wr*w);
        for e = 1:4
            row = 4*(j-1)+e;
            for k = 1:size(Rcols,1), Mx(row,Rcols{k,1}) = Mx(row,Rcols{k,1}) + Rcols{k,2}(e); end
            for k = 1:size(Lcols,1), Mx(row,Lcols{k,1}) = Mx(row,Lcols{k,1}) - Lcols{k,2}(e); end
            if e == 4
                for k = 1:size(Lcols,1), Mx(row,Lcols{k,1}) = Mx(row,Lcols{k,1}) - Meff*w^2*Lcols{k,2}(1); end
                rhs(row) = rhs(row) + Meff*w^2*const(1);
            end
            rhs(row) = rhs(row) + const(e);
        end
    end
    sol = Mx\rhs;
    T = abs(sol(iRight+1));  R = abs(sol(iLeft+1));
end
