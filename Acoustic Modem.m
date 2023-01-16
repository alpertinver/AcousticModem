%% ACOUSTIC MODEM IN MATLAB


%% Configuration
clear;
clc;
close all;
M = 16;      % Modulation order (alphabet size or number of points in signal constellation)
k = log2(M);
Fs=96000;
Nbits=8;
nChannels=1;
SNR=15;


%% audio recording
recObj=audiorecorder(Fs,Nbits,nChannels);
recDuration=8;
disp("Begin speaking.")
recordblocking(recObj,recDuration);
disp("End of recording")
y=getaudiodata(recObj);     %kaydedilen sesin datası
plot(y);                    %kaydedilen sesin zaman genlik grafiği
playObj=audioplayer(y,Fs);  
play(playObj);              %kaydedilen sesi dinletir

%% plot unmodulated signal
Ts=-(1/Fs)/2:1:(1/Fs)/2;
figure
subplot(1,2,1);
plottf(y,Ts,'t');
title('Input signal time domain');
subplot(1,2,2);
plottf(y,Ts,'f');
title('Input signal freq domain');


%% reshaping
wavbinary=dec2bin(typecast(single(y(:)), 'uint8'),8)-'0'; 
w1=reshape(wavbinary,[],1);
w1=reshape(w1,1,[]);


%% manchester encoding
b=w1;
l=length(b);
b(l+1)=0;
n=1;
 while n<=l
    t=(n-1):.001:n;
    if b(n)==1
        if b(n+1)==0
            y=(t<(n-0.5))+(-1)*(t>=n-0.5&t<=n);
        else
            y=(t<(n-0.5)|t==n)+(-1)*(t>=n-0.5&t<n);
        end
    else
        if b(n+1)==1
            y=(-1)*(t<(n-0.5))+(t>=n-0.5&t<=n);
        else
             y=(-1)*(t<(n-0.5)|t==n)+(t>=n-0.5&t<n);
        end
    end
    plot(t,y)
    hold on;
    axis([0 l -1.5 1.5]);
    n=n+1;
 end
title('Manchester');
xlabel('Time');
ylabel('Amplitude');



%% QAM Modulation and AWGN
data1=w1;

txSig=qammod(data1,M,'bin','InputType','bit');
rxSig=awgn(txSig,SNR);



%% Demodulation
z=qamdemod(rxSig,M,'bin','OutputType','bit');   %binary output

cd=comm.ConstellationDiagram('ShowReferenceConstellation',false);
cd(txSig);
cd1=comm.ConstellationDiagram('ShowReferenceConstellation',false);
cd1(rxSig);


%% reshaping
w2=reshape(z,[],8);
wavb2=double(w2);

wavdata2 = reshape(typecast(uint8(bin2dec(char(wavb2+'0'))),'single'),size(wavdata));
s=isequal(wavdata2,y)

audiowrite('ses2.wav',wavdata2,Fs)

sound(wavdata2,Fs)



%% plot output signal
figure
subplot(1,2,1);
plottf(wavdata2,Ts,'t');
title('output signal time domain');
subplot(1,2,2);
plottf(wavdata2,Ts,'f');
title('output signal freq domain');


%% BER calculationwe
[numErrors,ber] = biterr(y,wavdata2);
fprintf('\nFor an EbNo setting of %3.1f dB, the bit error rate is %5.2e, based on %d errors.\n',EbNo,ber,numErrors);


