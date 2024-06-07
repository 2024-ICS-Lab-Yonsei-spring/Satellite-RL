clc; clear;

% 트레이닝/테스트 여부 결정
doTraining = true;

%% 환경 생성
% Observation (State) 정의
ObsInfo = rlNumericSpec([1 114]); % 19 cells의 demand와 channel gain 값 (3 satellites, 19 cells * 2)
ObsInfo.Name = "User_observation";
ObsInfo.Description = 'Demand and Channel Gain for each cell';

% Action 정의
ActInfo = rlNumericSpec([19 3]); % 19 cells의 transmission power
ActInfo.Name = "User_action";
ActInfo.LowerLimit=0;
ActInfo.UpperLimit=10^3.8; % Total_power 정의 필요

% 환경 생성 (Step, Reset 함수를 만들어야 함)
env = rlFunctionEnv(ObsInfo,ActInfo,"swStepFunction","swResetFunction");

%% 인공신경망 생성
% Critic 네트워크 생성 및 초기화
criticNet = [
    featureInputLayer(prod(ObsInfo.Dimension))
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(1)
    ];

criticNet = dlnetwork(criticNet);
criticNet = initialize(criticNet);
critic = rlValueFunction(criticNet,ObsInfo);

% Actor 네트워크 생성 및 초기화
commonPath = [ 
    featureInputLayer(prod(ObsInfo.Dimension),Name="comPathIn")
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(1,Name="comPathOut") 
    ];

meanPath = [
    fullyConnectedLayer(15,Name="meanPathIn")
    reluLayer
    fullyConnectedLayer(prod(ActInfo.Dimension));
    tanhLayer;
    scalingLayer(Name="meanPathOut",Scale=ActInfo.UpperLimit) 
    ];

sdevPath = [
    fullyConnectedLayer(15,"Name","stdPathIn")
    reluLayer
    fullyConnectedLayer(prod(ActInfo.Dimension));
    softplusLayer(Name="stdPathOut") 
    ];

actorNet = dlnetwork;
actorNet = addLayers(actorNet,commonPath);
actorNet = addLayers(actorNet,meanPath);
actorNet = addLayers(actorNet,sdevPath);

actorNet = connectLayers(actorNet,"comPathOut","meanPathIn/in");
actorNet = connectLayers(actorNet,"comPathOut","stdPathIn/in");

actor = rlContinuousGaussianActor(actorNet, ObsInfo, ActInfo, ...
    "ActionMeanOutputNames","meanPathOut",...
    "ActionStandardDeviationOutputNames","stdPathOut",...
    ObservationInputNames="comPathIn");

%% 에이전트 형성 및 파라미터 설정
agent = rlPPOAgent(actor,critic);

agent.AgentOptions.ExperienceHorizon = 1024;
agent.AgentOptions.DiscountFactor = 0.95;

agent.AgentOptions.CriticOptimizerOptions.LearnRate = 8e-3;
agent.AgentOptions.CriticOptimizerOptions.GradientThreshold = 1;
agent.AgentOptions.ActorOptimizerOptions.LearnRate = 8e-3;
agent.AgentOptions.ActorOptimizerOptions.GradientThreshold = 1;

%% 트레이닝/테스트
trainOpts = rlTrainingOptions(...
    MaxEpisodes=300,...
    MaxStepsPerEpisode=20,...
    Verbose=true,...
    Plots="training-progress");

if doTraining
    % 트레이닝
    trainStats = train(agent,env,trainOpts);
    save("ResultNetwork.mat","agent")
else
    % 테스트
    load("ResultNetwork.mat","agent");
    simOpts = rlSimulationOptions;
    simOpts.MaxSteps = 20;
    ep_mean_r = zeros(1,50);
    for test_iter = 1:50 
        experience = sim(env,agent,simOpts);
        ep_r_lst = experience.Reward;
        ep_mean_r(test_iter) = mean(ep_r_lst);
    end
    plot(ep_mean_r)
end
