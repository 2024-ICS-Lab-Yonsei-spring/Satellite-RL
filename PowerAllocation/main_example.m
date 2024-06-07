clc; clear;

ObsInfo = rlNumericSpec([4 1]);
ObsInfo.Name = "CartPole States";
ObsInfo.Description = 'x, dx, theta, dtheta';

ActInfo = rlFiniteSetSpec([-10 10]);
ActInfo.Name = "CartPole Action";

env = rlFunctionEnv(ObsInfo,ActInfo,"myStepFunction","myResetFunction");

rng(0);
InitialObs = reset(env)
[NextObs,Reward,IsDone,Info] = step(env,-10);
NextObs