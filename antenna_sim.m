%function cost = antenna_sim(parameters, Sim_Path)

display_geom = 0;
run_sim = 1;
debug_pec = 0;

physical_constants;

Sim_Path = 'tmp';
Sim_CSX = 'uwb.xml';

fov = 90 * pi/180;

f_0 = 6.4896e9;
f_c = 0.4992e9 / 0.3925;

% +6.0429e-03, +1.0871e-02, +4.4621e-03, +4.2901e-03

helix_radius = round(6.0429e-03*1e6)/1e6;
helix_length = round(1.0871e-02*1e6)/1e6;
helix_pitch2 = round(4.4621e-03*1e6)/1e6;
helix_pitch1 = round(4.2901e-03*1e6)/1e6;

helix_turns = 0.25*(4.0*helix_length - helix_pitch1 + helix_pitch2)/helix_pitch2;
taper_ratio = 1;

lambda0 = C0/f_0;

feed_height = 0.6e-3;
wire_radius = 5e-4;
ground_radius = 1.55e-2;
ground_height = 0.4e-3;
feed_R = 50;

ang = linspace(0,pi/2,50);
helix_points1(1,:) = helix_radius*cos(ang);
helix_points1(2,:) = helix_radius*sin(ang);
helix_points1(3,:) = feed_height + ang/(2*pi)*helix_pitch1;

ang = linspace(pi/2,2*pi*helix_turns,200*(helix_turns-.25));

helix_points2(1,:) = helix_radius*cos(ang);
helix_points2(2,:) = helix_radius*sin(ang);
helix_points2(3,:) = feed_height + .25*helix_pitch1 + (ang/(2*pi)-.25)*helix_pitch2;

mesh_res = C0 / (f_0 + f_c) / 10;

CSX = InitCSX();
CSX = AddMetal(CSX, 'Ground');
CSX = AddMetal(CSX, 'Helix');
CSX = AddMetal(CSX, 'Cup');
CSX = AddMaterial(CSX, 'FR4');
CSX = AddMaterial(CSX, 'Nylon');
CSX = AddMaterial(CSX, 'delrin');
CSX = AddMaterial(CSX, 'air');
CSX = SetMaterialProperty(CSX, 'FR4', 'Epsilon', 4.3);
CSX = SetMaterialProperty(CSX, 'Nylon', 'Epsilon', 2.73);
CSX = SetMaterialProperty(CSX, 'delrin', 'Epsilon', 4);
CSX = SetMaterialProperty( CSX, 'air', 'Epsilon', 1, 'Mue', 1 );

CSX = AddCylinder(CSX,'Ground',1,[0 9e-4 -ground_height],[0 9e-4 0],ground_radius);
CSX = AddBox(CSX,'Ground',1,[helix_radius-2.6e-3 -4.5e-3 -ground_height],[helix_radius-1.2e-2 6e-3 -ground_height-3e-3]);
CSX = AddCylinder(CSX, 'air', 2, [helix_radius 0 -ground_height-1e-4], [helix_radius 0 1e-4], 1.25e-3);
CSX = AddBox(CSX, 'delrin', 2, [helix_radius-2.6e-3 -3.0e-3 -ground_height],[helix_radius-4e-4 3.0e-3 -ground_height-2e-3]);
CSX = AddBox(CSX, 'FR4', 1,[helix_radius+7e-3 -5.8e-3 -ground_height-2e-3],[helix_radius-1.6e-2 7.2e-3 -ground_height-3e-3]);

recess_depth = 15e-3;

CSX = AddCylindricalShell(CSX, 'Cup', 4, [0 0 recess_depth], [0 0 recess_depth-2.5e-2], 3.15e-2, 1e-3);
CSX = AddCylinder(CSX, 'Cup', 4, [0 0 recess_depth-2.5e-2], [0 0 recess_depth-2.5e-2-1e-3], 3.2e-2);

