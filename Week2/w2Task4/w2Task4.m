%Highway 1050 - 1350 
%Fall 1460 - 1560 
%Traffic 950 - 1050
clear all
clc

tic
%Paths to the input images and their groundtruth
sequencePath = {'../Archivos/highway/input/' '../Archivos/traffic/traffic/input/' '../Archivos/fall/fall/input/'} ;
groundtruthPath = {'../Archivos/highway/groundtruth/' '../Archivos/traffic/traffic/groundtruth/' '../Archivos/fall/fall/groundtruth/'};
%Initial and final frame of the sequence
iniFrame = [1050 950 1460];
endFrame = [1350 1050 1560];

for seq=1:numel(iniFrame)
%Train the background model with the first half of the sequence
[means, deviations] = trainBackgroundModelColor(char(sequencePath(seq)), char(groundtruthPath(seq)), iniFrame(seq), (endFrame(seq)-iniFrame(seq))/2);


%Define the range of alpha
alpha= 0:30;

%Allocate memory for variables
numAlphas = size(alpha,2);
numChannels= size(means,3);

precision = zeros(numChannels,numAlphas); recall = zeros(numChannels,numAlphas); 
accuracy = zeros(numChannels,numAlphas); FMeasure = zeros(numChannels,numAlphas);

TPTotal=zeros(numChannels,numAlphas);FPTotal=zeros(numChannels,numAlphas);
TNTotal=zeros(numChannels,numAlphas);FNTotal=zeros(numChannels,numAlphas);

%Get the information of the input and groundtruth images
FilesInput = dir(char(strcat(sequencePath(seq), '*jpg')));
FilesGroundtruth = dir(char(strcat(groundtruthPath(seq), '*png')));

for o=1:(size(means,3))
% k is used as an index to store information, in case alpha has 0, decimal or
%negative values
    k=0;
    for al = alpha
        k=k+1
    %Detect foreground objects in the second half of the sequence
        for i = iniFrame(seq)+(endFrame(seq)-iniFrame(seq))/2+1:endFrame(seq)
        %Read an image and convert it to grayscale
            image = imread(strcat(char(sequencePath(seq)),FilesInput(i).name));
            %grayscale = double(image);                     %RGB color space
            grayscale = double(ConvertRGBtoYUV(image));     %YUV Color Space
            
        %Read the groundtruth image
            groundtruth = readGroundtruth(char(strcat(groundtruthPath(seq),FilesGroundtruth(i).name)));  
        %%%%% --> better results if we count the hard shadows as foreground
        %%%%% groundtruth = double(imread(strcat(groundtruthPath,FilesGroundtruth(i).name))) > 169;

        %Detect foreground objects
            detection = detectForeground(grayscale(:,:,o), means(:,:,o), deviations(:,:,o),al);
    
        %Compute the performance of the detector for the whole sequence
            [TP,FP,TN,FN] = computePerformance(groundtruth, detection);
            TPTotal(o,k)=TPTotal(o,k)+TP;
            FPTotal(o,k)=FPTotal(o,k)+FP;
            TNTotal(o,k)=TNTotal(o,k)+TN;
            FNTotal(o,k)=FNTotal(o,k)+FN;
        
        %Show the output of the detector
        %figure(2)
        %imshow(detection)
        end
           %Compute the performance of the detector for the whole sequence
        [precision(o,k),recall(o,k),accuracy(o,k),FMeasure(o,k)] = computeMetrics(TPTotal(o,k),FPTotal(o,k),TNTotal(o,k),FNTotal(o,k));
        vec{seq}(o,k,1)=precision(o,k);
        vec{seq}(o,k,2)=recall(o,k);
        vec{seq}(o,k,3)=accuracy(o,k);
        vec{seq}(o,k,4)=FMeasure(o,k);
        vec{seq}(o,k,5)=TPTotal(o,k);
        vec{seq}(o,k,6)=FPTotal(o,k);
        vec{seq}(o,k,7)=TNTotal(o,k);
        vec{seq}(o,k,8)=FNTotal(o,k);
    end
end
end

%Plot some figures

%Precision
for o=1:numChannels
    figure(); 
    for seq=1:numel(iniFrame)
        plot(alpha, vec{seq}(o,:,1))
        hold on
    end
    hold off
    if o==1
        title('Precision for the 3 sequences 1st Channel'); xlabel('Alpha'); ylabel('Precision')
    elseif o==2
        title('Precision for the 3 sequences 2nd Channel'); xlabel('Alpha'); ylabel('Precision') 
    else
        title('Precision for the 3 sequences 3rd Channel'); xlabel('Alpha'); ylabel('Precision')
    end
    legend('Highway','Traffic','Fall'); ylim([0 1])
end

