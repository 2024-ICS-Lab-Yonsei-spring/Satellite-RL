function [InitialObservation, InitialState] = swResetFunction()
    % Initialize data traffic demand and received data traffic
    numCells = 57;
    dataTrafficDemand = randi([1, 10], numCells, 1); % Initial demand for each cell
    receivedDataTraffic = zeros(numCells, 1); % Initial received traffic for each cell
    InitialState = [dataTrafficDemand; receivedDataTraffic];
    InitialObservation = dataTrafficDemand ./ (receivedDataTraffic + 1); % Initial state
end
