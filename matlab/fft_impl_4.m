clear; clc;

N = 128;  % change this for different FFT sizes

%% 1. Twiddle factors — Q1.18
k = 0 : (N/2 - 1);
twiddle = exp(-1j * 2 * pi * k / N);
twiddle_r = real(twiddle);
twiddle_i = imag(twiddle);

% Q1.18: scale by 2^18 = 262144
% using 2^18 not 2^18-1 to avoid gain error accumulation across levels
scale_twiddle = 2^18;
twiddle_r_int = round(twiddle_r * scale_twiddle);
twiddle_i_int = round(twiddle_i * scale_twiddle);

% clamp to [-262144, 262143] (19-bit signed range)
twiddle_r_int = max(min(twiddle_r_int,  262143), -262144);
twiddle_i_int = max(min(twiddle_i_int,  262143), -262144);

% write hex files — 8 hex digits to avoid $readmemh width issues
fid = fopen('real_twiddle_mem.hex', 'w');
for i = 1 : N/2
    val = twiddle_r_int(i);
    if val < 0
        val = val + 2^19;
    end
    fprintf(fid, '%08x\n', val);
end
fclose(fid);

fid = fopen('imag_twiddle_mem.hex', 'w');
for i = 1 : N/2
    val = twiddle_i_int(i);
    if val < 0
        val = val + 2^19;
    end
    fprintf(fid, '%08x\n', val);
end
fclose(fid);

%% 2. Input signal — Q8.11
% square wave: 1 for first N/4 samples, 0 for rest
% X[0] = N/4 (DC component)
scale_input = 2^11;  % Q8.11, 11 fractional bits

input_r = zeros(1, N);
input_r(1 : N/2) = 1.0;    % first quarter = 1
input_r(N/2+1 : N) = 0.0;  % rest = 0
input_i = zeros(1, N);      % imaginary part = 0

input_r_int = round(input_r * scale_input);  % 1.0 -> 2048 = 0x00800
input_i_int = round(input_i * scale_input);  % all zeros

%% compute bit-reversed indices
br_idx = zeros(1, N);
for n = 0 : N-1
    b = dec2bin(n, log2(N));
    br_idx(n+1) = bin2dec(fliplr(b));
end

% write hex files in bit-reversed order
fid = fopen('real_mem.hex', 'w');
for i = 1 : N
    val = input_r_int(br_idx(i) + 1);
    if val < 0
        val = val + 2^19;
    end
    fprintf(fid, '%08x\n', val);
end
fclose(fid);

fid = fopen('imag_mem.hex', 'w');
for i = 1 : N
    val = input_i_int(br_idx(i) + 1);
    if val < 0
        val = val + 2^19;
    end
    fprintf(fid, '%08x\n', val);
end
fclose(fid);

%% 3. Verify with MATLAB FFT
fprintf('\nExpected FFT output (floating point):\n');
x = input_r + 1j * input_i;
X = fft(x);
for kk = 0 : N-1
    fprintf('X[%3d] = %10.4f + j%10.4f\n', kk, real(X(kk+1)), imag(X(kk+1)));
end

%% 4. Print twiddle table for reference
fprintf('\nTwiddle factors (Q1.18):\n');
for i = 1 : N/2
    val_r = twiddle_r_int(i);
    val_i = twiddle_i_int(i);
    if val_r < 0, hex_r = val_r + 2^19; else hex_r = val_r; end
    if val_i < 0, hex_i = val_i + 2^19; else hex_i = val_i; end
    fprintf('k=%3d  cos=%8.5f  hex=%08x    sin=%8.5f  hex=%08x\n', ...
        i-1, twiddle_r(i), hex_r, twiddle_i(i), hex_i);
end