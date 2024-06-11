function [nextObs, reward, isDone, loggedSignals] = satStepFunction(action, loggedSignals)
    % 다음 상태와 보상을 계산하는 함수

    % 상태 및 로깅 신호 불러오기
    numCells = 57;
    timestep = loggedSignals.timestep;
    demand = loggedSignals.demand;
    received = loggedSignals.received;

    % 현재 타임스텝에서 각 셀의 데이터 트래픽 수요 생성 (인구 비례 가정)
    currentDemand = rand(numCells, 1); % 임의의 수요 생성 예시

    % 누적된 demand 업데이트
    demand = demand + currentDemand;

    % action에 따른 빔 서비스 (4개의 셀에 대해 각 위성이 빔 제공)
    % action은 12개의 셀에 대한 인덱스를 포함한다고 가정
    for i = 1:length(action)
        cellIdx = action(i);
        received(cellIdx) = received(cellIdx) + (demand(cellIdx) / 2);
        demand(cellIdx) = demand(cellIdx) / 2; % demand의 절반만큼 서비스 제공
    end

    % 다음 상태 계산
    nextObs = demand;

    % 타임스텝 업데이트
    loggedSignals.demand = demand;
    loggedSignals.received = received;
    loggedSignals.timestep = timestep + 1;

    % 보상 계산: 각 셀이 한 주기동안 receive한 데이터 트래픽의 누적된 총량 / demand 총량
    if timestep >= 50
        demandTotal = sum(loggedSignals.demand);
        receivedTotal = sum(loggedSignals.received);
        reward = min(receivedTotal ./ demandTotal);
        isDone = true;
    else
        reward = 0;
        isDone = false;
    end
end
