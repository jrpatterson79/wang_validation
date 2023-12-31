clear; close all; clc

%% Fluid Properties
mu = 1e-3; % Fluid viscosity
Kf = 2e9; % Fluid bulk modulus

%% Prescribed Poroelastic Constants
Kd = 10e9; % Drained bulk modulus
nu = 0.25; % Drained Poisson ratio
biot = 0.6; % Biot coefficent
eta = 0.1; % Porosity

%% Derived Poroelastic Constants
G = (3*Kd) * ((1-(2*nu))/(2+(2*nu))); % Shear Modulus
M_inv = (eta/Kf) + (((1-biot)*(biot-eta))/Kd); 
M = 1/M_inv; % Biot Modulus
Ku = Kd + (biot^2 * M); % Undrained bulk modulus
nu_u = ((3*Ku)-(2*G))/(2*((3*Ku)+G)); % Undrained Poisson ratio
B = (3*(nu_u-nu)) / (biot * (1-(2*nu)) * (1+nu_u)); % Skempton coefficent
gamma = (B*(1+nu_u))/(3*(1-nu_u)); % Loading (barometric) efficiency

%% Rock Hydraulic Properties
k = 1e-14; % Rock permeability 
c = k / (mu*M_inv); % Hydraulic diffusivity

%% Periodic Forcing Parameters
P = 86400; % Pressure signal period [s]
omega = (2*pi) / P;
amp = 5000; % Pressure signal amplitude[Pa]
arg = omega / (2*c);

%% MOOSE Results
file_dir = '/Users/jpatt/moose_projects/wang_validation/out_files/';
file_prefix = 'wang_val_depth_pp_';

res = readtable([file_dir 'wang_val.csv']);
time = res.time(2:end);
trim = find(time >= 432000);

num_files = 306;
% porepressure = zeros(300,num_files-1);
for i = 2:num_files
    if i <= 10
        file_name = [file_prefix '000' num2str(i-1) '.csv'];
        data = readtable([file_dir file_name]);
        porepressure(:,i-1) = data.pp;
    elseif i > 1000
        file_name = [file_prefix num2str(i-1) '.csv'];
        data = readtable([file_dir file_name]);
        porepressure(:,i-1) = data.pp;
    elseif i > 100
        file_name = [file_prefix '0' num2str(i-1) '.csv'];
        data = readtable([file_dir file_name]);
        porepressure(:,i-1) = data.pp;
    else
        file_name = [file_prefix '00' num2str(i-1) '.csv'];
        data = readtable([file_dir file_name]);
        porepressure(:,i-1) = data.pp; 
    end
end
z = abs(data.z);
for j = 1 : numel(z)
    [~, moose_phasor(j,:)] = periodic_LS_fit(time(trim), porepressure(j,trim)'-mean(porepressure(j,trim)), P);
end
%% Wang Uniaxial (Eqn. 6.72 - Wang 2000)
wang_phasor = (gamma*amp) + ((1-gamma) .* amp .* exp(-z.*sqrt(arg)) .* exp(-1j.*z.*sqrt(arg)));

%% Figures
figure
clf
subplot(1,2,1)
ax = gca;
plot(abs(moose_phasor), z, '.', 'Color', [0.7592 0 0],...
    'MarkerSize', 12)
hold on
plot(abs(wang_phasor), z, 'LineWidth', 3, 'Color', [0 0.4470 0.7410])
ax.YDir = 'reverse';
xlabel('Amplitude (Pa)')
ylabel('Depth (m)')
ax.FontSize = 30;
legend('Wang', 'MOOSE', 'Location', 'NorthWest')

subplot(1,2,2)
ax = gca;
plot(angle(moose_phasor)+pi/2, z, '.', 'Color', [0.7592 0 0],...
    'MarkerSize', 12)
hold on
plot(angle(wang_phasor), z, 'LineWidth', 3, 'Color', [0 0.4470 0.7410])
ax.XTick = [-pi:pi/2:pi];
ax.XTickLabel = {'-\pi', '-\pi/2', 0, '\pi/2', '\pi'};
ax.YDir = 'reverse';
xlim([-pi pi])
xlabel('Phase Angle (rad)')
ylabel('Depth (m)')
ax.FontSize = 30;
set(gcf, 'Position', [100 100 1440/1.1 1440])




