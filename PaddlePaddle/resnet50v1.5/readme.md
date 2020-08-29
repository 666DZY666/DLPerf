# 【DLPerf】Paddle-ResNet50V1.5测评

# Overview
本次复现采用了[PaddlePaddle官方仓库](https://github.com/PaddlePaddle/models/tree/release/1.8)中的paddle版[ResNet50(v1.5)](https://github.com/PaddlePaddle/models/tree/release/1.8/PaddleCV/image_classification)的实现，复现的目的在于速度测评，同时根据测速结果给出1机、2机器、4机情况下的加速比，评判框架在分布式多机训练情况下的横向拓展能力。

目前，我们仅测试了正常FP32精度下，不加XLA时的情况，后续我们会陆续开展混合精度、XLA等多种方式的测评。



本文主要内容：


- **Environment**

  - 给出了测评时的硬件系统环境、软件版本等信息
- **Quick Start**

  - 介绍了从克隆官方Github仓库到数据集准备的详细过程
- **Training**

  - 提供了方便易用的测评脚本，覆盖从单机单卡～多机多卡的情形
- **Result**

  - 提供完整测评log日志，并给出示例代码，用以计算平均速度、加速比，并给出汇总表格



# Environment
## 系统

- 系统：Ubuntu 16.04.4 LTS (GNU/Linux 4.4.0-116-generic x86_64)
- 显卡：Tesla V100-SXM2-16GB x 8
- 驱动：Nvidia 440.33.01
- CUDA：10.2
- cuDNN：7.6.5
- NCCL：2.7.3
## 框架

- **paddle 1.8.3.post107**
## Feature support matrix
| Feature | ResNet-50 v1.5 Paddle |
| --- | --- |
| Multi-node,multi-gpu training | Yes |
| NVIDIA NCCL | Yes |

# Quick Start
## 项目代码

- [PaddlePaddle官方仓库](https://github.com/PaddlePaddle/models/tree/release/1.8)
   - [Resnet50_v1.5项目主页](https://github.com/PaddlePaddle/models/tree/release/1.8/PaddleCV/image_classification)

下载官方源码：
```shell
git clone https://github.com/PaddlePaddle/models/tree/release/1.8
cd models/PaddleCV/image_classification
```


将本页面scripts文件夹中的脚本全部放入：`models/PaddleCV/image_classification/`目录下
## 框架安装
```shell
python3 -m pip install paddlepaddle-gpu==1.8.3.post107 -i https://mirror.baidu.com/pypi/simple
```
## NCCL
paddle的分布式训练底层依赖nccl库，需要从[NVIDIA-NCCL官网下载](https://developer.nvidia.com/nccl/nccl-download)并安装和操作系统、cuda版本适配的nccl。
例如：安装2.7.3版本的nccl：
```shell
sudo dpkg -i nccl-repo-ubuntu1604-2.7.3-ga-cuda10.2_1-1_amd64.deb
sudo apt update
sudo apt install libnccl2=2.7.3-1+cuda10.2 libnccl-dev=2.7.3-1+cuda10.2
```
## 数据集
本次训练使用了ImageNet2012的一个子集(共651468张图片)，数据集制作以及格式参照[paddle官方说明](https://github.com/PaddlePaddle/models/tree/release/1.8/PaddleCV/image_classification#%E6%95%B0%E6%8D%AE%E5%87%86%E5%A4%87)


# Training
集群中有4台节点：


- NODE1=10.11.0.2
- NODE2=10.11.0.3
- NODE3=10.11.0.4
- NODE4=10.11.0.5

## 测评方法

每个节点有8张显卡，这里设置batch_size=128，从1机1卡～4机32卡进行了多组训练。每组进行6次训练，每次训练过程只取第1个epoch的前120iter，计算训练速度时去掉前20iter，只取后100iter。最后将6次训练的速度取中位数得到最终速度，并最终以此计算加速比。

在下文的【Result】部分，我们提供了完整日志和用于根据log计算速度的代码。

## 单机
`models/PaddleCV/image_classification/`目录下,执行脚本
```shell
bash run_single_node.sh
```
对单机1卡、4卡、8卡分别做6组测试。
## 2机16卡
2机、4机等多机情况下，需要在所有机器节点上准备同样的数据集、执行同样的脚本，以完成分布式训练。

如，2机：NODE1='10.11.0.2'     NODE2='10.11.0.3' 的训练，需在两台机器上分别准备好数据集后，NODE1节点`models/PaddleCV/image_classification/`目录下,执行脚本:

```shell
bash run_two_node.sh
```
NODE2节点`models/PaddleCV/image_classification/`目录下，执行同样的脚本`bash run_two_node.sh`即可运行2机16卡的训练，同样默认测试6组。
## 4机32卡
流程同上，在4个机器节点上分别执行：`
`
```shell
bash run_multi_node.sh
```
以运行4机32卡的训练，默认测试6组。
# Result
## 完整日志
[resnet50.zip](https://oneflow-public.oss-cn-beijing.aliyuncs.com/DLPerf/logs/PaddlePaddle/resnet50.zip)

## 加速比
执行以下脚本计算各个情况下的加速比：

```shell
python extract_paddle_logs.py  --log_dir=logs/paddle/resnet50
```
输出：
```shell
logs/paddle/resnet50/4n8g/r50_b128_fp32_1.log {1: 9256.12}
logs/paddle/resnet50/4n8g/r50_b128_fp32_4.log {1: 9256.12, 4: 9353.71}
logs/paddle/resnet50/4n8g/r50_b128_fp32_2.log {1: 9256.12, 4: 9353.71, 2: 9349.71}
logs/paddle/resnet50/4n8g/r50_b128_fp32_3.log {1: 9256.12, 4: 9353.71, 2: 9349.71, 3: 9359.18}
logs/paddle/resnet50/4n8g/r50_b128_fp32_6.log {1: 9256.12, 4: 9353.71, 2: 9349.71, 3: 9359.18, 6: 9306.93}
logs/paddle/resnet50/4n8g/r50_b128_fp32_5.log {1: 9256.12, 4: 9353.71, 2: 9349.71, 3: 9359.18, 6: 9306.93, 5: 9346.64}
logs/paddle/resnet50/1n8g/r50_b128_fp32_1.log {1: 2612.02}
logs/paddle/resnet50/1n8g/r50_b128_fp32_4.log {1: 2612.02, 4: 2636.74}
logs/paddle/resnet50/1n8g/r50_b128_fp32_2.log {1: 2612.02, 4: 2636.74, 2: 2624.97}
logs/paddle/resnet50/1n8g/r50_b128_fp32_3.log {1: 2612.02, 4: 2636.74, 2: 2624.97, 3: 2624.23}
logs/paddle/resnet50/1n8g/r50_b128_fp32_6.log {1: 2612.02, 4: 2636.74, 2: 2624.97, 3: 2624.23, 6: 2634.72}
logs/paddle/resnet50/1n8g/r50_b128_fp32_5.log {1: 2612.02, 4: 2636.74, 2: 2624.97, 3: 2624.23, 6: 2634.72, 5: 2625.79}
logs/paddle/resnet50/1n4g/r50_b128_fp32_1.log {1: 1353.06}
logs/paddle/resnet50/1n4g/r50_b128_fp32_4.log {1: 1353.06, 4: 1354.14}
logs/paddle/resnet50/1n4g/r50_b128_fp32_2.log {1: 1353.06, 4: 1354.14, 2: 1361.98}
logs/paddle/resnet50/1n4g/r50_b128_fp32_3.log {1: 1353.06, 4: 1354.14, 2: 1361.98, 3: 1363.45}
logs/paddle/resnet50/1n4g/r50_b128_fp32_6.log {1: 1353.06, 4: 1354.14, 2: 1361.98, 3: 1363.45, 6: 1357.79}
logs/paddle/resnet50/1n4g/r50_b128_fp32_5.log {1: 1353.06, 4: 1354.14, 2: 1361.98, 3: 1363.45, 6: 1357.79, 5: 1359.48}
logs/paddle/resnet50/1n1g/r50_b128_fp32_1.log {1: 354.32}
logs/paddle/resnet50/1n1g/r50_b128_fp32_4.log {1: 354.32, 4: 352.08}
logs/paddle/resnet50/1n1g/r50_b128_fp32_2.log {1: 354.32, 4: 352.08, 2: 354.71}
logs/paddle/resnet50/1n1g/r50_b128_fp32_3.log {1: 354.32, 4: 352.08, 2: 354.71, 3: 353.04}
logs/paddle/resnet50/1n1g/r50_b128_fp32_6.log {1: 354.32, 4: 352.08, 2: 354.71, 3: 353.04, 6: 352.39}
logs/paddle/resnet50/1n1g/r50_b128_fp32_5.log {1: 354.32, 4: 352.08, 2: 354.71, 3: 353.04, 6: 352.39, 5: 352.07}
logs/paddle/resnet50/1n2g/r50_b128_fp32_1.log {1: 661.22}
logs/paddle/resnet50/1n2g/r50_b128_fp32_4.log {1: 661.22, 4: 637.27}
logs/paddle/resnet50/1n2g/r50_b128_fp32_2.log {1: 661.22, 4: 637.27, 2: 641.5}
logs/paddle/resnet50/1n2g/r50_b128_fp32_3.log {1: 661.22, 4: 637.27, 2: 641.5, 3: 648.13}
logs/paddle/resnet50/1n2g/r50_b128_fp32_6.log {1: 661.22, 4: 637.27, 2: 641.5, 3: 648.13, 6: 621.58}
logs/paddle/resnet50/1n2g/r50_b128_fp32_5.log {1: 661.22, 4: 637.27, 2: 641.5, 3: 648.13, 6: 621.58, 5: 647.83}
logs/paddle/resnet50/2n8g/r50_b128_fp32_1.log {1: 4894.51}
logs/paddle/resnet50/2n8g/r50_b128_fp32_4.log {1: 4894.51, 4: 4892.93}
logs/paddle/resnet50/2n8g/r50_b128_fp32_2.log {1: 4894.51, 4: 4892.93, 2: 4906.09}
logs/paddle/resnet50/2n8g/r50_b128_fp32_3.log {1: 4894.51, 4: 4892.93, 2: 4906.09, 3: 4919.23}
logs/paddle/resnet50/2n8g/r50_b128_fp32_6.log {1: 4894.51, 4: 4892.93, 2: 4906.09, 3: 4919.23, 6: 4896.04}
logs/paddle/resnet50/2n8g/r50_b128_fp32_5.log {1: 4894.51, 4: 4892.93, 2: 4906.09, 3: 4919.23, 6: 4896.04, 5: 4882.73}
{'r50': {'1n1g': {'average_speed': 353.1,
                  'batch_size_per_device': 128,
                  'median_speed': 352.72,
                  'speedup': 1.0},
         '1n2g': {'average_speed': 642.92,
                  'batch_size_per_device': 128,
                  'median_speed': 644.66,
                  'speedup': 1.83},
         '1n4g': {'average_speed': 1358.32,
                  'batch_size_per_device': 128,
                  'median_speed': 1358.64,
                  'speedup': 3.85},
         '1n8g': {'average_speed': 2626.41,
                  'batch_size_per_device': 128,
                  'median_speed': 2625.38,
                  'speedup': 7.44},
         '2n8g': {'average_speed': 4898.59,
                  'batch_size_per_device': 128,
                  'median_speed': 4895.27,
                  'speedup': 13.88},
         '4n8g': {'average_speed': 9328.72,
                  'batch_size_per_device': 128,
                  'median_speed': 9348.17,
                  'speedup': 26.5}}}
Saving result to ./result/resnet50_result.json
```
## 计算规则

### 1.测速脚本

- extract_paddle_logs.py
- extract_paddle_logs_time.py

两个脚本略有不同：

extract_paddle_logs.py根据官方在log中打印的速度，在120个iter中，排除前20iter，取后100个iter的速度做平均；

extract_paddle_logs_time.py则根据log中打印出的时间，排除前20iter取后100个iter的实际运行时间计算速度。

### 2.均值速度和中值速度

- average_speed均值速度

- median_speed中值速度

  每个batch size进行5~7次训练测试，记为一组，每一组取average_speed为均值速度，median_speed为中值速度

### 3.加速比以中值速度计算

脚本和表格中的 **加速比** 是以单机单卡下的中值速度为基准进行计算的。例如:

单机单卡情况下速度为200(samples/s)，单机2卡速度为400，单机4卡速度为700，则加速比分别为：1.0、2.0、3.5

## ResNet50 V1.5 bsz = 128

### FP32 & Without XLA

| 节点数 | GPU数 | samples/s | 加速比 |
| --- | --- | --- | --- |
| 1 | 1 | 352.72    | 1 |
| 1 | 2| 644.66    | 1.83   |
| 1 | 4 | 1358.64   | 3.85   |
| 1 | 8 | 2625.38   | 7.44   |
| 2 | 16 | 4895.27   | 13.88  |
| 4 | 32 | 9348.17   | 26.50 |

附：[Paddle官方fp16+dali测试结果](https://github.com/PaddlePaddle/models/tree/release/1.8/PaddleCV/image_classification#%E6%B7%B7%E5%90%88%E7%B2%BE%E5%BA%A6%E8%AE%AD%E7%BB%83)


