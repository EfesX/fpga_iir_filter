clear all; clc; close all;

fileID = fopen('i_out.txt', 'r');
data_cell = textscan(fileID, '%d');
data_i = cell2mat(data_cell);
data_i = data_i(2:end);
fclose(fileID);

fileID = fopen('q_out.txt', 'r');
data_cell = textscan(fileID, '%d');
data_q = cell2mat(data_cell);
data_q = data_q(2:end);
fclose(fileID);

j = 1;
for k = 1:4:length(data_i) - 4
    i_out(j) = data_i(k);
    q_out(j) = data_q(k);
    j = j+1;
end




var = 0;
for k = 100:j-1
   var = var + (double(i_out(k)) + double(q_out(k)));
end
var

plot(i_out,'r.-')
hold on
plot(q_out, 'b.-')
grid on


%i_out = double(i_out);
%q_out = double(q_out);

%Y = complex(i_out, q_out);


%Y * Y' 



fileID_q = fopen('q_out.txt', 'r');
data_cell_q = textscan(fileID_q, '%d');
data_q = cell2mat(data_cell_q);

fileID_i = fopen('i_out.txt', 'r');
data_cell_i = textscan(fileID_i, '%d');
data_i = cell2mat(data_cell_i);

data_i = data_i(1:4:end);
data_q = data_q(1:4:end);


data = double(complex(data_i, data_q));


Fs = 50e6;
Ts = 1/Fs;
L = length(data);
t = (0:L-1)*Ts;


n = 2^nextpow2(L);
Y = fft(data, n);
f = Fs*(0:(n/2))/n;
P1 = (real(Y/n));
P2 = (imag(Y/n));


figure
plot(P1, '.-') 
grid on
hold on
plot(P2, 'ro-') 


plot(abs(Y/n), 'k')












