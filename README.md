# HGF Pipeline – Emotional Faces Task

This repository contains a preprocessing and modeling pipeline for the Emotional Faces Task using the **Hierarchical Gaussian Filter (HGF)** framework. It supports binary-choice and reaction-time (RT) models, multiple experiment sources, and cluster-scale execution.

## Overview

For each subject, the pipeline:

1. Loads raw behavioral data (inperson, MTurk, or Prolific)
2. Processes task data using:
   - `get_responses` (binary models), or
   - `get_rts` (RT models)
3. Optionally stops after preprocessing only
4. Fits an HGF model using **TAPAS** with **modified perception and observation models**
5. Extracts model-based and model-free metrics
6. Saves subject-level CSV outputs and diagnostic plots

## Key Files

- `main_hgf_wrapper.m`  
  Top-level MATLAB script. Handles data discovery, preprocessing, model fitting, and saving outputs.

- `hgf_function.m`  
  Core pipeline function. Calls `get_responses` / `get_rts`, prepares inputs, and fits models via TAPAS.

- `HGF/`  
  TAPAS toolbox code, including **locally modified perceptual and observation model configs**.

- `run_faces_HGF.py`  
  Python launcher for submitting subject-level jobs to a SLURM cluster.

- `run_HGF.ssub`  
  SLURM submission script called by the Python launcher.

## Behavioral-Only Mode

To preprocess data without fitting a model, set:

```
str_run = 'dont fit just process behavior'
```

The pipeline will output a cleaned, trial-level behavioral CSV and exit before model fitting.

## Model Fitting

- **Binary HGF**: fits choice probabilities using `tapas_fitModel_actprob`
- **RT-HGF**: fits log reaction times using `tapas_fitModel`

Both rely on TAPAS, with task-specific modifications to the perception and observation models.

## Cluster Execution

Jobs are submitted via:

```
python run_faces_HGF.py <results_dir> <model> <p|r> <experiment> <perception_model> <observation_model>
```

One SLURM job is launched per subject, with logs written to a `logs/` subdirectory.

## Outputs

Per subject:
- CSV with model parameters and model-free metrics
- Diagnostic belief-trajectory plot
- (Optional) processed behavioral CSV (preprocessing-only mode)

## Notes

- Subjects with incomplete runs are skipped
- Practice effects are detected and recorded
- MATLAB state is cleared between subjects to avoid contamination

Internal research code for the Wellbeing project.
