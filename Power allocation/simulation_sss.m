% 위성 및 원형 cell들의 중심 좌표 계산
% 위성 중심 좌표
S1 = [0, 150*sqrt(3)*1e3, 600*1e3];
S2 = [-150*1e3, 0, 600*1e3];
S3 = [150*1e3, 0, 600*1e3];
S = [
    0, 150*sqrt(3)*1e3, 600*1e3;   % S1의 위치
    -150*1e3, 0, 600*1e3;          % S2의 위치
    150*1e3, 0, 600*1e3            % S3의 위치
]; 


% 각 위성이 커버하는 원형 cell의 개수
num_cells = 19;

% 각 원형 cell들의 중심 좌표 계산
cells = cell(3, num_cells, 3);


% S1 위성의 cell 중심 좌표 계산
cells{1, 1, 1} = 0;
cells{1, 1, 2} = 150*sqrt(3)*1e3;
cells{1, 1, 3} = 0;

for i = 1:6
    x = 40 * cos((pi/3) * (i-1))*1e3;
    y = 150 * sqrt(3)*1e3 + 40 * sin((pi/3) * (i-1))*1e3;
    cells{1, i+1, 1} = x;
    cells{1, i+1, 2} = y;
    cells{1, i+1, 3} = 0;
end

for i = 1:12
    x = 80 * cos((pi/6) * (i-1))*1e3;
    y = 150 * sqrt(3)*1e3 + 80 * sin((pi/6) * (i-1))*1e3;
    cells{1, 7+i, 1} = x;
    cells{1, 7+i, 2} = y;
    cells{1, 7+i, 3} = 0;
end


% S2 위성의 cell 중심 좌표 계산
cells{2, 1, 1} = -150*1e3;
cells{2, 1, 2} = 0;
cells{2, 1, 3} = 0;

for i = 1:6
    x = -150*1e3 + 40 * cos((pi/3) * (i-1))*1e3;
    y = 40 * sin((pi/3) * (i-1))*1e3;
    cells{2, i+1, 1} = x;
    cells{2, i+1, 2} = y;
    cells{2, i+1, 3} = 0;
end

for i = 1:12
    x = -150*1e3 + 80 * cos((pi/6) * (i-1))*1e3;
    y = 80 * sin((pi/6) * (i-1))*1e3;
    cells{2, 7+i, 1} = x;
    cells{2, 7+i, 2} = y;
    cells{2, 7+i, 3} = 0;
end

% S3 위성의 cell 중심 좌표 계산
cells{3, 1, 1} = 150*1e3;
cells{3, 1, 2} = 0;
cells{3, 1, 3} = 0;

for i = 1:6
    x = 150*1e3 + 40 * cos((pi/3) * (i-1))*1e3;
    y = 40 * sin((pi/3) * (i-1))*1e3;
    cells{3, i+1, 1} = x;
    cells{3, i+1, 2} = y;
    cells{3, i+1, 3} = 0;
end

for i = 1:12
    x = 150*1e3 + 80 * cos((pi/6) * (i-1))*1e3;
    y = 80 * sin((pi/6) * (i-1))*1e3;
    cells{3, 7+i, 1} = x;
    cells{3, 7+i, 2} = y;
    cells{3, 7+i, 3} = 0;
end

% 위성과 각 위성이 커버하는 원형 cell의 중심 각도 계산
angles = cell(3, num_cells);
for s = 1:3
    satellite_x = S(s, 1);
    satellite_y = S(s, 2);
    satellite_z = S(s, 3);
    
    for i = 1:num_cells
        cell_x = cells{s, i, 1};
        cell_y = cells{s, i, 2};
        cell_z = cells{s, i, 3};
        
        % atan2 함수를 사용하여 각도 계산
        angle = atan2(sqrt((satellite_y-cell_y)^2+(satellite_x-cell_x)^2),satellite_z-cell_z);
        angles{s, i} = angle * (180 / pi); % 라디안을 도로 변환
    end
