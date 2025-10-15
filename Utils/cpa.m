%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% Correlation Power Analysis %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % Clear workspace
% clear;
% 
% % SSAES SBox
SBOX=[6 11 5 4 2 14 7 10 9 13 15 12 3 1 0 8];

% Parameters - Traces
n_traces = 30000;
n_nibbles = 16;
trace_len = 100012;
scale = 3;
m_off = 0;

% Loading data
plaintexts = load_io('/scratch/net4/HOS/Traces/plaintexts.txt', n_traces, n_nibbles);
ciphertexts = load_io('/scratch/net4/HOS/Traces/ciphertexts.txt', n_traces, n_nibbles);
traces = load_traces('/scratch/net4/HOS/Traces/traces.txt', n_traces, trace_len);

% % % Scaling in mV
for i=1:n_traces
    for j=1:trace_len
        traces(i,j) = ((traces(i,j)/127)*4)*scale+m_off;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Area Selection %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % Initial CPA area selection
offset_initial = 20000;
segmentLength = 5200;

% Reduce the traces
traces_red = zeros(n_traces,segmentLength);
for i=1:n_traces
	for j=1:segmentLength
		traces_red(i,j) = traces(i,j+offset_initial);
	end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% Key Recovery %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ham_values = zeros(1,n_traces);

% Known key (16 nibbles, decimal 15 down to 0)
known_key = [15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0];


time_indices = zeros(1, 16);  % Store time indices for each byte

for byte = 1:16
    % Compute ham_values for all possible keys 0:15
    ham_values = zeros(16, n_traces);
    for key = 0:15
        % bitxor with key, SBOX lookup (+1 for 1-based index), ham_w
        ham_values(key+1, :) = ham_w(SBOX(bitxor(plaintexts(:, byte), key) + 1));
    end
    
    corr_array = zeros(16, segmentLength);
    
    for key = 0:15
        key_idx = key + 1;
        for j = 1:segmentLength
            n1 = 0; n2 = 0; n3 = 0; d1 = 0; d2 = 0;
            for i = 1:n_traces
                n1 = n1 + (traces_red(i, j) * ham_values(key_idx, i));
                n2 = n2 + ham_values(key_idx, i);
                n3 = n3 + traces_red(i, j);
                d1 = d1 + ham_values(key_idx, i)^2;
                d2 = d2 + traces_red(i, j)^2;
            end
            numerator = (n_traces * n1) - (n2 * n3);
            denominator = sqrt(((n_traces * d1) - n2^2) * ((n_traces * d2) - n3^2));
            if denominator == 0
                corr_array(key_idx, j) = 0;
            else
                corr_array(key_idx, j) = abs(numerator / denominator);
            end
        end
    end
    
    % Max corr over j for each key
    max_array = max(corr_array, [], 2);
    
    % Find best key
    [~, best_key_idx] = max(max_array);
    best_key = best_key_idx - 1;
    
    known_key_byte = known_key(byte);
    if best_key == known_key_byte
        disp(['Byte ' num2str(byte) ': Known key ' num2str(known_key_byte) ' is the best guess. Good!']);
    else
        disp(['Byte ' num2str(byte) ': Warning: Best guess ' num2str(best_key) ' != known ' num2str(known_key_byte)]);
        % Still use known for time_idx, or switch to best if prefer
    end
    
    % Use known key for time index
    use_key_idx = known_key_byte + 1;
    [~, time_idx] = max(corr_array(use_key_idx, :));
    time_indices(byte) = time_idx;
    
    disp(['Time index for byte ' num2str(byte) ': ' num2str(time_idx)]);
end

% Final output
disp('Time indices for all bytes:');
disp(time_indices);

figure;
for byte = 1:16
    % Recalculate ham_values and corr_array for plotting (optional optimization)
    ham_values = zeros(16, n_traces);
    for key = 0:15
        ham_values(key+1, :) = ham_w(SBOX(bitxor(plaintexts(:, byte), key) + 1));
    end

    corr_array = zeros(16, segmentLength);
    for key = 0:15
        key_idx = key + 1;
        for j = 1:segmentLength
            n1 = sum(traces_red(:, j) .* ham_values(key_idx, :)');
            n2 = sum(ham_values(key_idx, :));
            n3 = sum(traces_red(:, j));
            d1 = sum(ham_values(key_idx, :).^2);
            d2 = sum(traces_red(:, j).^2);

            numerator = (n_traces * n1) - (n2 * n3);
            denominator = sqrt(((n_traces * d1) - n2^2) * ((n_traces * d2) - n3^2));
            if denominator == 0
                corr_array(key_idx, j) = 0;
            else
                corr_array(key_idx, j) = abs(numerator / denominator);
            end
        end
    end

    % Compute max correlation per key
    max_corr_per_key = max(corr_array, [], 2);

    % Find the best key
    [~, best_key_idx] = max(max_corr_per_key);
    best_key = best_key_idx - 1;

    % Plot
    subplot(4, 4, byte); % 16 subplots (one per byte)
    plot(0:15, max_corr_per_key, '-o', 'LineWidth', 1.5);
    hold on;
    plot(best_key, max_corr_per_key(best_key_idx), 'r*', 'MarkerSize', 10);
    hold off;
    title(['Byte ' num2str(byte) ' | Best key: ' num2str(best_key)]);
    xlabel('Key Guess (0–15)');
    ylabel('Max Correlation');
    grid on;
end

sgtitle('Correlation Power Analysis (CPA) - Key Guess per Byte');

