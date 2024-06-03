clc; clear;

% 트레이닝/테스트 여부 결정
doTraining = true;

%% 환경 생성
% Observation (State) 정의
ObsInfo = rlNumericSpec([3 1]);
ObsInfo.Name = "User_observation";
ObsInfo.Description = 'u1, u2, u3';

% Action 정의
ActInfo = rlNumericSpec([3 1]);
ActInfo.Name = "User_action";
ActInfo.LowerLimit=-2;
ActInfo.UpperLimit=2;

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
% summary(criticNet)

% Actor 네트워크 생성 및 초기화
% Define common input path layer
commonPath = [ 
    featureInputLayer(prod(ObsInfo.Dimension),Name="comPathIn")
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(1,Name="comPathOut") 
    ];

% Define mean value path
meanPath = [
    fullyConnectedLayer(15,Name="meanPathIn")
    reluLayer
    fullyConnectedLayer(prod(ActInfo.Dimension));
    tanhLayer;
    scalingLayer(Name="meanPathOut",Scale=ActInfo.UpperLimit) 
    ];

% Define standard deviation path
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
%plot(actorNet)

actor = rlContinuousGaussianActor(actorNet, ObsInfo, ActInfo, ...
    "ActionMeanOutputNames","meanPathOut",...
    "ActionStandardDeviationOutputNames","stdPathOut",...
    ObservationInputNames="comPathIn");

%% 에이전트 형성 및 파라미터 설정
% getAction(actor,{rand(ObsInfo.Dimension)})
agent = rlPPOAgent(actor,critic)

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
    Plots="training-progress")

if doTraining
    % 트레이닝
    trainStats = train(agent,env,trainOpts);
    save("ResultNetwork.mat","agent")
else
    % 테스트
    load("ResultNetwork.mat","agent");
    simOpts = rlSimulationOptions;
    simOpts.MaxSteps = 20;
    % simOpts.NumSimulations = 50;
    ep_mean_r = zeros(1,50);
    % 이 아래는 본인이 어떤 그래프를 보여주고 싶은지에 따라 자유롭게
    for test_iter = 1:50 
        experience = sim(env,agent,simOpts);
        ep_r_lst = experience.Reward;
        ep_mean_r(test_iter) = mean(ep_r_lst);
    end
    plot(ep_mean_r)
end

