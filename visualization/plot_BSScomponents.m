function plot_BSScomponents(cnt_ica, mnt, W_ica, A_ica, goodcomp, out, varargin)
%  IN   cnt_ica     - data structure of independent components 
%       mnt         - electrode montage structure
%       W_ica       - demixing matrix
%       A_ica       - mixing matrix
%       goodcomp    - array containing the numbers of the non-artifactual 
%                     components
%       out         - classifier output (or classifier probabliy)
%                        [1 x nComponents]
%       varargin    - for figure directory if those should be saved
%
% Plots spectrum, time course, filter and pattern for each independent 
% component and indicates whether it has been labeled as an artifact 
% or a neuronal activity. 

opts = opt_setDefaults(opt_proplistToStruct(varargin{:}) ...
    ,{'fig_dir', ''} ...
    );

%standardise the variance of the component to 1 
cnt_ica.x = cnt_ica.x./repmat(std(cnt_ica.x,0,1),length(cnt_ica.x(:,1)),1);

%calculate spectrum
sp_ica = proc_spectrum(cnt_ica, [0, floor(cnt_ica.fs/2)]);

for ic = 1:length(cnt_ica.x(1,:)) %for each component
    %Set the title to the according label found in goodcomp
    if isempty(setdiff(ic, goodcomp))  
        tit = sprintf('neuronal activity [%2.4f]',out(ic));
    else
        tit = sprintf('artifact [%2.4f]',out(ic));
    end    
    %plot spectrum, time course, filter and pattern for the component
    f = plot_ica_channel(cnt_ica, sp_ica, mnt, W_ica, A_ica, ic, tit);
    if ~strcmp(opts.fig_dir,'') && exist(opts.fig_dir, 'dir')
        saveas(f, fullfile(opts.fig_dir, sprintf('comp_%g', ic)), 'png')
    end
end


function f = plot_ica_channel(cnt_ica, sp_ica, mnt, AFilter, APattern, ic, tit)

f = figure;
%plot spectrum
subplot(2, 4, 1:2);
plot(sp_ica.t, sp_ica.x(:, ic));
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
section = [1, floor(length(cnt_ica.x)/cnt_ica.fs)];
px = cnt_ica.x(section(1)*cnt_ica.fs:section(2)*cnt_ica.fs, ic);
xl = linspace(section(1), section(2), length(px));
plot(xl, px);
xlabel('sec')
grid on
axis tight
title('Time course') 

