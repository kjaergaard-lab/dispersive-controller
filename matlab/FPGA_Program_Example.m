function varargout = FPGA_Program_Example
%% Define the spartan object
sp = SpartanImaging;

%% Set imaging parameters
sp.probeType = 'Rb';
sp.imageDelay = 0.16;
sp.enableProbe = 1;
sp.enableRepump = 0;

sp.crossbeamOnTime = 50;
sp.timeOfFlight = 20;
sp.additionalWaveguideOnTime = 0;

sp.probeWidthRb = 15;
sp.probeWidthK = 15;
sp.probeWidthV = 15;
sp.probeWidthF = 15;

sp.probeShutterDelay = 2.5;
sp.camDelay = 0.25;
sp.camLoopTime = 30;
sp.repumpProbeWidth = 150;
sp.repumpProbeDelay = 150e-3;
sp.repumpShutterDelay = 2.5;

%% Rb magnetic field calibration
% sp.pulses.addPulse(320,5,'Rb');




%% Calculate values, check for errors, and write the configuration
sp.checkValues.expandVariables.makeSequence;
sp.upload;

%% Return variables
if nargout == 1
    varargout{1} = sp;
end


