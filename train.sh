#!/bin/bash

set -e

#get parameters
lang=$1
specify_gpu=$2
multiplier=$3
shift
shift
shift

#launch conda env
source activate root

#train
for voice_name in "$@"; do
    start=$(date "+%s")
    voice_name=$(basename $voice_name)

    #prepare_features
    python ./scripts/prepare_features_tts.py --lang $lang ./data/$voice_name/ --dst_dir=./data/$voice_name

    #train duration model
    ./train_gan.sh tts_duration ./data/$voice_name/X_duration/ ./data/$voice_name/Y_duration/ ./checkpoints/$voice_name/tts_duration $((50 * multiplier)) $((5 * multiplier)) $((10 * multiplier)) $((100 * multiplier)) $voice_name $lang $specify_gpu

    #train acoustic model
    ./train_gan.sh tts_acoustic ./data/$voice_name/X_acoustic/ ./data/$voice_name/Y_acoustic/ ./checkpoints/$voice_name/tts_acoustic $((25 * multiplier)) $((5 * multiplier)) $((10 * multiplier)) $((50 * multiplier)) $voice_name $lang $specify_gpu

    #evaluation
    #python ./scripts/evaluation_tts.py ./checkpoints/$voice_name/tts_acoustic/gan/checkpoint_epoch50_Generator.pth ./checkpoints/$voice_name/tts_duration/gan/checkpoint_epoch100_Generator.pth ./data/$voice_name ./data/$voice_name/label_state_align/ ./generated/$voice_name/duration_acousic/gan
    end=$(date "+%s")
    time=$((end-start))
    echo "time used:$time seconds"
done
