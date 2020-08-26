# NVIDIA/DeepLearningExamples Pytorch BERT 测评

## 概述 Overview

本测试基于 [NVIDIA/DeepLearningExamples/PyTorch/LanguageModeling/BERT/](https://github.com/NVIDIA/DeepLearningExamples/tree/master/PyTorch/LanguageModeling/BERT) 仓库中提供的 Pytorch 框架的 BERT 实现，在 NVIDIA 官方提供的 [20.03 NGC 镜像及其衍生容器](https://ngc.nvidia.com/catalog/containers/nvidia:pytorch/tags)中进行单机单卡、单机多卡的结果复现及速度评测，同时增加分布式实现，测试 1机、2 机、4 机的吞吐率及加速比，评判框架在分布式多机训练情况下的横向拓展能力。

目前，该测试仅覆盖 FP32 精度，后续将持续维护，增加混合精度训练，XLA 等多种方式的测评。

## 内容目录 Table Of Contents

[TOC]

## 环境 Environment

#### 系统

- #### 硬件

  - GPU：Tesla V100（16G）×8

- ####　软件

  - 驱动：Nvidia 440.33.01

  - 系统：[ Ubuntu 16.04](http://releases.ubuntu.com/16.04/)

  - CUDA：10.2

  - cuDNN：7.6.5

#### NGC 容器

- 系统：[ Ubuntu 18.04](http://releases.ubuntu.com/18.04/)

- CUDA 10.2.89

- cuDNN 7.6.5

- NCCL：2.5.6

- Pytorch：1.5.0a0+8f84ded

- OpenMPI 3.1.4

- DALI 0.19.0

- Python：3.6.9

  更多容器细节请参考 [NVIDIA Container Support Matrix](https://docs.nvidia.com/deeplearning/dgx/support-matrix/index.html)。

  ##### Feature support matrix

  | Feature                         | ResNet50 v1.5 Pytorch |
  | ------------------------------- | --------------------- |
  | Multi-gpu training              | Yes                   |
  | Multi-node training             | Yes                   |
  | Automatic mixed precision (AMP) | No                    |



## 快速开始 Quick Start

### 1. 前期准备

- #### 数据集

根据 [BERT For Pytorch](https://github.com/NVIDIA/DeepLearningExamples/tree/master/PyTorch/LanguageModeling/BERT) 中的 [Getting the data](https://github.com/NVIDIA/DeepLearningExamples/tree/master/PyTorch/LanguageModeling/BERT#getting-the-data) 小节准备 Pytorch 使用的 `hdf5` 格式的 BERT 数据集，主要有 [SQuAD](https://rajpurkar.github.io/SQuAD-explorer/) (fine-tuning for question answering) 、Wikipedia (pre-training)、BookCorpus (pre-training)。

考虑到性能测试无需花费大量时间（网络良好，梯子健全情况下大约一天）制备完整数据集，简易 Wikipedia 数据集制作可参考以下步骤：

- 下载 Wikipedia 数据集并解压，取其 /AA 路径数据作为使用的 data sample

- 修改

  可以先制作数据集，运行容器时绑定数据集路径（`-v ./data:/data/`），也可以先起容器，制作完数据集，使用 scp 传递数据集至容器内的 /workspace/rn50/data 路径下

- #### 镜像及容器

同时，根据 [NVIDIA 官方指导 Quick Start Guide](https://github.com/NVIDIA/DeepLearningExamples/tree/master/PyTorch/LanguageModeling/BERT#quick-start-guide)下载源码、拉取镜像（本次测试选用的是 NGC 20.03）、搭建容器，进入容器环境。

```
git clone https://github.com/NVIDIA/DeepLearningExamples.git
cd DeepLearningExamples/PyTorch/LanguageModeling/BERT

# 构建项目镜像 
# DeepLearningExamples/PyTorch/LanguageModeling/BERT目录下
docker build . -t nvidia_rn50_pt:20.03-resnet
# 启动容器
docker  run -it --shm-size=16g --ulimit memlock=-1 --privileged  \
--name pt_bert  --net host \
--cap-add=IPC_LOCK --device=/dev/infiniband \
-v ./data:/data/ \
-d nvidia_rn50_pt:20.03
```

- #### SSH 免密

单机测试下无需配置，但测试 2 机、4 机等多机情况下，则需要配置 docker 容器间的 ssh 免密登录，保证 Pytorch 官方的 mpi/nccl 分布式脚本运行时可以在单机上与其他节点互联。

 **安装ssh服务端**

```
# 在容器内执行
apt-get update
apt-get install openssh-server
```

**设置免密登录**

- 节点间的 /root/.ssh/id_rsa.pub 互相授权，添加到 /root/.ssh/authorized_keys 中；
- 修改 sshd 中用于 docker 通信的端口号 `vim /etc/ssh/sshd_config`，修改 `Port`；
- 重启 ssh 服务，`service ssh restart`。

### 2. 运行测试

本次测试集群中有 4 台节点：

- NODE1=10.11.0.2
- NODE2=10.11.0.3
- NODE3=10.11.0.4
- NODE4=10.11.0.5

每个节点有 8 张 V100 显卡， 每张显卡显存 16 G。

- **单机测试**

在容器内下载本仓库源码：

````
git clone https://github.com/Oneflow-Inc/DLPerf.git
````

将本仓库 /DLPerf/NVIDIADeepLearningExamples/Pytorch/BERT/scripts 下的源码放至 /workspace/examples/bert/test_scripts（需新建） 下，执行脚本

```
bash run_single_node.sh
```

即可执行针对单机单卡、单机 2 卡、单机 4 卡、单机 8 卡， batch_size 分别取 32、48 等情况的集成测试，并将 log 信息保存在当前目录的 /ngc/pytorch/ 对应分布式配置路径中，如单机单卡为 /1n1g，意为 1 node 1 gpu；单机 8卡 为 /1n8g，意为 1 node 8 gpus，以此类推。

### 3. 数据处理

测试进行了多组训练（本测试中取5 次），每次训练过程只取第 1 个epoch 的前 120 iter，计算训练速度时去掉前 20 iter，只取后 100 iter的数据，以降低抖动。最后将 5~7 次训练的速度取中位数得到最终速度，并最终以此数据计算加速比。

运行 /DLPerf/NVIDIADeepLearningExamples/Pytorch/BERT/extract_pytorch_logs_time.py，即可得到针对不同配置测试结果 log 数据处理的结果： 

```
python extract_pytorch_logs_time.py --log_dir [log_dir]
```

结果打印如下

```
/workspace/examples/bert/test_scripts/ngc/pytorch/1n2g/bert-base-adam-training_b32_fp32_1.log {1: 221.77}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n2g/bert-base-adam-training_b32_fp32_5.log {1: 221.77, 5: 220.86}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n2g/bert-base-adam-training_b32_fp32_2.log {1: 221.77, 5: 220.86, 2: 221.42}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n2g/bert-base-adam-training_b32_fp32_3.log {1: 221.77, 5: 220.86, 2: 221.42, 3: 221.71}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n2g/bert-base-adam-training_b32_fp32_4.log {1: 221.77, 5: 220.86, 2: 221.42, 3: 221.71, 4: 221.19}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n1g/bert-base-adam-training_b32_fp32_1.log {1: 119.89}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n1g/bert-base-adam-training_b32_fp32_5.log {1: 119.89, 5: 120.04}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n1g/bert-base-adam-training_b32_fp32_2.log {1: 119.89, 5: 120.04, 2: 119.77}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n1g/bert-base-adam-training_b32_fp32_3.log {1: 119.89, 5: 120.04, 2: 119.77, 3: 119.39}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n1g/bert-base-adam-training_b32_fp32_4.log {1: 119.89, 5: 120.04, 2: 119.77, 3: 119.39, 4: 119.34}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n8g/bert-base-adam-training_b32_fp32_1.log {1: 917.73}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n8g/bert-base-adam-training_b32_fp32_5.log {1: 917.73, 5: 915.88}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n8g/bert-base-adam-training_b32_fp32_2.log {1: 917.73, 5: 915.88, 2: 921.33}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n8g/bert-base-adam-training_b32_fp32_3.log {1: 917.73, 5: 915.88, 2: 921.33, 3: 919.84}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n8g/bert-base-adam-training_b32_fp32_4.log {1: 917.73, 5: 915.88, 2: 921.33, 3: 919.84, 4: 919.92}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n4g/bert-base-adam-training_b32_fp32_1.log {1: 460.74}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n4g/bert-base-adam-training_b32_fp32_5.log {1: 460.74, 5: 458.96}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n4g/bert-base-adam-training_b32_fp32_2.log {1: 460.74, 5: 458.96, 2: 459.24}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n4g/bert-base-adam-training_b32_fp32_3.log {1: 460.74, 5: 458.96, 2: 459.24, 3: 458.11}
/workspace/examples/bert/test_scripts/ngc/pytorch/1n4g/bert-base-adam-training_b32_fp32_4.log {1: 460.74, 5: 458.96, 2: 459.24, 3: 458.11, 4: 459.45}
{'bert-base-adam-training': {'1n1g': {'average_speed': 119.69,
                                      'batch_size_per_device': 32,
                                      'median_speed': 119.77,
                                      'speedup': 1.0},
                             '1n2g': {'average_speed': 221.39,
                                      'batch_size_per_device': 32,
                                      'median_speed': 221.42,
                                      'speedup': 1.85},
                             '1n4g': {'average_speed': 459.3,
                                      'batch_size_per_device': 32,
                                      'median_speed': 459.24,
                                      'speedup': 3.83},
                             '1n8g': {'average_speed': 918.94,
                                      'batch_size_per_device': 32,
                                      'median_speed': 919.84,
                                      'speedup': 7.68}}}
Saving result to ./result/pytorch_result.json
```

## 性能结果 Performance

该小节提供针对 NVIDIA Pytorch 框架的 BERT 模型测试的性能结果和完整 log 日志。

### FP32 & W/O XLA

- #### BERT-Base batch_size = 32

| gpu_num_per_node | batch_size_per_device | samples/s(OneFlow) | speedup | samples/s(Pytorch) | speedup |
| ---------------- | --------------------- | ------------------ | ------- | ------------------ | ------- |
| 1                | 32                    | 145.2              | 1.00    | 119.77             | 1.00    |
| 2                | 32                    |                    |         | 221.42             | 1.85    |
| 4                | 32                    |                    |         | 459.24             | 3.83    |
| 8                | 32                    | 1043.0             | 7.18    | 919.84             | 7.68    |

- #### BERT-Base batch_size = 48

| gpu_num_per_node | batch_size_per_device | samples/s(OneFlow) | speedup | samples/s(Pytorch) | speedup |
| ---------------- | --------------------- | ------------------ | ------- | ------------------ | ------- |
| 1                | 48                    | 145.2              | 1.00    | 123.92             | 1.00    |
| 2                | 48                    |                    |         | 231.92             | 1.87    |
| 4                | 48                    |                    |         | 472.87             | 3.82    |
| 8                | 48                    | 1043.0             | 7.18    | 943.61             | 7.61    |

NVIDIA的 Pytorch 官方测评结果请见 [BERT For PyTorch](https://github.com/NVIDIA/DeepLearningExamples/tree/master/PyTorch/LanguageModeling/BERT#training-performance-results)

详细 Log 信息可下载：[ngc_pytorch_bert.zip]()


