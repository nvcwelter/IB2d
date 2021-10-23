%-------------------------------------------------------------------------------------------------------------------%
%
% IB2d is an Immersed Boundary Code (IB) for solving fully coupled non-linear 
% 	fluid-structure interaction models. This version of the code is based off of
%	Peskin's Immersed Boundary Method Paper in Acta Numerica, 2002.
%
% Author: Nicholas A. Battista
% Email:  nick.battista@unc.edu
% Date Created: May 27th, 2015
% Institution: UNC-CH
%
% This code is capable of creating Lagrangian Structures using:
% 	1. Springs
% 	2. Beams (*torsional springs)
% 	3. Target Points
%	4. Muscle-Model (combined Force-Length-Velocity model, "HIll+(Length-Tension)")
%
% One is able to update those Lagrangian Structure parameters, e.g., spring constants, resting %%	lengths, etc
% 
% There are a number of built in Examples, mostly used for teaching purposes. 
% 
% If you would like us %to add a specific muscle model, please let Nick (nick.battista@unc.edu) know.
%
%--------------------------------------------------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: creates the CHANNEL_CHANNEL-EXAMPLE geometry and prints associated input files
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Channel_Channel()

%
% Grid Parameters (MAKE SURE MATCHES IN input2d !!!)
%
Nx =  128;        % # of Eulerian Grid Pts. in x-Direction (MUST BE EVEN!!!)
Ny =  128;        % # of Eulerian Grid Pts. in y-Direction (MUST BE EVEN!!!)
Lx = 1.0;        % Length of Eulerian Grid in x-Direction
Ly = 1.0;        % Length of Eulerian Grid in y-Direction


% Immersed Structure Geometric / Dynamic Parameters %
ds= min(Lx/(2*Nx),Ly/(2*Ny));  % Lagrangian spacing
L = 0.9*Lx;                    % Length of Channel
w = 0.2*Ly;                    % Width of Channel
x0 = 0.3;                      % x-Center for Cylinder
y0 = 0.5;                      % y-Center for Cylinder
r = w/10;                      % Radii of Cylinder
struct_name = 'channel'; % Name for .vertex, .spring, etc files.


% Call function to construct geometry
[xLag,yLag] = give_Me_Channel_Immsersed_Boundary_Geometry(ds,L,w,Lx,Ly);
[xLag_C,yLag_C] = give_Me_Cylinder_Immsersed_Boundary_Geometry(ds,r,x0,y0);

Npts = length(xLag_C);
print('\n\n        WARNING!!!      \n');
print('# of pts in a cell: %d\n',Npts); 
print('If it is not EVEN...there will be a problem :)\n'); 
print('Change radius, r, or ds slightly to try to make it even\n\n');


% Compute Curvatures
C =  compute_Curvatures(xLag_C,yLag_C);

% Plot Geometry to test
plot(xLag(1:end/2),yLag(1:end/2),'r-'); hold on;
plot(xLag(end/2+1:end),yLag(end/2+1:end),'r-'); hold on;
plot(xLag_C,yLag_C,'r-'); hold on;


plot(xLag,yLag,'*'); hold on;
plot(xLag_C,yLag_C,'g*'); hold on;
xlabel('x'); ylabel('y');
axis([0 Lx 0 Ly]);

% Create different Bubbles
xLag_C1 = xLag_C; yLag_C1 = yLag_C;  % Bubble 1
xLag_C2 = xLag_C+3*r; yLag_C2 = yLag_C+2*r;  % Bubble 2
xLag_C3 = xLag_C+1.5*r; yLag_C3 = yLag_C-2.5*r;  % Bubble 3

% Combine Geometry Files into ONE Vector
xLag = [xLag_C1 xLag_C2 xLag_C3 xLag];
yLag = [yLag_C1 yLag_C2 yLag_C3 yLag];
first_Index = 3*length(xLag_C1)+1;

