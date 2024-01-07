clear all;
close all; 
clc;

% ---- 1. CamouflageMap Path Setting ----
%SalMapPath = '../CamMap/';   % Put model results in this folder%
SalMapPath = "D:\COD10k_Dataset_for_Evaluation\Xlarge_Gts\";% Put model results in this folder%
Models = {'Xlarge_Gts'}; %{'2020-CVPR-SINet'};   % You can add other model like: Models = {'2019-ICCV-EGNet','2019-CVPR-CPD'};
modelNum = length(Models);

% ---- 2. Ground-truth Datasets Setting ----
%DataPath = '../CamDataset/';
DataPath = "D:\COD10k_Dataset_for_Evaluation\GTs";
Datasets = {'GTs'}; % {'COD10K'};  % You may also need other datasets, such as Datasets = {'CAMO','CPD1K'};

% ---- 3. Results Save Path Setting ----
%ResDir = '../Results/Result-COD10K-test/';
ResDir = 'C:\Users\User\Desktop\result\';
ResName='v8x_result.txt';  % You can change the result name.

Thresholds = 1:-1/255:0;
datasetNum = length(Datasets);

for d = 1:datasetNum
    
    tic;
    dataset = Datasets{d}   % print cur dataset name
    fprintf('Processing %d/%d: %s Dataset\n',d,datasetNum,dataset);
  
    ResPath = [ResDir dataset '-mat/']; % The result will be saved in *.mat file so that you can used it for the next time.
    if ~exist(ResPath,'dir')
        mkdir(ResPath);
    end
    resTxt = [ResDir dataset ResName];  % The evaluation result will be saved in `../Resluts/Result-XXXX` folder.
    fileID = fopen(resTxt,'w');
    
    for m = 1:modelNum
        model = Models{m}   % print cur model name

        gtPath = [DataPath dataset '/'];
        salPath = [SalMapPath model '/'];   

        salPath = fullfile(salPath{:});
        gtPath = fullfile(gtPath{:});
        disp(salPath);
        
        imgFiles = dir([salPath '*.png']);  
        imgNUM = length(imgFiles);
        
        [threshold_Fmeasure, threshold_Emeasure] = deal(zeros(imgNUM,length(Thresholds)));
        
        [threshold_Precion, threshold_Recall] = deal(zeros(imgNUM,length(Thresholds)));
        
        [Smeasure, wFmeasure, adpFmeasure, adpEmeasure, MAE] =deal(zeros(1,imgNUM));
        
        % Start parallel pool to bring out your computer potentials
        for i = 1:imgNUM
            
            fprintf('Evaluating(%s Dataset,%s Model): %d/%d\n',dataset, model, i,imgNUM);
            name =  imgFiles(i).name;
            
            %load gt
            disp(gtPath);
            disp(name);
            gt = imread([gtPath name]);

            
            
            if (ndims(gt)>2)
                gt = rgb2gray(gt);
            end
            
            if ~islogical(gt)
                gt = gt(:,:,1) > 128;
            end
            
            %load salency
            sal  = imread([salPath name]);
            
            %check size
            if size(sal, 1) ~= size(gt, 1) || size(sal, 2) ~= size(gt, 2)
                sal = imresize(sal,size(gt));
                imwrite(sal,[salPath name]);
                fprintf('Error occurs in the path: %s!!!\n', [salPath name]);
            end
            
            sal = im2double(sal(:,:,1));
            
            %normalize sal to [0, 1]
            sal = reshape(mapminmax(sal(:)',0,1),size(sal));
            
            % S-meaure metric published in ICCV'17 (Structure measure: A New Way to Evaluate the Foreground Map.)
            Smeasure(i) = StructureMeasure(sal,logical(gt)); 
            
            % Weighted F-measure metric published in CVPR'14 (How to evaluate the foreground maps?)
            wFmeasure(i) = original_WFb(sal,logical(gt));
            
            % Using the 2 times of average of sal map as the threshold.
            threshold = min(2 * mean2(sal), 1); %threshold =  2* mean(sal(:)); -》 threshold = min(2 * mean2(sal), 1); To ensure the max value is less than 1.
            [~,~,adpFmeasure(i)] = Fmeasure_calu(sal,double(gt),size(gt),threshold);
            
            Bi_sal = zeros(size(sal));
            Bi_sal(sal>threshold)=1;
            adpEmeasure(i) = Enhancedmeasure(Bi_sal,gt);
            
            [threshold_F, threshold_E]  = deal(zeros(1,length(Thresholds)));
            [threshold_Pr, threshold_Rec]  = deal(zeros(1,length(Thresholds)));
            for t = 1:length(Thresholds)
                threshold = Thresholds(t);
                [threshold_Pr(t), threshold_Rec(t), threshold_F(t)] = Fmeasure_calu(sal,double(gt),size(gt),threshold);
                
                Bi_sal = zeros(size(sal));
                Bi_sal(sal>threshold)=1;
                threshold_E(t) = Enhancedmeasure(Bi_sal,gt);
            end
            
            threshold_Fmeasure(i,:) = threshold_F;
            threshold_Emeasure(i,:) = threshold_E;
            threshold_Precion(i,:) = threshold_Pr;
            threshold_Recall(i,:) = threshold_Rec;
            
            MAE(i) = mean2(abs(double(logical(gt)) - sal));
            
        end

        column_F = mean(threshold_Fmeasure,1);
        meanFm = mean(column_F);
        maxFm = max(column_F);
        
        column_Pr = mean(threshold_Precion,1);
        column_Rec = mean(threshold_Recall,1);
        
        column_E = mean(threshold_Emeasure,1);
        meanEm = mean(column_E);
        maxEm = max(column_E);
        
        Sm = mean2(Smeasure);
        wFm = mean2(wFmeasure);
        
        adpFm = mean2(adpFmeasure);
        adpEm = mean2(adpEmeasure);
        mae = mean2(MAE);
        
        save([ResPath model],'Sm','wFm', 'mae', 'column_Pr', 'column_Rec', 'column_F', 'adpFm', 'meanFm', 'maxFm', 'column_E', 'adpEm', 'meanEm', 'maxEm');
        fprintf(fileID, '(Dataset:%s; Model:%s) Smeasure:%.3f; wFmeasure:%.3f;MAE:%.3f; adpEm:%.3f; meanEm:%.3f; maxEm:%.3f; adpFm:%.3f; meanFm:%.3f; maxFm:%.3f.\n',dataset,model,Sm, wFm, mae, adpEm, meanEm, maxEm, adpFm, meanFm, maxFm); 
        fprintf('(Dataset:%s; Model:%s) Smeasure:%.3f; wFmeasure:%.3f;MAE:%.3f; adpEm:%.3f; meanEm:%.3f; maxEm:%.3f; adpFm:%.3f; meanFm:%.3f; maxFm:%.3f.\n',dataset,model,Sm, wFm, mae, adpEm, meanEm, maxEm, adpFm, meanFm, maxFm);
    end
    toc;
    
end


