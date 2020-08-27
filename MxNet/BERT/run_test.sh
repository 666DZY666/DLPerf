#!/usr/bin/bash
SHELL_FOLDER=$(dirname $(readlink -f "$0"))

export LD_LIBRARY_PATH=/usr/local/cuda/compat/lib.real:/usr/local/cuda/compat/lib:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/lib
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/mpi/bin/

export WORKSPACE=/DLPerf/benchs/gluon-nlp/scripts/bert
export DATA_DIR=/DLPerf/dataset/bert_mxnet_npy/wiki_128_npy_part_0

export NODE1=10.11.0.2
export NODE2=10.11.0.3
export NODE3=10.11.0.4
export NODE4=10.11.0.5
export PORT=2238


BZ_PER_DEVICE=32
i=1
while [ $i -le 7 ]
do
    bash $SHELL_FOLDER/pretrain.sh bert_base ${BZ_PER_DEVICE} 120 0 1 float32 ${i}
    bash $SHELL_FOLDER/pretrain.sh bert_base ${BZ_PER_DEVICE} 120 0,1,2,3,4,5,6,7 1 float32 ${i}
    bash $SHELL_FOLDER/pretrain.sh bert_base ${BZ_PER_DEVICE} 120 0,1,2,3,4,5,6,7 2 float32 ${i}
    bash $SHELL_FOLDER/pretrain.sh bert_base ${BZ_PER_DEVICE} 120 0,1,2,3,4,5,6,7 4 float32 ${i}

    echo " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Finished Test Case ${i}!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "
    let i++
    sleep 20s
done