%Recall
for o=1:numChannels
    figure(); 
    for seq=1:numel(iniFrame)
        plot(alpha, vec{seq}(o,:,2))
        hold on
    end
    hold off
    if o==1
        title('Recall for the 3 sequences 1st Channel'); xlabel('Alpha'); ylabel('Recall')
    elseif o==2
        title('Recall for the 3 sequences 2nd Channel'); xlabel('Alpha'); ylabel('Recall')
    else 
        title('Recall for the 3 sequences 3rd Channel'); xlabel('Alpha'); ylabel('Recall')
    end
    legend('Highway','Traffic','Fall'); ylim([0 1])
end

%Precision-Recall
for o=1:numChannels
    figure()
    for seq=1:numel(iniFrame)
        plot(vec{seq}(o,:,2),vec{seq}(o,:,1))
        hold on
    end
    hold off
    if o==1
        title('P-R curve for the 3 sequences 1st Channel'); xlabel('Recall'); ylabel('Precision')
    elseif o==2
        title('P-R curve for the 3 sequences 2nd Channel'); xlabel('Recall'); ylabel('Precision')
    else
        title('P-R curve for the 3 sequences 3rd Channel'); xlabel('Recall'); ylabel('Precision')
    end
    legend('Highway','Traffic','Fall'); axis([0 1 0 1])
end

%F Measure
for o=1:numChannels
    figure();
    for seq=1:numel(iniFrame)
        plot(alpha, vec{seq}(o,:,4))
        hold on;
    end
    hold off;
    if o==1
        title('Fmeasure for the 3 sequences 1st Channel'); xlabel('Alpha'); ylabel('Fmeasure')
    elseif o==2
        title('Fmeasure for the 3 sequences 2nd Channel'); xlabel('Alpha'); ylabel('Fmeasure')
    else
        title('Fmeasure for the 3 sequences 3rd Channel'); xlabel('Alpha'); ylabel('Fmeasure')
    end
    legend('Highway','Traffic','Fall'); ylim([0 1])
end

%Join Measure in one answer

PF=[];RF=[];FF=[];
for seq=1:numel(iniFrame)
    P=0;R=0;F=0;
    for o=1:3
        P=vec{seq}(o,:,1)+P;
        R=vec{seq}(o,:,2)+R;
        F=vec{seq}(o,:,4)+F;
    end
    PF{seq}=P/3;
    RF{seq}=R/3;
    FF{seq}=F/3;
end

%Precision of join measure
figure(); 
for seq=1:numel(iniFrame)
    plot(alpha, PF{seq})
    hold on
end
hold off
title('Precision for the 3 sequences'); xlabel('Alpha'); ylabel('Precision')
legend('Highway','Traffic','Fall'); ylim([0 1])

%Recall for join Measures
figure(); 
for seq=1:numel(iniFrame)
    plot(alpha, RF{seq})
    hold on
end
hold off
title('Recall for the 3 sequences'); xlabel('Alpha'); ylabel('Recall')
legend('Highway','Traffic','Fall'); ylim([0 1])

%Precision-Recall for join measures
figure()
for seq=1:numel(iniFrame)
    plot(RF{seq},PF{seq})
    hold on
end
hold off
title('P-R curve for the 3 sequences'); xlabel('Recall'); ylabel('Precision')
legend('Highway','Traffic','Fall'); axis([0 1 0 1])

%F1 for join Measures
figure(); 
for seq=1:numel(iniFrame)
    plot(alpha, FF{seq})
    hold on
end
hold off
title('F1 for the 3 sequences'); xlabel('Alpha'); ylabel('F1')
legend('Highway','Traffic','Fall'); ylim([0 1])



%TP,FP,TN,FN
% figure()
% subplot(3,1,1)
% plot(alpha, vec(1,:,5), alpha, vec(1,:,6), alpha, vec(1,:,7), alpha, vec(1,:,8))
% title('TP,FP,TN & FN'); xlabel('Alpha'); ylabel('# pixels')
% legend('TP Highway','FP Highway','TN Highway','FN Highway')
% ylim([0 2*10^7])
% 
% subplot(3,1,2)
% plot(alpha, vec(2,:,5), alpha, vec(2,:,6), alpha, vec(2,:,7), alpha, vec(2,:,8))
% title('TP,FP,TN & FN'); xlabel('Alpha'); ylabel('# pixels')
% legend('TP Traffic','FP Traffic','TN Traffic','FN Traffic')
% ylim([0 2*10^7])
% 
% subplot(3,1,3)
% plot(alpha, vec(3,:,5), alpha, vec(3,:,6), alpha, vec(3,:,7), alpha, vec(3,:,8))
% title('TP,FP,TN & FN'); xlabel('Alpha'); ylabel('# pixels')
% legend('TP Fall','FP Fall','TN Fall','FN Fall')
% ylim([0 2*10^7])
% 
% 
% for seq=1:numel(iniFrame)
%     auc=trapz(vec(seq,:,1),vec(seq,:,2));
%     disp(['AUC for sequence ' num2str(seq) ': ' num2str(auc)] )
% end