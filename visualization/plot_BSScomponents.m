function plot_BSScomponents(cnt_bss, mnt, W_bss, A_bss, varargin)
%  IN   cnt_bss     - data structure of independent components 
%       mnt         - electrode montage structure
%       W_bss       - demixing matrix
%       A_bss       - mixing matrix
%       varargin    - optional inputs: 
%                'goodcomp' - array containing the numbers of non-artifactual 
%                               components
%                'out'      - classifier output (or classifier probabliy)
%                               [1 x nComponents]
%                'fig_dir'  - for figure directory if those should be saved
%
% Plots spectrum, time course, filter and pattern for each component. 
% If optional parameters are set, the plots indicate whether the component has been labeled as an artifact 
% or neuronal activity. 

opts = opt_setDefaults(opt_proplistToStruct(varargin{:}) ...
    ,{'goodcomp', []; ...
    'out', []; ...
    'fig_dir', ''});

%standardise the variance of the component to 1 
cnt_bss.x = cnt_bss.x./repmat(std(cnt_bss.x,0,1),length(cnt_bss.x(:,1)),1);

%calculate spectrum
sp_bss = proc_spectrum(cnt_bss, [0, floor(cnt_bss.fs/2)]);

for ic = 1:length(cnt_bss.x(1,:)) %for each component
    %Set the title to the according label found in opts.goodcomp
    if isempty(opts.goodcomp)
        tit =  ''; 
    else
        if isempty(opts.out) 
            sout = '';
        else
            sout = sprintf(' [%2.4f]', opts.out(ic)); 
        end
        
        if isempty(setdiff(ic, opts.goodcomp))  
            tit = ['Neuronal activity', sout]; 
        else
            tit = ['Artifact', sout];
        end      
    end
    %plot spectrum, time course, filter and pattern for the component
    f = plot_bss_channel(cnt_bss, sp_bss, mnt, W_bss, A_bss, ic, tit);
    if ~strcmp(opts.fig_dir,'') && exist(opts.fig_dir, 'dir')
        saveas(f, fullfile(opts.fig_dir, sprintf('comp_%g', ic)), 'png')
    end
end


function f = plot_bss_channel(cnt_bss, sp_bss, mnt, AFilter, APattern, ic, tit)

f = figure;
%plot spectrum
subplot(2, 4, 1:2);
plot(sp_bss.t, sp_bss.x(:, ic));
xlim([0 50])
xlabel('Hz')
ylabel('dB')
grid on
title(tit); 

%plot filter
subplot(2, 4, 3);
plot_scalp(mnt, AFilter(ic, :), 'ScalePos','none');
title('Filter');

%plot pattern 
subplot(2, 4, 4);
plot_scalp(mnt, APattern(:, ic), 'ScalePos','none');
title('Pattern');

%plot time course
subplot(2,4,5:8);
section = [1, floor(length(cnt_bss.x)/cnt_bss.fs)];
px = cnt_bss.x(section(1)*cnt_bss.fs:section(2)*cnt_bss.fs, ic);
xl = linspace(section(1), section(2), length(px));
plot(xl, px);
xlabel('sec')
grid on
axis tight
title('Time course') 

