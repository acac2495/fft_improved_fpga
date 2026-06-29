clear; clc;

N = 64;

%% 1. Twiddle factors — Q1.15
% w_k = e^(-j*2*pi*k/N) for k = 0 to N/2 - 1
k = 0 : (N/2 - 1);
twiddle = exp(-1j * 2 * pi * k / N);

twiddle_r = real(twiddle);
twiddle_i = imag(twiddle);

% Q1.15: scale by 2^15 - 1 = 32767
scale_twiddle = 2^15 - 1;
twiddle_r_int = round(twiddle_r * scale_twiddle);
twiddle_i_int = round(twiddle_i * scale_twiddle);

% clamp to [-32768, 32767] just in case
twiddle_r_int = max(min(twiddle_r_int,  32767), -32768);
twiddle_i_int = max(min(twiddle_i_int,  32767), -32768);

% write hex files
fid = fopen('real_twiddle_mem.hex', 'w');
for i = 1 : N/2
    fprintf(fid, '%04x\n', typecast(int16(twiddle_r_int(i)), 'uint16'));
end
fclose(fid);

fid = fopen('imag_twiddle_mem.hex', 'w');
for i = 1 : N/2
    fprintf(fid, '%04x\n', typecast(int16(twiddle_i_int(i)), 'uint16'));
end
fclose(fid);