
clc;
clear;
close all;

%% =========================================================
% TRINET WIRELESS SENSOR NETWORK SIMULATION
% Protocols: LEACH, PEGASIS, MTE, TEEN, TriNet
% Generates Figures 2 to 7
% ==========================================================

%% 1. SIMULATION PARAMETERS

P.fieldSize = 1000;
P.BS = [500 500];

P.initialEnergy = 0.1;      % J
P.bandwidth = 1e6;           % 1 MHz
P.packetBits = 1024;         % bits
P.numCH = 5;
P.packetLoss = 0.10;
P.rounds = 50;

P.distanceFactor = 2;
P.maxLoad = 100;
P.bufferBits = 512;
P.delayFactor = 0.5;

% Radio energy model assumptions
P.Eelec = 50e-9;
P.Eamp = 100e-12;
P.EDA = 5e-9;

% TEEN assumptions
P.TEEN_eventProb = 0.20;
P.TEEN_HT = 0.60;
P.TEEN_ST = 0.10;

P.seed = 17;

protocols = {'LEACH','PEGASIS','MTE','TEEN','TriNet'};

nodeCounts = [50 100 150];
distanceCases = [50 100 150 200];

%% 2. NODE-BASED SIMULATION

nodeEC = zeros(3,5);
nodeSE = zeros(3,5);
nodeEE = zeros(3,5);

for a = 1:length(nodeCounts)

    n = nodeCounts(a);

    rng(P.seed+n);

    xy = P.BS + ...
        (rand(n,2)-0.5)*P.fieldSize;

    for k = 1:5

        rng(P.seed+100*a+k);

        R = runProtocol(protocols{k},xy,P);

        nodeEC(a,k) = R.energy;

        nodeSE(a,k) = R.throughput/P.bandwidth;

        nodeEE(a,k) = ...
            R.deliveredBits/max(R.energy,eps);

    end
end

%% 3. DISTANCE-BASED SIMULATION

Nfixed = 100;

distEC = zeros(4,5);
distSE = zeros(4,5);
distEE = zeros(4,5);

for a = 1:length(distanceCases)

    d = distanceCases(a);

    rng(P.seed+1000+d);

    xy = P.BS + ...
        (rand(Nfixed,2)-0.5)*(2*d);

    for k = 1:5

        rng(P.seed+2000+10*a+k);

        R = runProtocol(protocols{k},xy,P);

        distEC(a,k) = R.energy;

        distSE(a,k) = R.throughput/P.bandwidth;

        distEE(a,k) = ...
            R.deliveredBits/max(R.energy,eps);

    end
end

%% 4. DISPLAY NODE-BASED RESULTS

fprintf('\nNODE-BASED RESULTS\n');

for a = 1:length(nodeCounts)

    fprintf('\nNumber of Nodes = %d\n',nodeCounts(a));

    fprintf('%-10s %12s %15s %15s\n', ...
        'Protocol','EC(J)','SE(bps/Hz)','EE(bps/J)');

    for k = 1:5

        fprintf('%-10s %12.6f %15.6f %15.6f\n', ...
            protocols{k}, ...
            nodeEC(a,k), ...
            nodeSE(a,k), ...
            nodeEE(a,k));

    end
end

%% 5. DISPLAY DISTANCE-BASED RESULTS

fprintf('\nDISTANCE-BASED RESULTS\n');

for a = 1:length(distanceCases)

    fprintf('\nDistance = %d metres\n',distanceCases(a));

    fprintf('%-10s %12s %15s %15s\n', ...
        'Protocol','EC(J)','SE(bps/Hz)','EE(bps/J)');

    for k = 1:5

        fprintf('%-10s %12.6f %15.6f %15.6f\n', ...
            protocols{k}, ...
            distEC(a,k), ...
            distSE(a,k), ...
            distEE(a,k));

    end
end

%% 6. FIGURE 2 - ENERGY VS NUMBER OF NODES

