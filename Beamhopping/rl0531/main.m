clc; clear;

% Training or testing
doTraining = true;

%% Environment creation
% Observation (State) definition
ObsInfo = rlNumericSpec([57, 2]);
ObsInfo.Name = "Cell_Observation";
ObsInfo.Description = 'Current demand and total received data traffic for each cell';

% Action definition
ActInfo = rlFiniteSetSpec(1:57);
ActInfo.Name = "Selected_Cells";
ActInfo.Description = 'Indices of the cells selected to receive beams';

% Environment creation
env = rlFunctionEnv(ObsInfo, ActInfo, "swStepFunction", "swResetFunction");

% Save environment for Reinforcement Learning Designer
save('env.mat', 'env');
