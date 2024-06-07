function [NextObs, Reward, IsDone, LoggedSignals] = swStepFunction(Action, LoggedSignals)
    % 환경 상태 변수 불러오기
    State = LoggedSignals.State;
    
    % 각 변수 재정의
    num_cells = 19;
    num_satellites = 3;
    Total_power = 10^(3.8);
    b = 0.126;
    m = 10.1;
    omega = 0.835;
    kb = 1.38*(10^(-23)); % Boltz만 상수
    Trx = 300; % 잡음 온도
    B = 400*(10^6); % 총 대역폭
    Gm = 10^(3.59); % 일반적인 gain 값

    % 채널 게인 및 수요를 현재 상태에서 추출
    Channel_gain = reshape(State(num_cells*num_satellites+1:end), [num_satellites, num_cells]);
    Demand_cell = reshape(State(1:num_cells*num_satellites), [num_satellites, num_cells]);

    % 액션 반영하여 송신 전력 설정
    Beam_power = reshape(Action, [num_satellites, num_cells]);
    
    % SINR 설정
    Beam_SINR = cell(num_satellites, num_cells);
    for s = 1:num_satellites
        for i = 1:num_cells
            sum_interference = 0;
            for j= 1 : num_cells 
                if i ~= j
                    sum_interference = sum_interference + Beam_power(s, j) * Channel_gain(s, j);
                end
            end
            Beam_SINR{s, i} = (Beam_power(s, i) * Channel_gain(s, i)) / ((kb * Trx * B) + sum_interference);
        end
    end

    % 용량 설정
    Beam_capacity = cell(num_satellites, num_cells); 
    for s = 1:num_satellites
        for i = 1:num_cells
            Beam_capacity{s, i} = B * log2(1 + Beam_SINR{s, i});
        end
    end

    % min_Cm_Dm 계산
    min_Cm_Dm = cell(num_satellites, 1);  % 각 위성별 최소값을 저장할 cell 배열
    temp = cell(num_satellites, num_cells);  % 각 위성의 각 셀별 Beam_capacity / Demand_cell 비율을 저장할 cell 배열
    
    for s = 1:num_satellites
        for i = 1:num_cells
            % Beam_capacity와 Demand_cell의 비율을 계산하여 temp에 저장
            temp{s, i} = Beam_capacity{s, i} / Demand_cell{s, i};      
        end
    end
    
    % 각 위성(s)별로 최소값 계산
    for s = 1:num_satellites
        % temp의 s번째 행에서 모든 열에 대해 최소값을 계산
        min_Cm_Dm{s} = min_exclude_zero(cell2mat(temp(s,:)));
    end
    
    % 보상 계산 (min_Cm_Dm 값의 최소값)
    Reward = min(cell2mat(min_Cm_Dm));

    % 다음 상태 설정
    NextObs = State; % 상태는 업데이트하지 않음

    % 에피소드 종료 조건 설정
    IsDone = false; % 에피소드 종료 조건 설정하지 않음

    % 로그 신호 업데이트
    LoggedSignals.State = NextObs;
end

% 보조 함수: min_exclude_zero
function min_val = min_exclude_zero(array)
    non_zero_elements = array(array > 0);
    if isempty(non_zero_elements)
        min_val = 0;
    else
        min_val = min(non_zero_elements);
    end
end
