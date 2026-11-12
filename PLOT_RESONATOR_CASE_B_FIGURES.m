%% PLOT_RESONATOR_CASE_B_FIGURES.m
%  Local resonator 0.5 kg mass-spring at 1.0 m, 1000 Hz, hammer at 0.7 m, 6 m rod.
%  FILES NEEDED from apdl four columns: time | u before | u after | u mass):
%     B_resref.txt    reference rod, no resonator
%     B_reswith.txt   rod with resonator
%  Put this script in the folder of the files, or type the folder below.

clear; close all; clc

%% CHANGE THIS BLOCK
dirData        = '.';                 % folder with the two files ('.' = current folder)
fRef           = 'B_resref.txt';      % reference-rod file
fWith          = 'B_reswith.txt';     % rod-with-resonator file
xBefore        = 0.85;                % before-probe position [m]
xAfter         = 1.40;                % after-probe position [m]
colBefore      = 2;                   % column of the displacement at the before-probe
colAfter       = 3;                   % column of the displacement at the after-probe
screenFraction = 0.80;                % largest share of the screen a figure may take
saveFigures    = true;                % true = save both figures at the end of the run
outDir         = 'report_figures';    % folder for the saved files (created if missing)
saveFormats    = {'png','pdf'};       % any of 'png', 'pdf', 'fig'
saveDPI        = 300;                 % PNG resolution; every figure is saved 7.4 in wide

%% FIXED SETTINGS
colRef  = [0 0 0];   colWith = [0.698 0.133 0.133];
set(groot,'defaultAxesFontName','Times New Roman','defaultTextFontName','Times New Roman','defaultLegendFontName','Times New Roman');

%% READ THE FILES AND FORM THE VELOCITY
R = read_ansys_table(fullfile(dirData,fRef), 4);
Q = read_ansys_table(fullfile(dirData,fWith),4);
t  = R(:,1)*1e3;                       % time [ms]
dt = mean(diff(R(:,1)));               % time step [s]
V  = @(D,c) gradient(D(:,c),dt)*1e3;   % velocity [mm/s] from the nodal displacement [m]
v  = {V(R,colBefore), V(R,colAfter); V(Q,colBefore), V(Q,colAfter)};   % rows: reference, with resonator; columns: before, after
lab = {sprintf('Before the resonator, x = %.2f m',xBefore), sprintf('After the resonator, x = %.2f m',xAfter)};
short = {'Before the resonator','After the resonator'};
tl = [t(1) t(end)];   tl = tl + 0.05*diff(tl)*[-1 1];                  % common time limits with a 5 % margin
figList = gobjects(0);  figName = {};

%% FIGURE 9.6  reference rod and rod with resonator side by side
[fig,fs] = newfig('Figure 9.6',7.4,4.6,screenFraction);
ax = makeaxes(2,2,[0.095 0.025 0.115 0.080],[0.025 0.100]);
head = {'Reference rod (no resonator)','Rod with resonator'};
cc   = [colRef; colWith];
for i = 1:2                                                            % rows: before, after
    yl = [min([v{1,i};v{2,i}]) max([v{1,i};v{2,i}])];  yl = yl + 0.05*diff(yl)*[-1 1];   % one y-range per row
    for j = 1:2                                                        % columns: reference, with resonator
        a = ax(i,j);  axes(a);  hold(a,'on');
        plot(a,t,v{j,i},'Color',cc(j,:),'LineWidth',1.0);
        set(a,'XLim',tl,'YLim',yl);
        style(a,fs);
        text(0.98,0.93,short{i},'Parent',a,'Units','normalized','HorizontalAlignment','right','VerticalAlignment','top','FontSize',fs);
        if i == 1, title(a,head{j},'FontWeight','normal','FontSize',fs+1); end
        if i == 1, set(a,'XTickLabel',[]); else, xlabel(a,'Time [ms]'); end
        if j == 1, ylabel(a,'Velocity [mm/s]'); else, set(a,'YTickLabel',[]); end
    end
end
figList(end+1) = fig;  figName{end+1} = 'Figure_9_6_resonator_traces_side_by_side';  drawnow;