%  CSX = AddCylinder(CSX, 'air', 2, [helix_radius-2.7e-3 1.25e-2 -ground_height-1e-4], [helix_radius-2.7e-3 1.25e-2 1e-4], 1e-3);
%  CSX = AddCylinder(CSX, 'air', 2, [helix_radius-2.7e-3 -1.07e-2 -ground_height-1e-4], [helix_radius-2.7e-3 -1.07e-2 1e-4], 2.25e-3);
%  CSX = AddCylinder(CSX, 'air', 2, [helix_radius-2.7e-3-13e-3 1.25e-2 -ground_height-1e-4], [helix_radius-2.7e-3-13e-3 1.25e-2 1e-4], 2.25e-3);
%  CSX = AddCylinder(CSX, 'air', 2, [helix_radius-2.7e-3-13e-3 -1.07e-2 -ground_height-1e-4], [helix_radius-2.7e-3-13e-3 -1.07e-2 1e-4], 2.25e-3);

CSX = AddBox(CSX, 'Ground', 2, [helix_radius-1.6e-2-4.3e-3 -6.3e-3-8e-3 -ground_height-3e-3],[helix_radius-2.6e-3 7.7e-3+8e-3 -ground_height-3.1e-3]);

CSX = AddBox(CSX, 'Ground', 2, [helix_radius-2e-3 -6.3e-3 -ground_height-3e-3],[helix_radius+2e-3 7.7e-3 -ground_height-3.1e-3]);
CSX = AddBox(CSX, 'Ground', 2, [helix_radius-2e-3 -6.3e-3 0],[helix_radius+2e-3 -5.8e-3 -ground_height-3.1e-3]);
CSX = AddBox(CSX, 'Ground', 2, [helix_radius-2e-3  7.2e-3 0],[helix_radius+2e-3  7.7e-3 -ground_height-3.1e-3]);
%  CSX = AddBox(CSX, 'Ground', 2, [helix_radius+7e-3 -6.3e-3 0],[helix_radius+7.5e-3  7.7e-3 -ground_height-3.1e-3]);