end


% 각도 출력
for s = 1:3
    fprintf('위성 S%d:\n', s);
    for i = 1:num_cells
        fprintf('Cell %d: %.2f도\n', i, angles{s, i});
    end
    fprintf('\n');
end




% 각도마다 antenna gain(Gt) 설정6
Gm = 10^(3.59); % 일반적인 gain 값
Gt = cell(3, num_cells); % 각 cell의 antenna gain 저장
for s = 1:3
    for i = 1:num_cells
        angle = angles{s, i};
        angle_radians = deg2rad(angle);
        if i == 1
            Gt{s, i} = Gm;
        else
            parameter1 = (2 * pi * 0.15 * sin(angle_radians)*3*1e8) / (400*1e6);
            Gt{s, i} = Gm * 4*(abs(besselj(1, parameter1)/parameter1)^2);
        end
    end  
end




% 거리마다 Path Loss(PL) 설정
PL = cell(3, num_cells); 
for s = 1:3
    satellite_x = S(s, 1);
    satellite_y = S(s, 2);
    satellite_z = S(s, 3);
    for i = 1:num_cells
        cell_x = cells{s, i, 1};
        cell_y = cells{s, i, 2};
        cell_z = cells{s, i, 3};
        distance = sqrt((satellite_x-cell_x)^2+(satellite_y-cell_y)^2+(satellite_z-cell_z)^2);
        
        PL{s,i} = (4*pi*distance/(400*1e6))^2;
   
    end
end

num_cells=19;

iterations=5000;
min_Cm_Dm_random_all = zeros(3, iterations);
min_Cm_Dm_demand_all = zeros(3, iterations);
min_Cm_Dm_channel_all = zeros(3, iterations);

