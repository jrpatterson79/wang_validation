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

%% Load MOOSE Results
results_dir = '/Users/jpatt/moose_projects/wang_validation/out_files/';
results_file = 'wang_val.csv';
gold_file = 'atm_tides_out.csv';
moose_results = readtable([results_dir results_file]);
time = moose_results.time(2:end);
moose_del_pp = moose_results.p100(2:end)-moose_results.p100(2);

% Gold results
gold_results = readtable([results_dir gold_file]);

%% Periodic Atmospheric Forcing
P = 86400; % Atmospheric forcing period
omega = (2*pi) / P;
atm_tide = 5000 * sin (2*pi*(time./3600./24)); % Atmospheric forcing signal

%% Calculate Amplitudes
% Atmospheric tide amplitude
[~, atm_tide_phasor] = periodic_LS_fit(time, atm_tide, P);
atm_tide_amp = abs(atm_tide_phasor);

% MOOSE Amplitude 100-m depth
trim = find(time >= 5 * P);
[~, moose_pp_phasor] = periodic_LS_fit(time(trim), moose_del_pp(trim), P);
moose_amp = abs(moose_pp_phasor);

%% Wang Uniaxial (Eqn. 6.60 - Wang 2000)
z = 1000;

arg = (1j*omega) / c;
wang_phasor = gamma * atm_tide_amp * (1 - exp(-z * sqrt(arg)));
wang_amp = abs(wang_phasor);
wang_pp = wang_amp * sin(2*pi*(time./3600./24)); % Analytical pp at 100 m

%% Figures
figure
clf
ax = gca;
plot(time./86400, moose_del_pp, 'LineWidth', 2)
hold on
plot(time./86400, wang_pp, 'ko', 'LineWidth', 2)
plot(gold_results.time(2:end)./86400, gold_results.p100(2:end)-gold_results.p100(2), 'kd',...
    'MarkerFaceColor', [0.7592 0 0])
xlabel('Time (days)')
ylabel('Porepressure (Pa)')
ax.FontSize = 30;
legend('MOOSE', 'Wang', 'Gold')
set(gcf, 'Position', [100 100 2025 2025/2.667])




