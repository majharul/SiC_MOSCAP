function main_moscap_app()
%MAIN_MOSCAP_APP Entry point for MOSCAP C-V Explorer application.
%   Initializes parameters, runs simulation, displays results, and launches GUI.

clear variables;
clc;

% Initialize default parameters
params = moscap.defaultParameters();

% Run simulation
sim = moscap.simulateMosCapCV(params);

% Display console output
moscap.printModelReview(params, sim);
moscap.printValidationReport(params, sim);

% Plot static results
moscap.plotSimulationOnly(params, sim);

% Launch interactive GUI if desktop is available
if usejava('desktop')
    moscap.launchMosCapGui(params);
else
    fprintf('GUI skipped: desktop environment not available.\n');
end

end
