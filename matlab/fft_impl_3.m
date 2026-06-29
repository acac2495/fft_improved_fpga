%% 2. Input signal — Q5.11 (Triangular Wave)
% Triangle wave: ramps up from 0 to 1 over first half, ramps down from 1 to 0 over second half
% Q5.11: scale by 2^11 = 2048
N = 32;
scale_input = 2^11;

input_r = zeros(1, N);
for n = 0 : N-1
    if n < N/2
        input_r(n+1) = n / (N/2 - 1);        % ramp up:   0 -> 1  (samples 0..15)
    else
        input_r(n+1) = (N-1-n) / (N/2 - 1);  % ramp down: 1 -> 0  (samples 16..31)
    end
end
input_i = zeros(1, N);     % imaginary part = 0

input_r_int = round(input_r * scale_input);  % peaks at 2048
input_i_int = round(input_i * scale_input);  % all zeros

% write hex files (bit-reversed order for FFT input)
br_idx = zeros(1, N);
for n = 0 : N-1
    b = dec2bin(n, log2(N));
    br_idx(n+1) = bin2dec(fliplr(b));
end

fid = fopen('real_mem.hex', 'w');
for i = 1 : N
    val = input_r_int(br_idx(i) + 1);
    fprintf(fid, '%04x\n', typecast(int16(val), 'uint16'));
end
fclose(fid);

fid = fopen('imag_mem.hex', 'w');
for i = 1 : N
    val = input_i_int(br_idx(i) + 1);
    fprintf(fid, '%04x\n', typecast(int16(val), 'uint16'));
end
fclose(fid);

%% 3. Verify with MATLAB FFT
fprintf('\nExpected FFT output (floating point):\n');
x = input_r + 1j * input_i;
X = fft(x);
for k = 0 : N-1
    fprintf('X[%2d] = %8.4f + j%8.4f\n', k, real(X(k+1)), imag(X(k+1)));
end