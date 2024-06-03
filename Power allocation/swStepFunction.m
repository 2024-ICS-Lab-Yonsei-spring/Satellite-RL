function [NextObs,Reward,IsDone,NextState] = swStepFunction(Action,State)

Total_server_resource = 10;

% 유저 1 ~ 유저 3의 현재 컴퓨팅 요청량을 언팩
u1_c = State(1);
u2_c = State(2);
u3_c = State(3);

% 총량 서버 리소스를 유저 3명에게 분배
Resource_allocation = Total_server_resource.* softmax(Action)./ sum(softmax(Action));

% 유저 1 ~ 유저 3의 새로운 요청량과 컴퓨팅 되는 양을 계산
u1_c_next = max(u1_c + 5 * rand - Resource_allocation(1),0); 
u2_c_next = max(u2_c + 5 * rand - Resource_allocation(2),0); 
u3_c_next = max(u3_c + 5 * rand - Resource_allocation(3),0); 

NextState = [u1_c_next; u2_c_next; u3_c_next];
NextObs = NextState;

% main 문에서 최대 step 수를 제한하거나 (Done = false로 두기), 
% 특정 조건이 되면 Done이 되도록 설정할 수도 있음.
IsDone = false;
% 리워드 설정 (임의로 컴퓨팅이 많이 처리될수록 높은 리워드가 되도록 함)
Reward = 10 - u1_c_next - u2_c_next - u3_c_next;
end