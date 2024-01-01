# Camouflaged Object Detection Evaluation Toolkit

> Original work by Deng-Ping Fan, Ge-Peng Ji, Guolei Sun, Ming-Ming Cheng, Jianbing Shen, Ling Shao.

1. Usage Instructions for Binary Mask Evaluation

    To use this repository for evaluating a binary mask output from a model prediction against the original ground truth binary masks, follow these steps:

    - Place all the ground truth binary masks inside the `GroundTruth` directory.
    - Put the model's output prediction of binary masks in the `Predictions` directory.
    - Before running the evaluation code, update the required directory paths in the `main.m` file for accurate evaluation.

    Run the evaluation code for accurate assessment.

5. Evaluation Configuration

    Require: Matlab <br>
    Just Run main.m

# Citation

    @inproceedings{Fan2020Camouflage,
    title={Camouflaged Object Detection},
    author={Fan, Deng-Ping and Ji, Ge-Peng and Sun, Guolei and Cheng, Ming-Ming and Shen, Jianbing and Shao Ling},
    booktitle={IEEE Conference on Computer Vision and Pattern Recognition (CVPR)},
    year={2020}
    }

