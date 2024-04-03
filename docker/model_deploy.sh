#!/bin/bash
cd /root/OpenPCDet/tools; python onnx_utils/trans_pfe.py
cd /root/OpenPCDet/tools; python onnx_utils/trans_backbone_multihead.py
ls /root/OpenPCDet/output/*.onnx
onnx2trt /root/OpenPCDet/output/cbgs_pp_multihead_pfe.onnx -o /root/OpenPCDet/output/cbgs_pp_multihead_pfe.trt
onnx2trt /root/OpenPCDet/output/cbgs_pp_multihead_backbone.onnx -o /root/OpenPCDet/output/cbgs_pp_multihead_backbone.trt
ls /root/OpenPCDet/output/*.trt
cd /root/PointPillars_MultiHead_40FPS/build;./pointpillars_multihead_40fps_tests