% Combine CELL Geometry files into ONE vector for springs/beams (not necessary...just easier to count)
xLag_Cells = [xLag_C1 xLag_C2 xLag_C3];
yLag_Cells = [yLag_C1 yLag_C2 yLag_C3];

plot(xLag_Cells,yLag_Cells,'k*'); hold on;

% Prints .vertex file!
print_Lagrangian_Vertices(xLag,yLag,struct_name);

% Prints .spring file!
k_Spring = 1e7; ds_Rest = sqrt( ( xLag_C(1)-xLag_C(2)  )^2 + ( yLag_C(1)-yLag_C(2)  )^2    );
print_Lagrangian_Springs(xLag_C,yLag_C,k_Spring,ds_Rest,r,struct_name);

% Prints .beam file!
k_Beam = 1e9; 
print_Lagrangian_Beams(xLag_C,yLag_C,k_Beam,C,struct_name);


% Prints .target file!
k_Target = 1e7;
print_Lagrangian_Target_Pts(xLag,k_Target,struct_name,first_Index);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints VERTEX points to a file called rubberband.vertex
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Vertices(xLag,yLag,struct_name)

    N = length(xLag);

    vertex_fid = fopen([struct_name '.vertex'], 'w');

    fprintf(vertex_fid, '%d\n', N );

    %Loops over all Lagrangian Pts.
    for s = 1:N
        X_v = xLag(s);
        Y_v = yLag(s);
        fprintf(vertex_fid, '%1.16e %1.16e\n', X_v, Y_v);
    end

    fclose(vertex_fid); 
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints Vertex points to a file called rubberband.vertex
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Target_Pts(xLag,k_Target,struct_name,first_index)

    N = length(xLag) - first_index + 1;  % # of target points (e.g., the walls of channel)

    target_fid = fopen([struct_name '.target'], 'w');

    fprintf(target_fid, '%d\n', N );

    %Loops over all Lagrangian Pts.
    for s = 0:N-1                   % Loops over N target pts...just starts at zero bc of how first_index is defined
        fprintf(target_fid, '%d %1.16e\n', s+first_index, k_Target);
    end

    fclose(target_fid); 
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints SPRING points to a file called rubberband.spring
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Springs(xLag,yLag,k_Spring,ds_Rest,r,struct_name)

    N = length(xLag);
    
    spring_fid = fopen([struct_name '.spring'], 'w');

    fprintf(spring_fid, '%d\n', 3*N + 3/2*N ); %N MUST BE EVEN!

    %spring_force = kappa_spring*ds/(ds^2);

    %SPRINGS BETWEEN VERTICES
    for s = 1:3*N
            if s < N         
                fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, s+1, k_Spring, ds_Rest);  
            elseif s==N
                %Case s=N
                fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, 1,   k_Spring, ds_Rest);  
            elseif ( ( s>N ) && ( s<2*N ) )
                fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, s+1, k_Spring, ds_Rest);  
            elseif s==2*N
                fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, N+1,   k_Spring, ds_Rest); 
            elseif ( ( s>2*N ) && ( s<3*N ) )
                fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, s+1, k_Spring, ds_Rest);  
            elseif s==3*N
                fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, 2*N+1,   k_Spring, ds_Rest); 
            end
    end
    
    for s=1:N/2
        fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, s+N/2, k_Spring/100, 2*r);  
    end
    for s=1:N/2
        fprintf(spring_fid, '%d %d %1.16e %1.16e\n', N+s, N + s+N/2, k_Spring/100, 2*r);  
    end
    for s=1:N/2
        fprintf(spring_fid, '%d %d %1.16e %1.16e\n', 2*N+s, 2*N + s+N/2, k_Spring/100, 2*r);  
    end
    fclose(spring_fid); 
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints BEAM (Torsional Spring) points to a file called rubberband.beam
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Beams(xLag,yLag,k_Beam,C,struct_name)

    % k_Beam: beam stiffness
    % C: beam curvature
    
    N = length(xLag); % NOTE: Total number of beams = Number of Total Lag Pts. - 2

    beam_fid = fopen([struct_name '.beam'], 'w');

    fprintf(beam_fid, '%d\n', 3*N );

    %spring_force = kappa_spring*ds/(ds^2);

    %BEAMS BETWEEN VERTICES
    for s = 1:N
            if s==1 
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',N, s, s+1,   k_Beam, C(s) );  
            elseif  s <= N-1         
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',s-1, s, s+1, k_Beam, C(s) );  
            elseif s==N
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',s-1, s, 1,   k_Beam, C(s) );
            end
    end
    
    for s = N+1:2*N
            if s==N+1 
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',2*N, s, s+1,   k_Beam, C(s-N) );  
            elseif  s <= 2*N-1         
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',s-1, s, s+1, k_Beam, C(s-N) );  
            elseif s==2*N
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',s-1, s, N+1,   k_Beam, C(s-N) );
            end
    end
    
    for s = 2*N+1:3*N
            if s==2*N+1 
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',3*N, s, s+1,   k_Beam, C(s-2*N) );  
            elseif  s <= 3*N-1         
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',s-1, s, s+1, k_Beam, C(s-2*N) );  
            elseif s==3*N
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',s-1, s, 2*N+1,   k_Beam, C(s-2*N) );
            end
    end
    fclose(beam_fid); 
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: computes "curvature" of ellipse
% 
% NOTE: not curvature in the traditional geometric sense, in the 'discrete'
% sense through cross product.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function C = compute_Curvatures(xLag,yLag)

