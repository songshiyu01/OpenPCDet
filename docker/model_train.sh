#!/bin/bash
cd /root/OpenPCDet; python -m pcdet.datasets.nuscenes.nuscenes_dataset --func create_nuscenes_infos --cfg_file tools/cfgs/dataset_configs/nuscenes_dataset.yaml --version v1.0-mini
cd /root/OpenPCDet/tools; python train.py --cfg_file cfgs/nuscenes_models/cbgs_pp_multihead.yaml
