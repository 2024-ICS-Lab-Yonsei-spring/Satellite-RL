function [InitialObservation, InitialState] = swResetFunction()
% Reset function to place custom computing resource allocation.

% user 1 ~ user 3 computing resource
% Return initial environment state variables as logged signals.
InitialState = randi([5 10],3,1);
InitialObservation = InitialState;

end

