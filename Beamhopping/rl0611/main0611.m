ObsInfo = rlNumericSpec([57 1], 'LowerLimit', 0, 'UpperLimit', Inf);
ObsInfo.Name = 'observations';
ActInfo = rlFiniteSetSpec(1:57); % 가능한 행동 범위 설정
ActInfo.Name = 'actions';

% 환경 생성
env = rlFunctionEnv(ObsInfo, ActInfo, "satStepFunction", "satResetFunction");

% 네트워크 구조 정의
obsPath = featureInputLayer(57, 'Normalization', 'none', 'Name', 'observations');
fc1 = fullyConnectedLayer(128, 'Name', 'fc1');
relu1 = reluLayer('Name', 'relu1');
fc2 = fullyConnectedLayer(128, 'Name', 'fc2');
relu2 = reluLayer('Name', 'relu2');
meanLayer = fullyConnectedLayer(57, 'Name', 'mean');
stdLayer = fullyConnectedLayer(57, 'Name', 'std');
tanhMean = tanhLayer('Name', 'tanhMean');
softplusStd = softplusLayer('Name', 'softplusStd');

% Create actor network
actorNetwork = layerGraph(obsPath);
actorNetwork = addLayers(actorNetwork, [fc1, relu1, fc2, relu2, meanLayer, stdLayer, tanhMean, softplusStd]);

% Connect actor network layers
actorNetwork = connectLayers(actorNetwork, 'observations', 'fc1');
actorNetwork = connectLayers(actorNetwork, 'fc1', 'relu1');
actorNetwork = connectLayers(actorNetwork, 'relu1', 'fc2');
actorNetwork = connectLayers(actorNetwork, 'fc2', 'relu2');
actorNetwork = connectLayers(actorNetwork, 'relu2', 'mean');
actorNetwork = connectLayers(actorNetwork, 'mean', 'tanhMean');
actorNetwork = connectLayers(actorNetwork, 'relu2', 'std');
actorNetwork = connectLayers(actorNetwork, 'std', 'softplusStd');

% Create critic network
criticNetwork = layerGraph(obsPath);
criticFC1 = fullyConnectedLayer(128, 'Name', 'criticFC1');
criticRelu1 = reluLayer('Name', 'criticRelu1');
criticFC2 = fullyConnectedLayer(128, 'Name', 'criticFC2');
criticRelu2 = reluLayer('Name', 'criticRelu2');
valueLayer = fullyConnectedLayer(1, 'Name', 'value');

criticNetwork = addLayers(criticNetwork, [criticFC1, criticRelu1, criticFC2, criticRelu2, valueLayer]);

% Connect critic network layers
criticNetwork = connectLayers(criticNetwork, 'observations', 'criticFC1');
criticNetwork = connectLayers(criticNetwork, 'criticFC1', 'criticRelu1');
criticNetwork = connectLayers(criticNetwork, 'criticRelu1', 'criticFC2');
criticNetwork = connectLayers(criticNetwork, 'criticFC2', 'criticRelu2');
criticNetwork = connectLayers(criticNetwork, 'criticRelu2', 'value');

% Actor와 Critic 네트워크를 rlRepresentation 객체로 변환
actorOptions = rlRepresentationOptions('LearnRate', 0.00025, 'GradientThreshold', 1);
criticOptions = rlRepresentationOptions('LearnRate', 0.00025, 'GradientThreshold', 1);

actor = rlStochasticActorRepresentation(actorNetwork, ObsInfo, ActInfo, 'Observation', {'observations'}, actorOptions);
critic = rlValueRepresentation(criticNetwork, ObsInfo, 'Observation', {'observations'}, criticOptions);

% PPO 에이전트 옵션 설정
agentOpts = rlPPOAgentOptions;
agentOpts.ExperienceHorizon = 50;
agentOpts.ClipFactor = 0.2;
agentOpts.EntropyLossWeight = 0.01;
agentOpts.MiniBatchSize = 64;

% PPO 에이전트 생성
agent = rlPPOAgent(actor, critic, agentOpts);

% 훈련 옵션 설정
trainOpts = rlTrainingOptions;
trainOpts.MaxEpisodes = 1000;
trainOpts.MaxStepsPerEpisode = 50;
trainOpts.ScoreAveragingWindowLength = 10;
trainOpts.StopTrainingCriteria = 'EpisodeReward';
trainOpts.StopTrainingValue = 500;
trainOpts.SaveAgentCriteria = 'EpisodeReward';
trainOpts.SaveAgentValue = 500;

% 훈련 수행
trainingStats = train(agent, env, trainOpts);
