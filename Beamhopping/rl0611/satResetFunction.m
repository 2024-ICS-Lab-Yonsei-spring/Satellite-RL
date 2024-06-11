function [initialObservation, loggedSignals] = satResetFunction()
    % 초기 상태와 로깅 신호를 반환하는 함수

    % 초기 상태 설정
    numCells = 57;
    initialObservation = zeros(numCells, 1); % 초기 state는 모든 셀에 대해 0으로 설정

    % 로깅 신호 초기화
    loggedSignals.demand = initialObservation; % 초기 demand는 0으로 설정
    loggedSignals.received = zeros(numCells, 1); % 초기 received 데이터 트래픽은 0으로 설정
    loggedSignals.timestep = 1; % 타임스텝 초기화
end
