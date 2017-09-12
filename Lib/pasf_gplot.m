function sign = pasf_gplot(nc_name, nSpatialComponents, FPS)
%
% Collaborating with pasf algorithm to plot results on map into a video.
% Running under directory of pasf.
%
% Algorithm of pasf can be found at: https://github.com/khabbazian/pasf.
% Using subplot_tight instead of plot. Toolbox can be found at:
% http://www.mathworks.com/matlabcentral/fileexchange/30884-controllable-tight-subplot
%
% INPUT
%   'nc_name' is the filename of sea level pressure NC file, which is downloaded
%   from NCEP website.
%
%   'FPS' is the value of fps of video to generate, with default 5.
%
%   'nSpatialComponents' is the number of spatial components.
%
% OUTPUT
%   pasf_video.avi, which contains the results from pasf algorithm, will be
%   generated under the working directory.
%
% Examples:
%   pasf_gplot('filename.nc', 2, 10);
%
%   pasf_gplot('filename.nc', 2) under default fps;
%
%
%% AUTHOR   : Ruochen Liu
%% DATE     : 11-September-2017
%% Revision : 1.00
%% DEVELOPED: R2016a
%% FILENAME : pasf_gplot.m
%
    if  nargin < 3
        FPS = 5; % Defalut fps value.
    else
        FPS = FPS;
    end
    nc_name = 'pressure.nc';
    lat = ncread(nc_name, 'lat'); % Read latitdue, longitude and pressure matrix from NC file.
    lon = ncread(nc_name, 'lon');
    t = ncread(nc_name, 'time');
    SeaPressure = ncread(nc_name, 'slp');
    SeaPressure = permute(SeaPressure, [2 1 3]);

    latlim = double([min(lat) max(lat)]); % Range of latitude and longitude.
    lonlim = double([min(lon) max(lon)]);
    Dimension = size(SeaPressure); % Dimension of dataset latitude*longitude*pages.
    num_obs = Dimension(3); % Number of observations.

    sd = datenum('1800-01-01 00:00:00'); % Start date of data records.
    t1 = datetime(datestr(sd+min(t)/24));
    t2 = datetime(datestr(sd+max(t)/24));
    dateSeq = t1:t2;
    data = double(SeaPressure);
    Z = pasf(data, nSpatialComponents); % Z is the result from PASF.
    num_fig = nSpatialComponents + 2; % Number of components plus two.
    K = 1:num_fig;
    D = K(rem(num_fig,K)==0); % Find divisors of the number of subfigures for plotting.
    m = D(D>=sqrt(num_fig));
    m = m(1); % The number of rows in figures.
    n = num_fig/m; % The number of columns in figures.
 
    
    image = zeros(630, 840, 3, num_fig); % Array for saving images of different components.
    image = uint8(image);

    crange = prctile(Z(:) , [1 99]);

    outputVideo = VideoWriter(strcat(pwd,'/pasf_video.avi'));
    outputVideo.FrameRate = FPS; % Set FPS.
    open(outputVideo);

    for i = 1:num_obs, % Given i for date, iterate by j for component.
    
        disp( strcat( 'Generating frame # ', num2str(i) ) );
    
       for j = 1:num_fig,
            exp = Z(:,:,i,j);
            R = georasterref('RasterSize', size(exp), 'Latlim', latlim, 'Lonlim', lonlim); % Set up raster reference from dataset.
            figure('Visible','off','Color','k');
            worldmap(latlim, lonlim); % Set up world map.
            load geoid
            geoshow(geoid, geoidrefvec, 'DisplayType', 'texturemap');
            geoshow('landareas.shp', 'FaceColor', [0.15 0.5 0.15]); % Add land areas and coastlines.
            geoshow(exp, R, 'DisplayType', 'texturemap');
            mesh(peaks);
            caxis(crange);
            colormap(parula);
            title(datestr(dateSeq(i)), 'FontSize', 14); % Add subtitle of date.
            fig = gcf;
            fig.Color = 'white';
            [image(:,:,:,j),map2]=frame2im(getframe(gcf));
            clf;
       end
    
        figure('Visible','off'); % Plot different components in one figure.
        for k = 1:num_fig, % Needs attention!!!!!!!
            if k == num_fig-1
                com_name = 'Noise';
            else
                if k == num_fig
                    com_name = 'Demeaned Data';
                else
                    com_name = strcat( 'Component #', num2str(k));
                end
            end
            subplot_tight(m,n,k,[0.05 0.05]), imshow(image(:,:,:,k));
            title(com_name, 'FontSize', 8); % Add title of component.
        end
       fig = gcf;
       fig.Color = 'white';
    
       F = getframe(gcf);
       writeVideo(outputVideo, F);
       clf;
    end

    close(outputVideo);
    disp('Complete');

end
