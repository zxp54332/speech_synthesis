#!/bin/bash

set -e

#get parameters
voice_name=$1
text=$2
filename=$voice_name"_"$text.wav
lang=$3
specify_gpu=$4
output=$5

#check parameters
if [ -z "$lang" ]; then
    lang=en
fi

if [ -z "$specify_gpu" ]; then
    specify_gpu=0
fi

#synthesis & play wav
if [ -f ~/Desktop/$filename ]; then
    play ~/Desktop/$filename
elif [ $lang = 'en' ]; then
    ssh braslab138@140.125.45.138 'rm -rf ./Desktop/speech_synthesis/generated && mkdir -p ./Desktop/speech_synthesis/generated/lab'
    ssh braslab138@140.125.45.138 './Desktop/speech_synthesis/entxt2lab.sh' $text
    ssh braslab138@140.125.45.138 './Desktop/speech_synthesis/synthesis.sh' $voice_name $lang $specify_gpu
    scp braslab138@140.125.45.138:~/Desktop/speech_synthesis/generated/duration_acousic/gan/synthesis/$filename ~/Desktop/
    play ~/Desktop/$filename
elif [ $lang = 'cn' ]; then
    ssh braslab138@140.125.45.138 'rm -rf ./Desktop/speech_synthesis/generated && mkdir -p ./Desktop/speech_synthesis/generated/lab'
    ssh braslab138@140.125.45.138 './Desktop/speech_synthesis/cntxt2lab.sh' $text
    ssh braslab138@140.125.45.138 './Desktop/speech_synthesis/synthesis.sh' $voice_name $lang $specify_gpu
    scp braslab138@140.125.45.138:~/Desktop/speech_synthesis/generated/duration_acousic/gan/synthesis/$filename ~/Desktop/
    play ~/Desktop/$filename
fi

if [ $output ]; then
    mv ~/Desktop/$filename $output
fi
