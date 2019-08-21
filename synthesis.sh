#!/bin/bash

#get parameters
voice_name=$1
labels_dir=./generated/lab
data_dir=./data/$voice_name
lang=$2
specify_gpu=$3

#launch conda env
cd ~/anaconda3/bin/
source activate root

#synthesis
cd ~/Desktop/speech_synthesis
for ty in gan; do
        CUDA_VISIBLE_DEVICES=$specify_gpu python ./scripts/synthesis.py \
                --lang $lang \
                $(ls -t ./checkpoints/$voice_name/tts_acoustic/$ty/*_Generator.pth | head -1) \
                $(ls -t ./checkpoints/$voice_name/tts_duration/$ty/*_Generator.pth | head -1) \
                ${data_dir} \
                ${labels_dir} \
                ./generated/duration_acousic/$ty
done