CSX = AddCurve(CSX, 'Helix', 3, helix_points1);
CSX = AddWire(CSX, 'Helix', 3, helix_points1, wire_radius);
CSX = AddCurve(CSX, 'Helix', 3, helix_points2);
CSX = AddWire(CSX, 'Helix', 3, helix_points2, wire_radius);
CSX = AddCurve(CSX, 'Helix', 3, [[helix_radius 0 -ground_height-2e-3]; [helix_radius 0 feed_height]]');
CSX = AddWire(CSX, 'Helix', 3, [[helix_radius 0 -ground_height-2e-3]; [helix_radius 0 feed_height]]', wire_radius);

CSX = AddBox(CSX, 'Helix', 3, [helix_radius-2.0e-3 -5e-4 -ground_height-2e-3], [helix_radius 5e-4 -ground_height-2e-3]);

inside_radius = helix_radius-wire_radius-1e-3;
outside_radius = helix_radius;
CSX = AddCylindricalShell(CSX,'Nylon',0,[0 0 0],[0 0 feed_height+helix_length+wire_radius+2e-3], (inside_radius+outside_radius)/2, outside_radius-inside_radius);

inside_radius = feed_height+helix_length+wire_radius+5e-3;
outside_radius = feed_height+helix_length+wire_radius+2e-3+5e-3;
CSX = AddCylindricalShell(CSX,'Nylon',0,[-1.5e-3 0 -4e-3],[1.5e-3 0 -4e-3], (inside_radius+outside_radius)/2, outside_radius-inside_radius);

CSX = AddCylinder(CSX,'Nylon',1,[0 0 recess_depth],[0 0 recess_depth+2e-3],3.2e-2);

[CSX port] = AddLumpedPort(CSX, 999, 1, feed_R, [helix_radius-2.0e-3 0 -ground_height-2e-3], [helix_radius-2.6e-3 0 -ground_height-2e-3], [1 0 0], true);

CSX = AddDump(CSX, 'Jt','DumpType',3,'FileType',1);
CSX = AddBox( CSX, 'Jt', 0, [-ground_radius, -ground_radius, -ground_height-3.1e-3], [ground_radius, ground_radius, feed_height+helix_length]);

mesh.x = [-(2*lambda0+ground_radius) SmoothMeshLines2([-3.1e-3, -ground_radius, -helix_radius, 0, helix_radius-2.6e-3, helix_radius-2.0e-3, helix_radius, ground_radius, 3.1e-3], wire_radius/2) (2*lambda0+ground_radius)];
mesh.y = mesh.x;
mesh.z = [-(2*lambda0+ground_height) SmoothMeshLines2([recess_depth-2.5e-2-1e-3, -ground_height-3.1e-3, -ground_height-2e-3, 0, feed_height, feed_height+helix_length], wire_radius/2) (2*lambda0+feed_height+helix_length)];

mesh = SmoothMesh(mesh, mesh_res);
CSX = DefineRectGrid(CSX, 1, mesh);

start = [mesh.x(11)     mesh.y(11)     mesh.z(11)];
stop  = [mesh.x(end-10) mesh.y(end-10) mesh.z(end-10)];
[CSX nf2ff] = CreateNF2FFBox(CSX, 'nf2ff', start, stop);

FDTD = InitFDTD( 'NrTs', 200000, 'EndCriteria', 1e-5, 'OverSampling', 2);
FDTD = SetGaussExcite(FDTD, f_0, f_c );
BC   = {'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8'};
FDTD = SetBoundaryCond(FDTD, BC);

if (run_sim==1 || display_geom==1 || debug_pec==1)
    confirm_recursive_rmdir(0);
    [status, message, messageid] = rmdir( Sim_Path, 's' );
    [status, message, messageid] = mkdir( Sim_Path );

    WriteOpenEMS([Sim_Path '/' Sim_CSX], FDTD, CSX);

    if (display_geom==1)
        CSXGeomPlot([Sim_Path '/' Sim_CSX]);
        return;
    end

    if (debug_pec==1)
        RunOpenEMS( Sim_Path, Sim_CSX, '--debug-PEC --no-simulation');
        return;
    end

    RunOpenEMS( Sim_Path, Sim_CSX);
end

%  ConvertHDF5_VTK([Sim_Path '/Jt.h5'],[Sim_Path '/Jf'],'Frequency',f_0,'FieldName','J-Field');

freq = linspace(f_0-0.4992e9, f_0+0.4992e9, 11);
theta = linspace(0, fov/2, 20);
phi = linspace(0, 2*pi*0.9, 8);

port = calcPort(port, Sim_Path, freq);
nf2ff = CalcNF2FF(nf2ff, Sim_Path, freq, theta, phi,'Mode',1);

s11 = port.uf.ref ./ port.uf.inc;

s11_db = 20*log10(abs(s11))

vswr = (1+abs(s11)) ./ (1-abs(s11))
max_vswr = max(vswr)

rhcp_gain = 4*pi*(abs(nf2ff.E_cprh{5}).^2./abs(nf2ff.E_norm{5}).^2 .* nf2ff.P_rad{5}) ./ port.P_inc(5)

min_rhcp_gain = min(min(rhcp_gain))

vswr_target = 2.5;

cost = max([1, 1+(max_vswr-vswr_target)*10])/min_rhcp_gain

%  [delay, fidelity] = DelayFidelity(nf2ff, port, Sim_Path, -1i, 1, theta, phi, f_0, f_c, 'Mode', 1, 'Center', [0,0,feed_height+helix_length]);
%
%  disp(delay*C0*100);
%
%  figure;
%  hold on;
%  polar(phi.', delay(1,:)*C0*100, '-r');
%  polar(phi.', delay(2,:)*C0*100, '-g');
%  polar(phi.', delay(3,:)*C0*100, '-b');
%  polar(phi.', delay(4,:)*C0*100, '-y');
%  polar(phi.', delay(5,:)*C0*100, '-c');

return;