figure;

bar(nodeCounts,nodeEC,'grouped');

xlabel('Number of Sensor Nodes');
ylabel('Energy Consumption (J)');

title('Energy Consumption vs Number of Nodes');

legend(protocols,'Location','best');

grid on;
box on;

%% 7. FIGURE 3 - ENERGY VS DISTANCE

figure;

bar(distanceCases,distEC,'grouped');

xlabel('Distance (m)');
ylabel('Energy Consumption (J)');

title('Energy Consumption vs Distance');

legend(protocols,'Location','best');

grid on;
box on;

%% 8. FIGURE 4 - SPECTRAL EFFICIENCY VS NODES

figure;

bar(nodeCounts,nodeSE,'grouped');

xlabel('Number of Sensor Nodes');
ylabel('Spectral Efficiency (bps/Hz)');

title('Spectral Efficiency vs Number of Nodes');

legend(protocols,'Location','best');

grid on;
box on;

%% 9. FIGURE 5 - SPECTRAL EFFICIENCY VS DISTANCE

figure;

bar(distanceCases,distSE,'grouped');

xlabel('Distance (m)');
ylabel('Spectral Efficiency (bps/Hz)');

title('Spectral Efficiency vs Distance');

legend(protocols,'Location','best');

grid on;
box on;

%% 10. FIGURE 6 - ENERGY EFFICIENCY VS NODES

figure;

bar(nodeCounts,nodeEE,'grouped');

xlabel('Number of Sensor Nodes');
ylabel('Energy Efficiency (bps/J)');

title('Energy Efficiency vs Number of Nodes');

legend(protocols,'Location','best');

set(gca,'YScale','log');

grid on;
box on;

%% 11. FIGURE 7 - ENERGY EFFICIENCY VS DISTANCE

figure;

bar(distanceCases,distEE,'grouped');

xlabel('Distance (m)');
ylabel('Energy Efficiency (bps/J)');

title('Energy Efficiency vs Distance');

legend(protocols,'Location','best');

set(gca,'YScale','log');

grid on;
box on;

%% 12. SAVE RESULTS

Results.nodeCounts = nodeCounts;
Results.distanceCases = distanceCases;
Results.protocols = protocols;

Results.nodeEC = nodeEC;
Results.nodeSE = nodeSE;
Results.nodeEE = nodeEE;

Results.distEC = distEC;
Results.distSE = distSE;
Results.distEE = distEE;

Results.parameters = P;

save('TriNet_Results.mat','Results');

writematrix(nodeEC,'Node_Energy.csv');
writematrix(nodeSE,'Node_Spectral_Efficiency.csv');
writematrix(nodeEE,'Node_Energy_Efficiency.csv');

writematrix(distEC,'Distance_Energy.csv');
writematrix(distSE,'Distance_Spectral_Efficiency.csv');
writematrix(distEE,'Distance_Energy_Efficiency.csv');

fprintf('\nSimulation completed successfully.\n');

%% =========================================================
% LOCAL FUNCTIONS
% =========================================================

function out = runProtocol(name,xy,P)

n = size(xy,1);

energy = P.initialEnergy*ones(n,1);

totalConsumed = 0;
deliveredPackets = 0;

for roundNo = 1:P.rounds

    alive = energy > 1e-12;

    ids = find(alive);

    if numel(ids)<2
        break;
    end

    pos = xy(ids,:);
    e = energy(ids);

    switch upper(name)

        case 'LEACH'

            ch = chooseCHs(pos,e,P.BS,P.numCH,'random');

            [tx,rx,del] = ...
                clusterRound(pos,ch,P.BS,P,false);

        case 'PEGASIS'

            [tx,rx,del] = ...
                pegasisRound(pos,P.BS,P);

        case 'MTE'

            [tx,rx,del] = ...
                mteRound(pos,P.BS,P);

        case 'TEEN'

            ch = chooseCHs(pos,e,P.BS,P.numCH,'random');

            [tx,rx,del] = ...
                clusterRound(pos,ch,P.BS,P,true);

        case 'TRINET'

            ch = chooseCHs(pos,e,P.BS,P.numCH,'trinet');

            [tx,rx,del] = ...
                trinetRound(pos,ch,P.BS,P);

        otherwise

            error('Unknown protocol');

    end

    used = tx+rx;

    used = min(used,energy(ids));

    energy(ids) = energy(ids)-used;

    totalConsumed = totalConsumed+sum(used);

    deliveredPackets = deliveredPackets+del;