for it = 1:iterations
    % % Shadowed Rician Fading pdf
    
    b = 0.126;
    m = 10.1;
    omega = 0.835;
    
    
    
    % Channel gain 설정
    Channel_gain = cell(3, num_cells); 
    
    for s = 1:3
        for i = 1:num_cells
            
            % pdf_values{s, i} = (alpha^m) * lambda * exp(-x_values{s, i} * lambda) .* hypergeom(m, 1, beta * x_values{s, i});
            SR = ShadowedRicianRandGen(b,m,omega,1);
            
            Channel_gain{s,i} = Gt{s, i} * PL{s,i} * SR  ;        
       
        end
    end
    
    % User 설정 (Random, uniform)
    
    User_cell = cell(3, num_cells); 
    for s = 1:3
        for i = 1:num_cells
               
            User_cell{s, i} = poissrnd(10^4,1) ;  
    
        end
    end
    
    
    % Demand of traffic m-th beam (Random, uniform)
    
    Demand_cell = cell(3, num_cells); 
    for s = 1:3
        for i = 1:num_cells
    
            Demand_cell{s, i} = User_cell{s, i}*10000 ;  
    
        end
    end
    
    % Beam power 설정 
    Total_power = 10^(3.8);
    
    % Active beam number 설정 (위성마다 다르게 설정)
    active_beam_numbers = [4 4 4];
    
    % Beam power 1/N, random index
    Beam_power_random = cell(3, num_cells); 
    
    for s = 1:3
        list = zeros(1, num_cells);
        active_indices = randperm(num_cells, active_beam_numbers(s));
        list(active_indices) = 1;
        
        for i = 1:num_cells
            Beam_power_random{s, i} = 0;
            if list(i) == 1
                Beam_power_random{s, i} = Total_power / active_beam_numbers(s);
            end
        end
    end
    
    % Beam power 1/N, Demand index
    Beam_power_demand = cell(3, num_cells); 
    
    for s = 1:3
        list = zeros(1, num_cells);
    
        % Demand에 따라 정렬된 index를 찾기
        [~, sorted_indices] = sort(cell2mat(Demand_cell(s, :)), 'descend');
        
        % 상위 active_beam_number 개의 index 선택
        active_indices = sorted_indices(1:active_beam_numbers(s));
        list(active_indices) = 1;
        
        % 각 셀에 전력 할당
        for i = 1:num_cells
            Beam_power_demand{s, i} = 0;
            if list(i) == 1
                Beam_power_demand{s, i} = Total_power / active_beam_numbers(s);
            end
        end
    end
    
    % Beam power 1/N, Channel gain index
    Beam_power_channel = cell(3, num_cells); 
    
    for s = 1:3
        list = zeros(1, num_cells);
        
        % Channel_gain에 따라 정렬된 index를 찾기
        [~, sorted_indices] = sort(cell2mat(Channel_gain(s, :)), 'descend');
        
        % 상위 active_beam_number 개의 index 선택
        active_indices = sorted_indices(1:active_beam_numbers(s));
        list(active_indices) = 1;
        
        % 각 셀에 전력 할당
        for i = 1:num_cells
            Beam_power_channel{s, i} = 0;
            if list(i) == 1
                Beam_power_channel{s, i} = Total_power / active_beam_numbers(s);
            end
        end
    end
    
    
    
    
    % SINR 설정 (1/N Distribution)
    kb = 1.38*(10^(-23)); % Boltzman constant
    Trx = 300; % Noise temperature
    B = 400*(10^6); % Total Bandwidth
    
    % SINR 1/n 
    Beam_SINR_random = cell(3, num_cells); 
    Beam_SINR_demand = cell(3, num_cells); 
    Beam_SINR_channel = cell(3, num_cells); 
    for s = 1:3
        for i = 1:num_cells
            sum_interference_random = 0;
            sum_interference_demand = 0;
            sum_interference_channel = 0;
    
            for j= 1 : num_cells 
                interference_random = 0 ;
                interference_demand = 0 ;
                interference_channel = 0 ;
                if i~=j
                    interference_random = Beam_power_random{s, j}*Channel_gain{s,j} ;
                    interference_demand = Beam_power_demand{s, j}*Channel_gain{s,j} ;
                    interference_channel = Beam_power_channel{s, j}*Channel_gain{s,j} ;
                end
                sum_interference_random = sum_interference_random + interference_random;
                sum_interference_demand = sum_interference_demand + interference_demand;
                sum_interference_channel = sum_interference_channel + interference_channel;
            end
            Beam_SINR_random{s, i} = (Beam_power_random{s, i}*Channel_gain{s,i}) / ((kb*Trx*B)+sum_interference_random) ;  % 1/n씩
            Beam_SINR_demand{s, i} = (Beam_power_demand{s, i}*Channel_gain{s,i}) / ((kb*Trx*B)+sum_interference_demand) ;  % 1/n씩
            Beam_SINR_channel{s, i} = (Beam_power_channel{s, i}*Channel_gain{s,i}) / ((kb*Trx*B)+sum_interference_channel) ;  % 1/n씩
    
        end
    end
    
    % Capacity 설정 (1/N Distribution)
    
    % Capacity 1/n
    Beam_capacity_random = cell(3, num_cells); 
    Beam_capacity_demand = cell(3, num_cells); 
    Beam_capacity_channel = cell(3, num_cells); 
    for s = 1:3
        for i = 1:num_cells
    
            Beam_capacity_random{s, i} = B * log(1+Beam_SINR_random{s, i}) ;  
            Beam_capacity_demand{s, i} = B * log(1+Beam_SINR_demand{s, i}) ;  
            Beam_capacity_channel{s, i} = B * log(1+Beam_SINR_channel{s, i}) ;  
    
        end
    end
    
    
    
    
    % minimum Cm/Dm 
    % minimum Cm/Dm 1/n
    min_Cm_Dm_random = cell(3, 1);  % 각 위성별 최소값을 저장할 cell 배열
    min_Cm_Dm_demand = cell(3, 1);  
    min_Cm_Dm_channel = cell(3, 1);  
    temp_random = cell(3, num_cells);  % 각 위성의 각 셀별 Beam_capacity / Demand_cell 비율을 저장할 cell 배열
    temp_demand = cell(3, num_cells);
    temp_channel = cell(3, num_cells);
    
    for s = 1:3
        for i = 1:num_cells
            % Beam_capacity와 Demand_cell의 비율을 계산하여 temp에 저장
            temp_random{s, i} = Beam_capacity_random{s, i} / Demand_cell{s, i}; 
            temp_demand{s, i} = Beam_capacity_demand{s, i} / Demand_cell{s, i};
            temp_channel{s, i} = Beam_capacity_channel{s, i} / Demand_cell{s, i};
        end
    end
    
    % 각 위성(s)별로 최소값 계산
    for s = 1:3
        % temp의 s번째 행에서 모든 열에 대해 최소값을 계산
        min_Cm_Dm_random{s} = min_exclude_zero(cell2mat(temp_random(s,:)));
        min_Cm_Dm_demand{s} = min_exclude_zero(cell2mat(temp_demand(s,:)));
        min_Cm_Dm_channel{s} = min_exclude_zero(cell2mat(temp_channel(s,:)));
    end
    
    % 결과 저장
    min_Cm_Dm_random_all(:, it) = cell2mat(min_Cm_Dm_random);
    min_Cm_Dm_demand_all(:, it) = cell2mat(min_Cm_Dm_demand);
    min_Cm_Dm_channel_all(:, it) = cell2mat(min_Cm_Dm_channel);
