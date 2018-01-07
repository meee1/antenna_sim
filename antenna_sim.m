function cost = antenna_sim(parameters, Sim_Path)

display_geom = 0;
run_sim = 1;

physical_constants;

Sim_CSX = 'uwb.xml';

fov = 90 * pi/180;

f_0 = 6.4896e9;
f_c = 0.4992e9 / 0.3925;

helix_radius = parameters(1);
helix_length = parameters(2);
helix_pitch = parameters(3);
taper_ratio = parameters(4);

helix_turns = helix_length/helix_pitch;

lambda0 = C0/f_0;

feed_height = 1e-3;
ground_radius = 3e-2;
ground_height = 0.5e-3;
feed_R = 50;

ang = linspace(0,2*pi*helix_turns,200*helix_turns);

helix_points(1,:) = helix_radius*(1 - taper_ratio*ang/(2*pi*helix_turns)).*cos(ang);
helix_points(2,:) = helix_radius*(1 - taper_ratio*ang/(2*pi*helix_turns)).*sin(ang);
helix_points(3,:) = ang/2/pi*helix_pitch + feed_height;

mesh_res = C0 / (f_0 + f_c) / 10;

CSX = InitCSX();
CSX = AddMetal(CSX, 'Ground');
CSX = AddCylinder(CSX,'Ground',1,[0 0 -ground_height],[0 0 0],ground_radius);


%  CSX = AddMetal(CSX, 'MotorCup');
%  CSX = AddCylinder(CSX,'MotorCup',0,[0 0 feed_height+helix_turns*helix_pitch+1e-3-3.1e-2],[0 0 feed_height+helix_turns*helix_pitch+1e-3-3e-2], 3.5e-2);
%  CSX = AddCylindricalShell(CSX,'MotorCup',0,[0 0 feed_height+helix_turns*helix_pitch+1e-3-3e-2],[0 0 feed_height+helix_turns*helix_pitch+1e-3], 3.45e-2, 1e-3);

CSX = AddMetal(CSX, 'Helix');
CSX = AddCurve(CSX, 'Helix', 2, helix_points);
CSX = AddWire(CSX, 'Helix', 2, helix_points, 3.22e-4);
%  CSX = AddWire(CSX, 'Helix', 2, taper1_points, 3.22e-4);
%  CSX = AddWire(CSX, 'Helix', 2, taper2_points, 3.22e-4);
%  CSX = AddWire(CSX, 'Helix', 2, taper3_points, 3.22e-4);
%  CSX = AddWire(CSX, 'Helix', 2, taper4_points, 3.22e-4);
%  CSX = AddWire(CSX, 'Helix', 2, fin2_points, 3.22e-4);
%  CSX = AddWire(CSX, 'Helix', 2, fin3_points, 3.22e-4);
%  CSX = AddWire(CSX, 'Helix', 2, fin4_points, 3.22e-4);

%  CSX = AddMaterial(CSX, 'Structure');
%  CSX = SetMaterialProperty(CSX, 'Structure', 'Epsilon', 3);
%  CSX = AddCylindricalShell(CSX,'Structure',0,[0 0 0],[0 0 feed_height+helix_turns*helix_pitch+1e-3],(helix_radius+helix_top_radius)/2,helix_radius-helix_top_radius);
%  CSX = AddCylinder(CSX,'Structure',0,[0 0 0],[0 0 feed_height+helix_turns*helix_pitch+1e-3],helix_radius-0.4e-3);

%  CSX = AddCylinder(CSX,'Structure',0,[0 0 feed_height+helix_turns*helix_pitch+1e-3],[0 0 feed_height+helix_turns*helix_pitch+2e-3], 3.5e-2);
%  %  CSX = AddCylinder(CSX,'Structure',0,[0 0 0],[0 0 feed_height+helix_turns*helix_pitch+1e-3], 2e-3);
%  %  CSX = AddCylinder(CSX,'Structure',0,[0 0 feed_height+.5*helix_pitch],[-(helix_radius+1e-3) 0 feed_height+.5*helix_pitch], 2e-3);
%  %  CSX = AddCylinder(CSX,'Structure',0,[0 0 feed_height+helix_pitch],[helix_radius+1e-3 0 feed_height+helix_pitch], 2e-3);


[CSX port] = AddLumpedPort(CSX, 10, 1, feed_R, [helix_radius 0 0], [helix_radius 0 feed_height], [0 0 1], true);