%% FIGURE 9.7  the same records superimposed
[fig,fs] = newfig('Figure 9.7',7.4,4.6,screenFraction);
ax = makeaxes(2,1,[0.095 0.025 0.115 0.080],[0.0 0.130]);
for i = 1:2
    a = ax(i,1);  axes(a);  hold(a,'on');
    h1 = plot(a,t,v{1,i},'Color',colRef, 'LineWidth',1.1);
    h2 = plot(a,t,v{2,i},'Color',colWith,'LineWidth',1.1);
    yl = [min([v{1,i};v{2,i}]) max([v{1,i};v{2,i}])];  yl = yl + 0.05*diff(yl)*[-1 1];
    set(a,'XLim',tl,'YLim',yl);
    style(a,fs);
    ylabel(a,'Velocity [mm/s]');
    title(a,lab{i},'FontWeight','normal','FontSize',fs+1);
    if i == 1, set(a,'XTickLabel',[]); else, xlabel(a,'Time [ms]'); end
end
legend(a,[h1 h2],{'Reference rod','Rod with resonator'},'Location','southeast','FontSize',fs,'Box','on');
figList(end+1) = fig;  figName{end+1} = 'Figure_9_7_resonator_traces_superimposed';  drawnow;

%% SAVE THE FIGURES
if saveFigures
    if ~exist(outDir,'dir'), mkdir(outDir); end
    for q = 1:numel(figList)
        fg  = figList(q);
        pos = get(fg,'Position');
        res = max(1,round(saveDPI*get(fg,'UserData')/(pos(3)/get(0,'ScreenPixelsPerInch'))));   % integer resolution giving a 7.4 in wide file
        for e = 1:numel(saveFormats)
            fn = fullfile(outDir,[figName{q} '.' saveFormats{e}]);
            switch lower(saveFormats{e})
                case 'png'
                    if exist('exportgraphics','file'), exportgraphics(fg,fn,'Resolution',res,'BackgroundColor','white');
                    else, print(fg,fn,'-dpng',sprintf('-r%d',res)); end
                case 'pdf'
                    if exist('exportgraphics','file'), exportgraphics(fg,fn,'ContentType','vector','BackgroundColor','white');
                    else, print(fg,fn,'-dpdf','-painters'); end
                case 'fig'
                    savefig(fg,fn);
            end
        end
    end
    fprintf('\nFigures saved in: %s\n',fullfile(pwd,outDir));
    for q = 1:numel(figName), fprintf('   %s  (%s)\n',figName{q},strjoin(saveFormats,', ')); end
end
fprintf('\nCase B figures drawn (%d samples, dt = %.2f us).\n',numel(t),dt*1e6);

%% functions
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

function [fig,fs] = newfig(name,wIn,hIn,frac)
% NEWFIG  figure of wIn x hIn inches, scaled to fit the screen and placed in the middle of it.
    scr = get(0,'ScreenSize');  ppi = get(0,'ScreenPixelsPerInch');
    W = wIn*ppi;  H = hIn*ppi;
    s = min([frac*scr(3)/W, frac*scr(4)/H, 1.3]);
    W = round(W*s);  H = round(H*s);
    fig = figure('Name',name,'NumberTitle','off','Color','w','Units','pixels', ...
                 'Position',[round((scr(1)+scr(3)-W)/2) round((scr(2)+scr(4)-H)/2) W H],'UserData',wIn);
    fs = max(8,10.5*min(1,s));
end

function ax = makeaxes(nr,nc,mg,gp)
% MAKEAXES  nr x nc axes in normalised units. mg = [left right bottom top] margins, gp = [horizontal vertical] gaps.
    wA = (1 - mg(1) - mg(2) - (nc-1)*gp(1))/nc;
    hA = (1 - mg(3) - mg(4) - (nr-1)*gp(2))/nr;
    ax = gobjects(nr,nc);
    for i = 1:nr
        for j = 1:nc
            x0 = mg(1) + (j-1)*(wA + gp(1));
            y0 = 1 - mg(4) - i*hA - (i-1)*gp(2);
            ax(i,j) = axes('Position',[x0 y0 wA hA]);
        end
    end
end

function style(a,fs)
% STYLE  Times New Roman, light grid, ticks outward.
    set(a,'FontName','Times New Roman','FontSize',fs,'Box','on','TickDir','out','LineWidth',0.6, ...
          'GridColor',[0.5 0.5 0.5],'GridAlpha',0.3,'XGrid','on','YGrid','on','Layer','top');
end
