clc;
clear;
close all;

% 위성과 셀 관련 파라미터 설정
numCells = 19;
totalSatellites = 3;
numTimeSteps = 5;
satelliteAltitude = 10;
radius = 3;
firstRingRadius = 2 * radius;
secondRingRadius_1 = 4 * radius;
secondRingRadius_2 = 2 * sqrt(3) * radius;

satellitePositions = zeros(totalSatellites, 3);
for k = 1:totalSatellites
    angle = (k-1) * (2 * pi / totalSatellites) - pi/6;
    satellitePositions(k, :) = [6 * radius * cos(angle), 6 * radius * sin(angle), satelliteAltitude];
end

theta = linspace(0, 2 * pi, 50);
xCircle = cos(theta) * radius;
yCircle = sin(theta) * radius;

% 통신 파라미터 설정
Omega = 0.835;
m = 10;
s = 5;
tot_cells = totalSatellites * numCells;
P = zeros(tot_cells, 1); % 모든 사용자에게 초기 파워 0 할당
kB = 1.38e-23;
Trx = 290;
B = 1e6;
S = randi([1, 2], tot_cells, 1);

% 채널 계수 생성
H = generate_shadowed_rician_channel(Omega, m, s, tot_cells);

% 시뮬레이션 시작
figure;
for t = 1:numTimeSteps
    clf;
    hold on;
    axis equal;
    view(3);
    title(sprintf('3D Cell Configuration and Demand with Satellites at Time %d', t));

    for s = 1:totalSatellites
        trafficDemand = randi([10, 100], numCells, 1);
        [~, highDemandIdx] = maxk(trafficDemand, 4);
        usersPerCell = randi([5, 15], numCells, 1);  % 각 셀마다 5에서 15명 사이의 사용자
        
        % 트래픽 수요가 높은 셀에만 파워 할당
        P((s-1) * numCells + highDemandIdx) = 1.0;
        
        centerX = satellitePositions(s, 1);
        centerY = satellitePositions(s, 2);
        centerZ = 0;
        processCells(centerX, centerY, centerZ, xCircle, yCircle, firstRingRadius, secondRingRadius_1, secondRingRadius_2, trafficDemand, usersPerCell, s, t, highDemandIdx, satellitePositions, satelliteAltitude, H, P, kB, Trx, B, S, numCells);
    end

    pause(1);
    hold off;
end

%% 
function processCells(cX, cY, cZ, xC, yC, fRR, sRR1, sRR2, traffic, usersPerCell, satelliteIdx, t, highDemandIdx, satellitePositions, satelliteAltitude, H, P, kB, Trx, B, S, numCells)
    rings = [0 fRR sRR1 sRR2];
    anglesPerRing = [1, 6, 6, 6];
    
    index = 1;
    for r = 1:length(rings)
        for i = 1:anglesPerRing(r)
            if r == 1 % 중심 셀
                angle = pi / 6;
            elseif r == 2 % 첫 번째 링
                angle = (i - 1) * (2 * pi / anglesPerRing(r));
            elseif r == 3 % 두 번째 링 첫 번째 그룹
                angle = (i - 1) * (2 * pi / anglesPerRing(2)); % 첫 번째 링 셀 사이에 위치
            elseif r == 4 % 두 번째 링 두 번째 그룹
                angle = (i - 1) * (2 * pi / anglesPerRing(2))+ pi / 6 ; % 첫 번째 링 셀과 접하도록 위치
            end
            
            x = cX + rings(r) * cos(angle);
            y = cY + rings(r) * sin(angle);
            z = cZ;

            % Calculate the off-axis angle in degrees
            vecCenter = [0, 0, -satelliteAltitude];  % since the satellite is directly above the central cell at altitude 10
            vecCell = [x - cX, y - cY, -satelliteAltitude];  % Adjusting for satellite altitude
            dotProduct = dot(vecCenter, vecCell);
            magCenter = norm(vecCenter);
            magCell = norm(vecCell);
            cosTheta = dotProduct / (magCenter * magCell);
            offAxisAngle = acosd(cosTheta);
            if offAxisAngle > 90
                offAxisAngle = 180 - offAxisAngle;
            end

            % Apply a simple antenna pattern
            patternEffect = cosd(offAxisAngle)^4; % Cosine squared pattern
            % 셀의 색상 결정
            fillColor = [1-patternEffect, 1-patternEffect, 1]; % 일반 셀은 파란색으로 감쇠
            % 셀의 위치 그리기
            fill3(x + xC, y + yC, repmat(cZ, size(xC)), fillColor); % 각 셀의 원 그리기
            hold on;

            % 파워가 할당된 셀에 대해 SINR 계산
            globalIndex = satelliteIdx * numCells - numCells + index;
            if any(highDemandIdx == index)  % 파워가 할당된 셀 확인
                SINR = calculate_sinr_single(P, H, kB, Trx, B, S, globalIndex);
                fprintf('Time %d, Satellite %d, Cell %d: Position (%.2f, %.2f, %.2f), Demand %d, Users %d, SINR: %.2f dB\n', t, satelliteIdx, index, x, y, z, traffic(index), usersPerCell(index), 10*log10(SINR));
            else
                fprintf('Time %d, Satellite %d, Cell %d: Position (%.2f, %.2f, %.2f), Demand %d, Users %d, No Power Assigned\n', t, satelliteIdx, index, x, y, z, traffic(index), usersPerCell(index));
            end
            index = index + 1;
        end
    end
    scatter3(cX, cY, 10, 'ko', 'filled'); % 위성 위치를 검은색 원으로 표시
end
%% 
function SINR = calculate_sinr_single(P, H, kB, Trx, B, S, k)
    signal = P(k) * abs(H(k, k))^2;
    interference = 0;
    interference_reduction_factor = 0.01;
    
    for l = 1:length(P)
        if l ~= k
            interference = interference + P(l) * abs(H(k, l))^2 * interference_reduction_factor;
        end
    end
    noise = kB * Trx * B;
    SINR = signal / (interference + noise);
end

%% 
function H = generate_shadowed_rician_channel(Omega, m, s, N)
    % Nakagami-m 분포의 파라미터로 변환
    mu = m * s / (m + s) * 2;  % mu 값을 증가시켜 보다 좋은 채널을 생성
    omega = (m + s) * Omega / s * 1.5;  % omega 값을 증가
    
    % 감쇠 계수 적용
    attenuation_factor = 0.8;  % 간섭 감소를 위한 계수
    
    % NxN 행렬로 채널의 크기를 샘플링
    H_raw = sqrt(random('gam', mu, omega / mu, N, N));
    H = H_raw * attenuation_factor;  % 간섭 감소를 위해 전체 채널에 감쇠 계수 적용
end