mesh.x = [-(2*lambda0+ground_radius) linspace(-helix_radius, helix_radius, 31) (2*lambda0+ground_radius)];
mesh.y = [-(2*lambda0+ground_radius) linspace(-helix_radius, helix_radius, 31) (2*lambda0+ground_radius)];
mesh.z = [-(2*lambda0+ground_height) 0 linspace(feed_height, feed_height+helix_turns*helix_pitch, 25) (2*lambda0+feed_height+helix_turns*helix_pitch)];
mesh = SmoothMesh(mesh, mesh_res/2);
CSX = DefineRectGrid(CSX, 1, mesh);

start = [mesh.x(10)     mesh.y(10)     mesh.z(10)];
stop  = [mesh.x(end-9) mesh.y(end-9) mesh.z(end-9)];
[CSX nf2ff] = CreateNF2FFBox(CSX, 'nf2ff', start, stop);

FDTD = InitFDTD( 'NrTs', 30000, 'EndCriteria', 1e-5, 'OverSampling', 2);
FDTD = SetGaussExcite(FDTD, f_0, f_c );
BC   = {'MUR' 'MUR' 'MUR' 'MUR' 'MUR' 'PML_8'};
FDTD = SetBoundaryCond(FDTD, BC);

if (run_sim==1 || display_geom==1)
    confirm_recursive_rmdir(0);
    [status, message, messageid] = rmdir( Sim_Path, 's' );
    [status, message, messageid] = mkdir( Sim_Path );

    WriteOpenEMS([Sim_Path '/' Sim_CSX], FDTD, CSX);

    if (display_geom==1)
        CSXGeomPlot([Sim_Path '/' Sim_CSX]);
        return;
    end

    RunOpenEMS( Sim_Path, Sim_CSX);
end

freq  = linspace(f_0-0.4992e9, f_0+0.4992e9, 200);
port = calcPort(port, Sim_Path, freq);

max_s11 = max(20*log10(abs(port.uf.ref ./ port.uf.inc)));

cost = max_s11;
return;

phi = [0] * pi / 180;
theta = [-180:5:180] * pi / 180;

[delay, fidelity, nf2ff] = DelayFidelity(nf2ff, port, Sim_Path, -1i, 1, theta, phi, f_0, f_c, 'Mode', 0, 'center', [0 0 0]);

figure
plot(theta.' * 180/pi, delay*C0*1000);
title(["delay ", suffix, " (mm)"]);

figure
plot(theta.' * 180/pi, fidelity)
title(["fidelity"]);

figure
for i = 1:numel(nf2ff.freq)
    if (nf2ff.freq(i) >= f_0-f_c*0.3925 || nf2ff.freq(i) <= f_0+f_c*0.3925)
        plotFFdB(nf2ff, 'xaxis', 'theta', 'freq_index', i);
        hold on;
    end
end
drawnow;
title(["gain ", suffix, " / dBi"]);

% save the plots in order to compare them afer simulating the different channels
%  print(1, ["s11_", suffix, ".png"]);
%  print(2, ["farfield_", suffix, ".png"]);
%  print(3, ["delay_mm_", suffix, ".png"]);
%  print(4, ["fidelity_", suffix, ".png"]);

% calculate the far field at phi=0 degrees and at phi=90 degrees

%  thetaRange = unique([0:2:90 90:4:180]);
%  phiRange = (0:8:360) - 180;
%  disp( 'calculating the 3D far field...' );
%
%  nf2ff = CalcNF2FF(nf2ff, Sim_Path, f_0, thetaRange*pi/180, phiRange*pi/180,'Mode',0,'Outfile','3D_Pattern.h5','Verbose',1);
%
%  directivity = nf2ff.P_rad{1}/nf2ff.Prad*4*pi;
%  directivity_CPRH = abs(nf2ff.E_cprh{1}).^2./max(nf2ff.E_norm{1}(:)).^2*nf2ff.Dmax;
%  directivity_CPLH = abs(nf2ff.E_cplh{1}).^2./max(nf2ff.E_norm{1}(:)).^2*nf2ff.Dmax;
%
%  DumpFF2VTK([Sim_Path '/3D_Pattern.vtk'],directivity,thetaRange,phiRange);
%  DumpFF2VTK([Sim_Path '/3D_Pattern_CPRH.vtk'],directivity_CPRH,thetaRange,phiRange);
%  DumpFF2VTK([Sim_Path '/3D_Pattern_CPLH.vtk'],directivity_CPLH,thetaRange,phiRange);
return;
