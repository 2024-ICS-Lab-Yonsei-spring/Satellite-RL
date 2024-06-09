clc; clear;

doTraining = true;

%% Environment setup
numCells = 57;
ObsInfo = rlNumericSpec([numCells 1], 'LowerLimit', 0, 'UpperLimit', inf);
ObsInfo.Name = 'CellTrafficRatios';

ActInfo = rlFiniteSetSpec(1:numCells);
ActInfo.Name = 'SelectedCells';

env = rlFunctionEnv(ObsInfo, ActInfo, 'swStepFunction', 'swResetFunction');

%% Neural network setup for the Critic and Actor
criticNetwork = [
    featureInputLayer(numCells, 'Name', 'CellTrafficRatios')
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(1)
];

criticOptions = rlRepresentationOptions('LearnRate', 1e-3, 'GradientThreshold', 1);
critic = rlValueRepresentation(criticNetwork, ObsInfo, 'Observation', {'CellTrafficRatios'}, criticOptions);

actorNetwork = [
    featureInputLayer(numCells, 'Name', 'CellTrafficRatios')
    fullyConnectedLayer(100)
    reluLayer
    fullyConnectedLayer(numCells)
    softmaxLayer
];

actorOptions = rlRepresentationOptions('LearnRate', 1e-3, 'GradientThreshold', 1);
actor = rlStochasticActorRepresentation(actorNetwork, ObsInfo, ActInfo, 'Observation', {'CellTrafficRatios'}, actorOptions);

%% Agent setup
agentOpts = rlPPOAgentOptions('ExperienceHorizon', 50, 'ClipFactor', 0.2, ...
    'EntropyLossWeight', 0.01, 'MiniBatchSize', 64, 'NumEpoch', 3);
agent = rlPPOAgent(actor, critic, agentOpts);

%% Training options
trainOpts = rlTrainingOptions('MaxEpisodes', 500, 'MaxStepsPerEpisode', 50, ...
    'Verbose', true, 'Plots', 'training-progress', 'StopTrainingCriteria', 'AverageReward', ...
    'StopTrainingValue', 500);

if doTraining
    trainStats = train(agent, env, trainOpts);
    save('trainedAgent.mat', 'agent');
else
    load('trainedAgent.mat', 'agent');
    simOpts = rlSimulationOptions('MaxSteps', 50);
    experience = sim(env, agent, simOpts);
    totalReward = sum(experience.Reward)
end
