#!/bin/bash

set -e

#get parameter
text=$1
directory=./generated/lab/

#launch conda env
cd ~/anaconda3/bin
source activate root

#create label file from txt
cd ~/Desktop/MTTS/
python src/mandarin_frontend.py --text $text

#move label file
mv "$text.lab" ~/Desktop/speech_synthesis/generated/lab/