%a-x component (rmin)
%b-y component (rmax)
%C = ab / ( sqrt( a^2*sin(t)^2 + b^2*cos(t)^2  )  )^3

N = length(xLag);
C = zeros( N );

%Note: needs to be done same order as you print .beam file!
for i=1:N
   
   % Pts Xp -> Xq -> Xr (same as beam force calc.)
   
   if ( (i > 1) && (i < N) )
   
        Xp = xLag(i-1); Xq = xLag(i); Xr = xLag(i+1);
        Yp = yLag(i-1); Yq = yLag(i); Yr = yLag(i+1);
   
   elseif (i==1)
       
        Xp = xLag(N); Xq = xLag(i); Xr = xLag(i+1);
        Yp = yLag(N); Yq = yLag(i); Yr = yLag(i+1);
       
   elseif (i==N)
       
        Xp = xLag(N-1); Xq = xLag(N); Xr = xLag(1);
        Yp = yLag(N-1); Yq = yLag(N); Yr = yLag(1);
       
   end
       
   C(i) = (Xr-Xq)*(Yq-Yp) - (Yr-Yq)*(Xq-Xp); %Cross product btwn vectors
      
end


    
    
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: creates the Lagrangian structure geometry for channel
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [xLag,yLag] = give_Me_Channel_Immsersed_Boundary_Geometry(ds,L,w,Lx,Ly)

% The immsersed structure is a channel %
x = (Lx-L)/2:ds:(L+(Lx-L)/2);  %xPts
yBot = (Ly-w)/2;               %yVal for bottom of Channel
yTop = Ly - (Ly-w)/2;          %yVal for top of Channel

xLag = [x x];
yLag = [yBot*ones(1,length(x)) yTop*ones(1,length(x))];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: creates the Lagrangian structure geometry for cylinder
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [xLag,yLag] = give_Me_Cylinder_Immsersed_Boundary_Geometry(ds,r,x0,y0)

% The immsersed structure is a cylinder %

dtheta = ds/ (2.1*r);
theta = 0; i=1;
while theta < 2*pi
   xLag(i) = x0 - r*cos(theta);
   yLag(i) = y0 - r*sin(theta);
   theta = theta + dtheta;
   i=i+1;
end

   
  
