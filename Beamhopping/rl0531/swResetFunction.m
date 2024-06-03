function [InitialObservation, LoggedSignals] = swResetFunction()
    % Number of cells
    numCells = 57; % 3 satellites * 19 cells each

    % Initialize state: (current data traffic demand / total received data traffic)
    InitialState = zeros(numCells, 2);
    InitialState(:, 1) = randi([1 100], numCells, 1); % Initial data traffic demand
    InitialState(:, 2) = 0; % Total received data traffic starts at 0

    InitialObservation = InitialState;
    LoggedSignals.State = InitialState;
    LoggedSignals.StepCount = 0; % Initialize step count
end