end

deliveredPackets = ...
    deliveredPackets*(1-P.packetLoss);

deliveredBits = deliveredPackets*P.packetBits;

duration = max(P.rounds,1);

out.energy = totalConsumed;

out.deliveredBits = deliveredBits;

out.throughput = deliveredBits/duration;

end

%% CH SELECTION

function ch = chooseCHs(pos,e,bs,K,method)

n = size(pos,1);

K = min(K,n);

if strcmp(method,'random')

    ch = randperm(n,K);

else

    d = sqrt(sum((pos-bs).^2,2));

    er = e/max(max(e),eps);

    proximity = 1-d/max(max(d),eps);

    nqi = ones(n,1);

    score = 0.55*er + ...
            0.30*proximity + ...
            0.15*nqi;

    [~,order] = sort(score,'descend');

    ch = order(1:K);

end

end

%% LEACH AND TEEN CLUSTERING

function [tx,rx,del] = ...
    clusterRound(pos,ch,bs,P,teen)

n = size(pos,1);

tx = zeros(n,1);
rx = zeros(n,1);

del = 0;

isCH = false(n,1);
isCH(ch) = true;

dCH = pdist2local(pos,pos(ch,:));

[~,assign] = min(dCH,[],2);

active = true(n,1);

if teen

    active = rand(n,1)<P.TEEN_eventProb;

    active(ch) = true;

end

for i = 1:n

    if ~active(i) || isCH(i)
        continue;
    end

    h = ch(assign(i));

    d = norm(pos(i,:)-pos(h,:));

    tx(i) = tx(i)+txCost(P.packetBits,d,P);

    rx(h) = rx(h)+rxCost(P.packetBits,P);

    rx(h) = rx(h)+P.EDA*P.packetBits;

end

for j = 1:length(ch)

    h = ch(j);

    members = find(assign==j & active & ~isCH);

    packets = 1+numel(members);

    d = norm(pos(h,:)-bs);

    tx(h) = tx(h)+ ...
        txCost(P.packetBits*packets,d,P);

    del = del+packets;

end

end

%% PEGASIS

function [tx,rx,del] = pegasisRound(pos,bs,P)

n = size(pos,1);

tx = zeros(n,1);
rx = zeros(n,1);

del = 0;

order = zeros(n,1);

used = false(n,1);

order(1) = randi(n);

used(order(1)) = true;

for q = 2:n

    prev = order(q-1);

    ds = sqrt(sum((pos-pos(prev,:)).^2,2));

    ds(used) = inf;

    [~,order(q)] = min(ds);

    used(order(q)) = true;

end

[~,leader] = min(sum((pos-bs).^2,2));

loc = find(order==leader);

% Left branch

carry = 0;

for q = 1:loc-1

    node = order(q);

    carry = carry+1;

    next = order(q+1);

    d = norm(pos(node,:)-pos(next,:));

    tx(node) = tx(node)+ ...
        txCost(P.packetBits*carry,d,P);

    rx(next) = rx(next)+ ...
        rxCost(P.packetBits*carry,P);

end

% Right branch

carry = 0;

for q = n:-1:loc+1

    node = order(q);

    carry = carry+1;

    next = order(q-1);

    d = norm(pos(node,:)-pos(next,:));

    tx(node) = tx(node)+ ...
        txCost(P.packetBits*carry,d,P);

    rx(next) = rx(next)+ ...
        rxCost(P.packetBits*carry,P);

