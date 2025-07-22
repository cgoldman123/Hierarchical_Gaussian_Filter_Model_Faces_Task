import sys, os, re, subprocess
from datetime import datetime


run = '1' # irrelevant for inperson
counterbalance = '2' # irrelevant for inperson
base_results = sys.argv[1]
model = sys.argv[2] # true if RT model
prediction = sys.argv[3] # indicate p or r for prediction or response
experiment_mode = sys.argv[4] # indicate inperson, mturk, or prolific
perception_model = sys.argv[5] # indicate perceptual model to fit
observation_model = sys.argv[6]  # indicate observation model to fit

timestamp = datetime.now().strftime('%m-%d-%y-%H_%M_%S')
results = f"{base_results}_{timestamp}"

if experiment_mode == 'inperson':
    subject_list_path = '/media/labs/rsmith/lab-members/cgoldman/Wellbeing/local/local_wellbeing_IDs.csv'
elif experiment_mode == 'prolific':
    subject_list_path = '/media/labs/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/emotional_faces_prolific_IDs.csv'

if model == 'false':
    model_name = 'binary'
else:
    model_name = 'rt'

if not os.path.exists(results):
    os.makedirs(results)
    print(f"Created results directory {results}")

if not os.path.exists(f"{results}/logs"):
    os.makedirs(f"{results}/logs")
    print(f"Created results-logs directory {results}/logs")

subjects = []
with open(subject_list_path) as infile:
    for line in infile:
        if 'record_id' or 'id' not in line:
            subjects.append(line.strip())
ssub_path = '/media/labs/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/VB_scripts/run_HGF.ssub'

# i = 0
for subject in subjects:

    # if subject != "6679689a61bf2c46ebba0863":
    #     continue

    stdout_name = f"{results}/logs/{subject}-%J.stdout"
    stderr_name = f"{results}/logs/{subject}-%J.stderr"

    jobname = f'HGF-{model_name}-fit-{subject}'
    os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} {subject} {run} {results} {model} {prediction} {counterbalance} {experiment_mode} {perception_model} {observation_model}")

    print(f"SUBMITTED JOB [{jobname}]")
    # if i == 10:
    #     break
    # i = i + 1



    ###python3 /media/labs/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/VB_scripts/run_faces_HGF.py  /media/labs/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/model_output_prolific/hgf_no_rt_responses_prolific "false" "r" "prolific" "tapas_hgf_binary_config" "tapas_condhalluc_obs2_config_CMG"
    ###python3 /media/labs/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/VB_scripts/run_faces_HGF.py  /media/labs/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/model_output_prolific/hgf_no_rt_predictions_prolific "false" "p" "prolific" "tapas_hgf_binary_config" "tapas_unitsq_sgm_config"

    ###python3 /media/labs/rsmith/lab-members/osanchez/wellbeing/emotional_faces/Hierarchical_Gaussian_Filter_Model_Faces_Task/run_faces_HGF.py  /media/labs/rsmith/lab-members/osanchez/wellbeing/emotional_faces/model_output/local/hgf_no_rt_responses_local "false" "r" "inperson" "tapas_hgf_binary_config" "tapas_condhalluc_obs2_config_CMG" 

#### DO NOT RUN SCRIPTS BELOW UNLESS PROCESSING DATA (will have to set str_run to 'dont fit just process behavior' in the main matlab file)
    ###python3 /media/labs/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/VB_scripts/run_faces_HGF.py  /media/labs/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/model_output_local/local_emotional_faces_processed_data "false" "r" "inperson" "tapas_hgf_binary_config" "tapas_condhalluc_obs2_config_CMG"
    ###python3 /media/labs/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/VB_scripts/run_faces_HGF.py  /media/labs/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/model_output_prolific/prolific_emotional_faces_processed_data "false" "r" "prolific" "tapas_hgf_binary_config" "tapas_condhalluc_obs2_config_CMG"


    ## joblist | grep HGF | grep -Po 98.... | xargs scancel

