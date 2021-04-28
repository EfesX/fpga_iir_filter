%      Программа пересчёта входного напряжения в код на выходе АЦП (12-разрядный).
% На входе ожидается массив значений напряжения в пределах плюс/минус 0,9 вольт. 
% Значения напряжения, выходящие за пределы будут ограничены.
%
% Автор: Кротер С.В. от 27 сентября 2012 года.

function code = ADC(voltage,varargin)
    if nargin==1 
        ACPRazryad = 12; % разрядность ЦАП
    else
        ACPRazryad = varargin{1};
    end

    ACPMax = 0.9;
    ACPMin = -0.9;
    
    voltage = voltage(:);
    voltage = voltage - ACPMin; % избавляюсь от отрицательных чисел

    N_level = 2^ACPRazryad-1;

    AK = N_level/ACPMax/2;
    
    code = int16(voltage.*AK);
    
    code( code>= N_level) = N_level;
    code( code <= 0 ) = 0;
    
