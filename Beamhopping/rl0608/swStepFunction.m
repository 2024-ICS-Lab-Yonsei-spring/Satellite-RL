function [NextObs, Reward, IsDone, NextState] = swStepFunction(Action, State)
    numCells = 57;
    totalSatellites = 3;
    cellsPerSatellite = 19;
    beamsPerSatellite = 4;

    dataTrafficDemand = State(1:numCells);
    receivedDataTraffic = State(numCells+1:end);

    % Decode actions: Selecting top 4 cells for each of the 3 satellites
    selectedCells = zeros(totalSatellites * beamsPerSatellite, 1);
    for i = 1:totalSatellites
        startIdx = (i-1)*cellsPerSatellite + 1;
        endIdx = i*cellsPerSatellite;
        [~, idx] = maxk(dataTrafficDemand(startIdx:endIdx), beamsPerSatellite);
        selectedCells((i-1)*beamsPerSatellite+1:i*beamsPerSatellite) = startIdx - 1 + idx;
    end

    % Update received data traffic for selected cells
    for cellIdx = selectedCells'
        receivedDataTraffic(cellIdx) = receivedDataTraffic(cellIdx) + dataTrafficDemand(cellIdx);
    end

    % Update state
    NextState = [dataTrafficDemand; receivedDataTraffic];
    NextObs = dataTrafficDemand ./ (receivedDataTraffic + 1); % Updated state

    % Compute reward
    minRatio = min(receivedDataTraffic ./ dataTrafficDemand);
    Reward = minRatio;

    % Episode termination condition
    IsDone = false;
end
