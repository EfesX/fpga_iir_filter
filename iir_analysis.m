clc; clear all; close all;

fileID = fopen('iir_impulse.txt', 'r');
data_cell = textscan(fileID, '%d');
data = cell2mat(data_cell);

Fs = 50e6;
Ts = 1/Fs;
L = length(data);
t = (0:L-1)*Ts;


n = 2^nextpow2(L);
Y = fft(data, n);
f = Fs*(0:(n/2))/n;
P = mag2db(abs(Y/n));

maxf = max(P(5:end))
P = P - maxf;

line = ones(1, length(f)) .* -40;


figure
plot(t ./ 1e-6, data)
title('Impulse Response');
xlabel('Time [us]')


figure
plot(f ./ 1e6,P(1:n/2+1), f ./ 1e6, line) 
title('Impulse Responce in Frequency Domain');
xlabel('Frequency [MHz]')
grid on









