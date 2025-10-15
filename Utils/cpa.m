%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hardware Oriented Security - Matlab CPA Exercise %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clear workspace
%clear;

% SSAES SBox
% SBOX=[6 11 5 4 2 14 7 10 9 13 15 12 3 1 0 8];
% 
% % Parameters - Traces
% n_traces = 30000;
% n_nibbles = 16;
% trace_len = 100012;
% scale = 3;
% m_off = 0;
% 
% % Loading data
% plaintexts = load_io('/scratch/net4/HOS/Traces/plaintexts.txt', n_traces, n_nibbles);
% ciphertexts = load_io('/scratch/net4/HOS/Traces/ciphertexts.txt', n_traces, n_nibbles);
% traces = load_traces('/scratch/net4/HOS/Traces/traces.txt', n_traces, trace_len);
% % 
% % % Scaling in mV
% for i=1:n_traces
%     for j=1:trace_len
%         traces(i,j) = ((traces(i,j)/127)*4)*scale+m_off;
%     end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Exercise 1 - Area Selection %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot one trace and then select the appropriate part of the traces.

% Plot the first trace
% figure(1);
% plot(traces(1,:));
% title('Power Consumption of an Encryption');

% Initial CPA area selection
% offset_initial = 20000;
% segmentLength = 5200;
% 
% % Reduce the traces
% traces_red = zeros(n_traces,segmentLength);
% for i=1:n_traces
% 	for j=1:segmentLength
% 		traces_red(i,j) = traces(i,j+offset_initial);
% 	end
% end

% Plot the first reduced trace
% figure(3);
% plot(traces_red(1,:));
% title('Selected Power Consumption');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% EXERCISE 2 - Key Recovery %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% key_guess = [0,1,2,3];
ham_values = zeros(16,n_traces);
% 
% for key=1:16
%     for i=1:n_traces
%         ham_values(key,i) = ham_w(SBOX(bitxor(plaintexts(i,1),key-1) +1)); % bitxor
%     end
% end
for byte=1:16
    for key=1:16
            ham_values(key,:) = ham_w(SBOX(bitxor(plaintexts(:,byte),key-1) +1)); % bitxor
    end
% numerator = 0;
    n1=0;
    n2=0;
    n3=0;
    d1 = 0;
    d2 = 0;
    corr_array = zeros(16, segmentLength);

    for key=1:16
        for j=1:segmentLength
            n1=0;
            n2=0;
            n3=0;
            d1 = 0;
            d2 = 0;
            for i=1:n_traces
                n1 = n1 + (traces_red(i,j)*ham_values(key,i));
                n2 = n2 +  ham_values(key,i);
                n3 = n3 + traces_red(i,j);

                d1 = d1 + ham_values(key,i)^2;
                d2 = d2 + traces_red(i,j)^2;
            end
            numerator = (n_traces*n1) - (n2*n3);
            denominator = sqrt(((n_traces*d1)-n2^2)*((n_traces*d2)-(n3^2)));
            corr_array(key,j) = abs(numerator/denominator);
        end
    end

    max_array = zeros(16);
    for val=1:16
        max_array(val) = max(corr_array(val,:));
    end
    [M,I] = max(max_array);
    display(I);
end
% CPA steps:
%   - Guess (key byte)
%   - Hypothesis (compute intermediate value)
%   - Correlation
%   - Correct key byte (highest correlation)

