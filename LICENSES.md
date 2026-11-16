# Licenses and credit

## Photos and labels

Aerial imagery from OpenAerialMap contributors, tree-crown annotations from the Restor Foundation OAM-TCD dataset (restor/tcd on Hugging Face). Licensed CC BY 4.0. Only CC-BY-4.0-licensed tiles are used..

- Source: OAM-TCD (Restor Foundation Tree Crown Delineation), OpenAerialMap aerial tree-crown imagery (https://huggingface.co/datasets/restor/tcd)
- License: CC BY 4.0
- Changes made for this demo: a subset of 100 photos; labels converted to CVAT format; an
  image-level tag added by rule on the answer-key photos.

- Illustrative aerial vegetation imagery. It does not separate gas pipeline rights-of-way from electric line corridors; gas versus electric is talk-track framing only.
- Both OAM-TCD categories (individual tree and group of trees) are mapped to the single vegetation polygon label.
- Source 2048 px tiles at 10 cm per pixel are cut into four 1024 px tiles. Annotations stored as run-length masks are skipped, so only polygon outlines are used.
- The leaf-on versus leaf-off split in the answer key is approximate, from a greenness heuristic, not from capture dates.

## Model

- The model is Urban Tree Segmentation on Roboflow Universe
  (https://universe.roboflow.com/tree-density-detection/urban-tree-segmentation/model/3),
  licensed CC BY 4.0. Its weights are not included (hosted by Roboflow, not redistributable).
  model/roboflow_veg_func.py calls it through the Roboflow API with your own key.
- The first-pass vegetation polygons in the backup were made in CVAT Online by a Roboflow-hosted model, Urban Tree Segmentation (https://universe.roboflow.com/tree-density-detection/urban-tree-segmentation/model/3), licensed CC BY 4.0. Its weights are trained and hosted by Roboflow; they are not included here and cannot be redistributed. Roboflow integration is a CVAT Online feature. The open-source way to run the same model is model/roboflow_veg_func.py, which calls the Roboflow API with your own Roboflow key. You do not have to run it: the model's first pass is already in the backup.

## CVAT

CVAT is open source under the MIT License: https://github.com/cvat-ai/cvat. `scripts/setup.sh`
downloads it at tag `v2.82.0`. CVAT Online features shown in `clickthrough.html` are not part
of the open-source release.
