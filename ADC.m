%      ��������� ��������� �������� ���������� � ��� �� ������ ��� (12-���������).
% �� ����� ��������� ������ �������� ���������� � �������� ����/����� 0,9 �����. 
% �������� ����������, ��������� �� ������� ����� ����������.
%
% �����: ������ �.�. �� 27 �������� 2012 ����.

function code = ADC(voltage,varargin)
    if nargin==1 
        ACPRazryad = 12; % ����������� ���
    else
        ACPRazryad = varargin{1};
    end

    ACPMax = 0.9;
    ACPMin = -0.9;
    
    voltage = voltage(:);
    voltage = voltage - ACPMin; % ���������� �� ������������� �����

    N_level = 2^ACPRazryad-1;

    AK = N_level/ACPMax/2;
    
    code = int16(voltage.*AK);
    
    code( code>= N_level) = N_level;
    code( code <= 0 ) = 0;
    
