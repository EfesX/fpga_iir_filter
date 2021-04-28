clear all; clc; close all;

fileID = fopen('sh_i_out.txt', 'r');
data_cell = textscan(fileID, '%d');
data_i = cell2mat(data_cell);
fclose(fileID);

fileID = fopen('sh_q_out.txt', 'r');
data_cell = textscan(fileID, '%d');
data_q = cell2mat(data_cell);
fclose(fileID);


data = double(complex(data_i, data_q));
Y = fft(data);

figure
plot(real(Y))
hold on
plot(imag(Y))

figure
plot(data_i, '.-')



