#!/bin/bash

set -e #Exit immediately if a command exits with a non-zero status.

#get parameters
hparams_name=$1
inputs_dir=$2
outputs_dir=$3
dst_root=$4
generator_warmup_epoch=$5
discriminator_warmup_epoch=$6
spoofing_total_epoch=$7
total_epoch=$8
experiment_id=$9
lang=${10}
specify_gpu=${11}
w_d=1
max_files=-1 # -1 means `use full data`.
# To save time for training, switch off `run_baseline and `run_spoofing_warmup
run_baseline=0
run_generator_warmup=1
run_discriminator_warmup=1
run_spoofing_warmup=0
run_adversarial=1

#create identifier
randstr=$(python -c "from datetime import datetime; print(str(datetime.now()).replace(' ', '_'))")
randstr=${experiment_id}_${randstr}

# Checkpoint naming rule:
# checkpoint_epoch{epoch}_{Generator/Discriminator}.pth
baseline_checkpoint=$dst_root/baseline/checkpoint_epoch${total_epoch}_Generator.pth
spoofing_checkpoint=$dst_root/spoofing/checkpoint_epoch${spoofing_total_epoch}_Discriminator.pth

#print parameter
echo "Experiment id:" $experiment_id
echo "Name of hyper paramters:" $hparams_name
echo "Network inputs directory:" $inputs_dir
echo "Network outputs directory:" $outputs_dir
echo "Model checkpoints saved at:" $dst_root
echo "Experiment identifier:" $randstr
echo "Generator wamup epoch:" $generator_warmup_epoch
echo "Discriminator wamup epoch:" $discriminator_warmup_epoch
echo "Total epoch for spoofing model training:" $spoofing_total_epoch
echo "Total epoch for GAN:" $total_epoch

#training
### Baseline ###
if [ "${run_baseline}" == 1 ]; then
    CUDA_VISIBLE_DEVICES=$specify_gpu python ./scripts/train.py --hparams_name="$hparams_name" \
        --max_files=$max_files --w_d=0 --hparams="nepoch=$total_epoch" \
        --checkpoint-dir=$dst_root/baseline $inputs_dir $outputs_dir \
        --log-event-path="log/${hparams_name}_baseline_$randstr" \
        --disable-slack
fi

### GAN ###

# Generator warmup
# only train generator
if [ "${run_generator_warmup}" == 1 ]; then
    CUDA_VISIBLE_DEVICES=$specify_gpu python ./scripts/train.py --hparams_name="$hparams_name" \
        --lang=$lang \
        --max_files=$max_files --w_d=0 --hparams="nepoch=$generator_warmup_epoch" \
        --checkpoint-dir=$dst_root/gan_g_warmup $inputs_dir $outputs_dir \
        --log-event-path="log/${hparams_name}_generator_warmup_$randstr" \
        --disable-slack
fi

# Discriminator warmup
# only train discriminator
if [ "${run_discriminator_warmup}" == 1 ]; then
    CUDA_VISIBLE_DEVICES=$specify_gpu python ./scripts/train.py --hparams_name="$hparams_name" \
        --lang=$lang \
        --max_files=$max_files --w_d=${w_d} \
        --checkpoint-g=$dst_root/gan_g_warmup/checkpoint_epoch${generator_warmup_epoch}_Generator.pth \
        --discriminator-warmup --hparams="nepoch=$discriminator_warmup_epoch" \
        --checkpoint-dir=$dst_root/gan_d_warmup $inputs_dir $outputs_dir \
        --restart_epoch=0 \
        --log-event-path="log/${hparams_name}_discriminator_warmup_$randstr" \
        --disable-slack
fi

# Discriminator warmup for spoofing rate computation
# try to discrimnate baseline's generated features as fake
# only train discriminator
if [ "${run_spoofing_warmup}" == 1 ]; then
    CUDA_VISIBLE_DEVICES=$specify_gpu python ./scripts/train.py --hparams_name="$hparams_name" \
        --lang=$lang \
        --max_files=$max_files --w_d=${w_d} --hparams="nepoch=$spoofing_total_epoch" \
        --checkpoint-g=${baseline_checkpoint} \
        --discriminator-warmup \
        --checkpoint-dir=$dst_root/spoofing \
        --restart_epoch=0 $inputs_dir $outputs_dir \
        --log-event-path="log/${hparams_name}_spoofing_model_warmup_$randstr" \
        --disable-slack
fi

# Finally do joint training generator and discriminator
# start from ${generator_warmup_epoch}
if [ "${run_adversarial}" == 1 ]; then
    CUDA_VISIBLE_DEVICES=$specify_gpu python ./scripts/train.py --hparams_name="$hparams_name" \
        --lang=$lang \
        --max_files=$max_files \
        --checkpoint-d=$dst_root/gan_d_warmup/checkpoint_epoch${discriminator_warmup_epoch}_Discriminator.pth \
        --checkpoint-g=$dst_root/gan_g_warmup/checkpoint_epoch${generator_warmup_epoch}_Generator.pth \
        --checkpoint-r=${spoofing_checkpoint} \
        --w_d=${w_d} --hparams="nepoch=$total_epoch" \
        --checkpoint-dir=$dst_root/gan \
        --reset_optimizers --restart_epoch=${generator_warmup_epoch} \
        $inputs_dir $outputs_dir \
        --log-event-path="log/${hparams_name}_adversarial_training_$randstr"
fi
