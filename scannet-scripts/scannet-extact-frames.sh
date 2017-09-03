#!/bin/bash
echo "Bash version ${BASH_VERSION}..."

DATASET_ROOT=/media/cideep/HardDisk/RGBD-datasets-raw/scannet
SENS_EXCUTABLE=${DATASET_ROOT}/ScanNet-git/SensReader/sens
SOURCE_PATH=${DATASET_ROOT}/scenes-raw
TARGET_PATH=${DATASET_ROOT}/scene-frames

for i in $(seq -f "%04g" 0 10)
do
	echo "iteration: " ${i}
	mkdir ${TARGET_PATH}/scene${i}_00
	${SENS_EXCUTABLE} ${SOURCE_PATH}/scene${i}_00/scene${i}_00.sens ${TARGET_PATH}/sceneimgs_${i}
done