end

% Leader transmission

d = norm(pos(leader,:)-bs);

tx(leader) = tx(leader)+ ...
    txCost(P.packetBits*n,d,P);

del = n;

end

%% MTE

function [tx,rx,del] = mteRound(pos,bs,P)

n = size(pos,1);

tx = zeros(n,1);
rx = zeros(n,1);

del = 0;

dBS = sqrt(sum((pos-bs).^2,2));

[~,order] = sort(dBS,'descend');

packets = ones(n,1);

for q = 1:n

    i = order(q);

    closer = find(dBS<dBS(i)-1e-9);

    if isempty(closer)

        next = 0;

        target = bs;

    else

        [~,ix] = min(sum((pos(closer,:)-pos(i,:)).^2,2));

        next = closer(ix);

        target = pos(next,:);

    end

    d = norm(pos(i,:)-target);

    tx(i) = tx(i)+ ...
        txCost(P.packetBits*packets(i),d,P);

    if next==0

        del = del+packets(i);

    else

        rx(next) = rx(next)+ ...
            rxCost(P.packetBits*packets(i),P);

        packets(next) = packets(next)+packets(i);

    end

end

end

%% TRINET HYBRID PROTOCOL

function [tx,rx,del] = trinetRound(pos,ch,bs,P)

n = size(pos,1);

tx = zeros(n,1);
rx = zeros(n,1);

del = 0;

isCH = false(n,1);
isCH(ch) = true;

dCH = pdist2local(pos,pos(ch,:));

[~,assign] = min(dCH,[],2);

load = zeros(length(ch),1);

% Cluster transmission

for i = 1:n

    if isCH(i)
        continue;
    end

    h = ch(assign(i));

    d = norm(pos(i,:)-pos(h,:));

    tx(i) = tx(i)+txCost(P.packetBits,d,P);

    rx(h) = rx(h)+rxCost(P.packetBits,P);

    rx(h) = rx(h)+P.EDA*P.packetBits;

    load(assign(i)) = load(assign(i))+1;

end

% Multi-hop CH transmission

chPos = pos(ch,:);

chDist = sqrt(sum((chPos-bs).^2,2));

[~,leaderLocal] = min(chDist);

for j = 1:length(ch)

    if j==leaderLocal
        continue;
    end

    candidates = find(chDist<chDist(j));

    if isempty(candidates)

        target = 0;

        targetPos = bs;

    else

        [~,ix] = min(sum( ...
            (chPos(candidates,:)-chPos(j,:)).^2,2));

        target = candidates(ix);

        targetPos = chPos(target,:);

    end

    bits = P.packetBits*(1+load(j));

    d = norm(chPos(j,:)-targetPos);

    tx(ch(j)) = tx(ch(j))+txCost(bits,d,P);

    if target==0

        del = del+1+load(j);

    else

        rx(ch(target)) = rx(ch(target))+rxCost(bits,P);

        load(target) = load(target)+1+load(j);

    end

end

% Final CH sends to base station

bits = P.packetBits*(1+load(leaderLocal));

d = norm(chPos(leaderLocal,:)-bs);

tx(ch(leaderLocal)) = tx(ch(leaderLocal))+ ...
    txCost(bits,d,P);

del = del+1+load(leaderLocal);

end

%% RADIO ENERGY MODEL

function v = txCost(bits,d,P)

v = bits*P.Eelec + ...
    bits*P.Eamp*(d^P.distanceFactor);

end

function v = rxCost(bits,P)

v = bits*P.Eelec;

end

%% DISTANCE CALCULATION

function D = pdist2local(A,B)

D = zeros(size(A,1),size(B,1));

for i = 1:size(A,1)

    for j = 1:size(B,1)

        D(i,j) = norm(A(i,:)-B(j,:));

    end

end

end
