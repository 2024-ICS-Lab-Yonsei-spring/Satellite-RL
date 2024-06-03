function [NextObs, Reward, IsDone, LoggedSignals] = swStepFunction(Action, LoggedSignals)
    % Number of cells
    numCells = 57;
    numBeamsPerSat = 4;
    numSats = 3;

    % Unpack current state from LoggedSignals
    State = LoggedSignals.State;
    currentDemand = State(:, 1);
    totalReceived = State(:, 2);
    
    % Update step count
    LoggedSignals.StepCount = LoggedSignals.StepCount + 1;

    % Select the top cells for each satellite
    ratios = currentDemand ./ (totalReceived + 1); % Adding 1 to avoid division by zero
    
    % Initialize allocated beams
    allocatedBeams = zeros(numCells, 1);
    
    for sat = 1:numSats
        startIdx = (sat - 1) * 19 + 1;
        endIdx = sat * 19;
        [~, sortedIndices] = sort(ratios(startIdx:endIdx), 'descend');
        selectedCells = sortedIndices(1:numBeamsPerSat) + (sat - 1) * 19;
        allocatedBeams(selectedCells) = 1;
    end

    % Simulate data reception (for simplicity, assume each beam satisfies the entire current demand)
    newReceived = allocatedBeams .* currentDemand;

    % Update state
    newDemand = currentDemand; % Assuming demand remains constant for simplicity
    newTotalReceived = totalReceived + newReceived;

    NextState = [newDemand, newTotalReceived];
    NextObs = NextState;
    LoggedSignals.State = NextState;

    % Calculate reward as the minimum of (total received / total demand) over all cells
    totalReceivedPerCycle = newTotalReceived; % Assuming each step is within one cycle
    totalDemandPerCycle = newDemand; % Assuming demand remains constant per cycle
    Reward = min(totalReceivedPerCycle ./ (totalDemandPerCycle + 1)); % Adding 1 to avoid division by zero

    % Define terminal condition (one episode ends after a fixed number of steps)
    IsDone = LoggedSignals.StepCount >= 50; % Example: end after 20 steps
end
