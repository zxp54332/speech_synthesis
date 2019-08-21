#!/bin/bash

set -e

#get parameter
text=$1
directory=./generated/lab/

#launch conda env
cd ~/anaconda3/bin
source activate root

#create txt
cd ~/Desktop/speech_synthesis/
if [ ! -d "$directory" ]; then
    mkdir -p $directory
fi
cd ~/Desktop/speech_synthesis/generated/lab/
echo $text | sed 's/_/ /g' >>$text.txt

#create label file from txt
~/Desktop/merlin/egs/build_your_own_voice/s1/scripts/prepare_labels_from_txt.sh ~/Desktop/speech_synthesis/generated/lab/ ~/Desktop/speech_synthesis/generated/lab/ ~/Desktop/merlin/egs/build_your_own_voice/s1/conf/global_settings.cfg

#move txt to lab folder
mv ./prompt-lab/$text.lab ./

#remove unnecessary folder
rm -rf prompt-utt/ prompt-lab/ test_id_list.scp $text.txt new_test_sentences.scm

#format label file
cd ~/Desktop/speech_synthesis/
python ./scripts/format_lab.py --filename=./generated/lab/$text.lab