end

min_Cm_Dm_random_avg = mean(min_Cm_Dm_random_all, 2);
min_Cm_Dm_demand_avg = mean(min_Cm_Dm_demand_all, 2);
min_Cm_Dm_channel_avg = mean(min_Cm_Dm_channel_all, 2);

% 결과 출력
fprintf('Random Allocation 평균 min_Cm_Dm:\n');
disp(min_Cm_Dm_random_avg);
fprintf('Demand-based Allocation 평균 min_Cm_Dm:\n');
disp(min_Cm_Dm_demand_avg);
fprintf('Channel Gain-based Allocation 평균 min_Cm_Dm:\n');
disp(min_Cm_Dm_channel_avg);


% 3D 그래픽 플로팅
figure;
hold on;
% 위성 표시
plot3(S1(1), S1(2), S1(3), 'ro', 'MarkerSize', 5, 'LineWidth', 2);
plot3(S2(1), S2(2), S2(3), 'go', 'MarkerSize', 5, 'LineWidth', 2);
plot3(S3(1), S3(2), S3(3), 'bo', 'MarkerSize', 5, 'LineWidth', 2);
% 각 cell의 중심 좌표와 반지름 정보를 이용하여 원형 모양의 셀을 표시
for s = 1:3
    for i = 1:num_cells
        % 각 cell의 중심 좌표
        center_x = cells{s, i, 1};
        center_y = cells{s, i, 2};
        center_z = cells{s, i, 3};
        
        % 반지름
        radius = 25*1e3;
        
        % 원의 각도 범위
        theta = linspace(0, 2*pi, 100);
        
        % 원의 좌표 계산
        circle_x = radius * cos(theta) + center_x;
        circle_y = radius * sin(theta) + center_y;
        circle_z = center_z * ones(size(theta));
        
        % 원형 모양의 셀 표시
        plot3(circle_x, circle_y, circle_z, 'k', 'LineWidth', 1);
    end
end

xlabel('X 축');
ylabel('Y 축');
zlabel('Z 축');
title('위성과 각 위성이 커버하는 원형 cell들');
grid on;
view(3);
axis([-300*1e3, 300*1e3, -200*1e3, 400*1e3, 0*1e3, 800*1e3]);
hold off;