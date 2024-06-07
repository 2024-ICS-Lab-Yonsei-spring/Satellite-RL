function [InitialObservation, InitialState] = swResetFunction()
    % Reset function to initialize demand and channel gain

    % Initial demand and channel gain values (random initialization for example)
    InitialDemand = poissrnd(10^4, 3, 19) * 5000; % 3 satellites, 19 cells
    InitialChannelGain = zeros(3, 19);
    b = 0.126;
    m = 10.1;
    omega = 0.835;

    for i = 1:3
        for j = 1:19
            InitialChannelGain(i, j) = ShadowedRicianRandGen(b, m, omega, 1);
        end
    end

    InitialState = [InitialDemand(:); InitialChannelGain(:)]'; % Transpose to 1x114
    InitialObservation = InitialState;
end
