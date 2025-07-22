%% HGF Wrapper Function, 2023
clear all 
dbstop if error


str_run = 'dont fit just process behavior'; % set this to '' or 'dont fit just process behavior'

if ispc
    root = 'L:/';    
    run = '1';   % MTurk Session 1,2,3
    res_dir = 'L:/rsmith/lab-members/cgoldman/Wellbeing/emotional_faces/model_output_local/test';
    rt_model = false;
    p_or_r = 'r'; %prediction or responses (for binary hgf) - p=prediction, r=responses
    show_plot = true;
    % for experiment mode, specify if mturk, stimtool, or inperson
    experiment_mode = "prolific";
    if experiment_mode == "inperson"
        subject = 'AA111';   % inperson Subject ID
    elseif experiment_mode == "mturk"
        subject = 'AM0JKZVOEOTMA';   % Mturk Subject ID (others AM0JKZVOEOTMA, A1IZ4NX41GKU4X, A1Q7VWUBIJOK17)
    elseif experiment_mode == "prolific"
        subject = '5590a34cfdf99b729d4f69dc'; %  5590a34cfdf99b729d4f69dc or 55bcd160fdf99b1c4e4ae632 or 6556a01177d7a552a0819714 or 65f335ba737e19c6aad352aa or 6682adb6c4cc2cb1c1fc7f58
    end
    perception_model = 'tapas_hgf_binary_config';       
    observation_model = 'tapas_unitsq_sgm_config'; %tapas_unitsq_sgm_config or tapas_condhalluc_obs2_config_CMG

elseif isunix 
    root = '/media/labs/';
    subject = getenv('SUBJECT') 
    run = getenv('RUN');   
    res_dir = getenv('RESULTS')
    rt_model = strcmp(getenv('MODEL'), 'true')
    p_or_r = getenv('PREDICTION')
    experiment_mode = getenv('EXPERIMENT')
    show_plot = false;
    
    perception_model = getenv('PERCEPTION_MODEL');
    observation_model = getenv('OBSERVATION_MODEL');
    
end

perception_model
observation_model


addpath('./HGF/')


if (experiment_mode == "mturk")
    file_path = [root 'NPC/DataSink/StimTool_Online/WBMTURK_Emotional_FacesCB' cb];
    directory = dir(file_path);
    index_array = find(arrayfun(@(n) contains(directory(n).name, ['emotional_faces_v2_' subject]),1:numel(directory)));
elseif (experiment_mode == "inperson")
    file_path = [root 'rsmith/wellbeing/data/raw/sub-' subject];
    directory = dir(file_path);
    index_array = find(arrayfun(@(n) contains(directory(n).name, {'EF_R2', 'EF_R1'}),1:numel(directory)));

elseif (experiment_mode == "prolific")
    file_paths = {[root 'NPC/DataSink/StimTool_Online/WB_Emotional_Faces'], [root 'NPC/DataSink/StimTool_Online/WB_Emotional_Faces_CB']};
    for k = 1:length(file_paths)
        file_path = file_paths{k};
        directory = dir(file_path);
        % sort by date
        dates = datetime({directory.date}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');
        % Sort the dates and get the sorted indices
        [~, sortedIndices] = sort(dates);
        % Use the sorted indices to sort the structure array
        directory = directory(sortedIndices);
        index_array = find(arrayfun(@(n) contains(directory(n).name, ['emotional_faces_v2_' subject]),1:numel(directory)));
        % check if this person's file is in the directory
        if ~isempty(index_array)
            break;
        end
    end
    if strcmp(file_path, [root 'NPC/DataSink/StimTool_Online/WB_Emotional_Faces']); cb = '1'; else; cb='2';end

end

% initialize has_practice_effects to false, tracking if this participant's
% first complete behavioral file came after they played the task a little
% bit
has_practice_effects = false;
if length(index_array) > 1
    disp("WARNING, MULTIPLE BEHAVIORAL FILES FOUND FOR THIS ID. USING FIRST ONE")
end





for k=1:length(index_array)
    raw = readtable([file_path '/' directory(index_array(k)).name]);
    % Add a trial column for inperson (because it's currently called
    % trial_number)
    % Assign the value of cb based on the file name (EF_R1 corresponds to
    % cb1 and EF_R2 corresponds to cb2)
    if strcmp(experiment_mode,"inperson")
        raw.trial = raw.trial_number;
        if contains(directory(index_array(k)).name,"EF_R1")
            cb = '1';
        elseif contains(directory(index_array(k)).name,"EF_R2")
            cb = '2';
        end
    end
    if any(cellfun(@(x) isequal(x, 'MAIN'), raw.trial_type)) && (max(raw.trial)<199)
        has_practice_effects = true;
    end
    
    if max(raw.trial)<199
        run_script=0;
        continue;
    else 
        run_script=1;
    end


    try
        
        if run_script==1
            [x, file_table, processed_table] = hgf_function(str_run, raw, rt_model, p_or_r, cb, experiment_mode,perception_model,observation_model);
            
            
            if show_plot & ~strcmp(str_run,'dont fit just process behavior')
                if strcmp(observation_model,'tapas_condhalluc_obs2_config_CMG')
                     tapas_hgf_binary_condhalluc_plotTraj(x)
                else
                     tapas_hgf_binary_plotTraj(x)
                end

            end
            if experiment_mode == "mturk" | experiment_mode == "prolific"
                resp_index = find(file_table.event_type==6)+1;
                resp_table = file_table(resp_index,:);
                resp_table.score = file_table(find(file_table.event_type==9),:).response;
                predict_index = find(file_table.event_type==12);
                predict_table = file_table(predict_index,:);
                predict_table.trial_number = predict_table.trial;
                resp_table.trial_number = resp_table.trial;
            elseif experiment_mode == "inperson"
                % note that these are zero indexed
                resp_index = find(file_table.event_code==9);
                resp_table = file_table(resp_index,:);
                resp_table.score = resp_table.response;

                predict_index = find(file_table.event_code==6);
                predict_table = file_table(predict_index,:);
                
                for i=resp_table.trial_number'
                    trial_type = file_table(file_table.trial_number == i & file_table.event_code == 11,:).trial_type(1);
                    resp_table(resp_table.trial_number == i, :).trial_type = trial_type;

                    % if the person did missed this trial, fill in
                    % absolute/response time
                    if isempty(file_table(file_table.trial_number == i & file_table.event_code == 8,:))
                        resp_table(resp_table.trial_number == i, :).absolute_time = 999999999999;
                        resp_table(resp_table.trial_number == i, :).response_time = {'NA'};
                    else
                        absolute_time = file_table(file_table.trial_number == i & file_table.event_code == 8,:).absolute_time(1);
                        resp_table(resp_table.trial_number == i, :).absolute_time = absolute_time;
                        response_time = file_table(file_table.trial_number == i & file_table.event_code == 8,:).response_time(1);
                        resp_table(resp_table.trial_number == i, :).response_time = response_time;
                        choice = file_table(file_table.trial_number == i & file_table.event_code == 8,:).response(1);
                        resp_table(resp_table.trial_number == i, :).response = choice;
                        result = file_table(file_table.trial_number == i & file_table.event_code == 8,:).result(1);
                        resp_table(resp_table.trial_number == i, :).result = result;


                    end

                end
                for i=resp_table.trial_number'
                    trial_type = file_table(file_table.trial_number == i & file_table.event_code == 11,:).trial_type(1);
                    resp_table(resp_table.trial_number == i, :).trial_type = trial_type;
                end
                for i=predict_table.trial_number'
                    trial_type = file_table(file_table.trial_number == i & file_table.event_code == 11,:).trial_type(1);
                    predict_table(predict_table.trial_number == i, :).trial_type = trial_type;
                end
            end

            if strcmp(str_run, 'dont fit just process behavior')
                % Build the processed behavioral file for subsequent
                % analysis or fitting in RxInfer
                % Extract these columns from the responses table
                resp_cols={'trial_number','trial_type','absolute_time','response_time','response','result', 'score'};
                % Extract these columns from the predictions table
                pred_cols={'absolute_time','response_time','response','result'};
                
                % Rename overlapping columns with prefixes
                rename={'absolute_time','response_time','response','result'};
                for i=1:length(rename)
                  resp_table.Properties.VariableNames{strcmp(resp_table.Properties.VariableNames,rename{i})}=['resp_' rename{i}];
                  predict_table.Properties.VariableNames{strcmp(predict_table.Properties.VariableNames,rename{i})}=['pred_' rename{i}];
                end
                
                % Update column names after renaming
                resp_cols_prefixed={'trial_number','trial_type','resp_absolute_time','resp_response_time','resp_response','resp_result', 'score'};
                pred_cols_prefixed={'pred_absolute_time','pred_response_time','pred_response','pred_result'};
                
                % Combine into one table
                combined_table=[resp_table(:,resp_cols_prefixed),predict_table(:,pred_cols_prefixed)];

                % Define trial types as type1 (expected; sad-high or
                % angry-low) vs type2 (unexpected; sad-low or angry-high)
                type1=ismember(combined_table.trial_type,{'sad_high','angry_low'});
                type2=ismember(combined_table.trial_type,{'sad_low','angry_high'});
                
                % Use the result column to determine if the subject thought
                % the trial was type1 or type2
                combined_table.pred_sad_high_or_angry_low=double((strcmp(combined_table.pred_result,'correct') & type1) | ...
                                                                 (strcmp(combined_table.pred_result,'incorrect') & type2));
                
                % Make sure too slow responses are coded as NaN
                resp_result=combined_table.resp_result;
                resp_logic=(strcmp(resp_result,'correct') & type1) | (strcmp(resp_result,'incorrect') & type2);
                too_slow=contains(resp_result,'too slow');
                combined_table.resp_sad_high_or_angry_low=nan(height(combined_table),1);
                combined_table.resp_sad_high_or_angry_low(~too_slow)=double(resp_logic(~too_slow));
                % Record if the subject observed type1 or type2
                combined_table.observed_sad_high_or_angry_low = ismember(combined_table.trial_type, {'sad_high','angry_low'});
                % Record the intensity of the face
                combined_table.face_intensity = processed_table.face_intensity;
                writetable(combined_table, [res_dir '/task_data_' subject '_processed_data.csv'])
                return;
            end

            if rt_model
                %model = 'rt-HGF';

                sub_table.ID = subject;
                sub_table.run = run;
                sub_table.counterbalance = cb;
                % MODEL-BASED
                sub_table.omega_2 = x.p_prc.om(2);
                sub_table.omega_3 = x.p_prc.om(3);
                sub_table.beta_0 = x.p_obs.be0;
                sub_table.beta_1 = x.p_obs.be1;
                sub_table.beta_2 = x.p_obs.be2;
                sub_table.beta_3 = x.p_obs.be3;
                sub_table.beta_4 = x.p_obs.be4;
                sub_table.zeta = x.p_obs.ze;
                sub_table.AIC = x.optim.AIC;
                sub_table.LME = x.optim.LME;

            else
                %model = 'binary-HGF';

                sub_table.ID = subject;
                sub_table.run = run;
                sub_table.perception_model = perception_model;
                sub_table.observation_model = observation_model;
                % MODEL-BASED
                sub_table.mu_initial_2 = x.p_prc.mu_0(2);
                sub_table.mu_initial_3 = x.p_prc.mu_0(3);
                sub_table.sigma_initial_2 = x.p_prc.sa_0(2);
                sub_table.sigma_initial_3 = x.p_prc.sa_0(3);
                sub_table.rho_2 = x.p_prc.rho(2);
                sub_table.rho_3 = x.p_prc.rho(3);
                sub_table.kappa_2 = x.p_prc.ka(1);
                sub_table.kappa_3 = x.p_prc.ka(2);                
                sub_table.omega_2 = x.p_prc.om(2);
                sub_table.omega_3 = x.p_prc.om(3);
                if strcmp(observation_model,'tapas_unitsq_sgm_config')
                    sub_table.zeta = x.p_obs.ze;
                elseif strcmp(observation_model,'tapas_condhalluc_obs2_config') || strcmp(observation_model,'tapas_condhalluc_obs2_config_CMG')
                    sub_table.h_intensity_sal = x.p_obs.h_intensity_sal;
                    sub_table.l_intensity_conf = x.p_obs.l_intensity_conf;
                    sub_table.be = x.p_obs.be;
                    sub_table.nu = x.p_obs.nu;               
                end
                
                
                
                sub_table.AIC = x.optim.AIC;
                sub_table.LME = x.optim.LME;      
                sub_table.avg_act = sum(x.optim.action_probs(~isnan(x.optim.action_probs)))/length(x.optim.action_probs(~isnan(x.optim.action_probs)));
                sub_table.model_acc = sum(x.optim.action_probs > 0.5)/length(x.optim.action_probs(~isnan(x.optim.action_probs)));
                sub_table.variance = var(x.optim.action_probs(~isnan(x.optim.action_probs)));
            end
            % MODEL FREE
            sub_table.has_practice_effects = has_practice_effects;
            %sub_table.model = model;
            sub_table.p_or_r = p_or_r;
            
            model_free_struct = faces_model_free(root,cb, experiment_mode,resp_table,predict_table);
            mf_fields = fieldnames(model_free_struct);
            for i = 1:numel(mf_fields)
               if isfield(sub_table, model_free_struct.(mf_fields{i}))
                   error("Tried to write over a field in sub_table!!");
               else
                   sub_table.(mf_fields{i}) = model_free_struct.(mf_fields{i});
               end
            end
           

           %save([res_dir '/output_' model '_' 'cb' cb '_' subject], 'sub_table');
           writetable(struct2table(sub_table), [res_dir '/faces_' subject '_T' num2str(run) '_cb' cb '_' p_or_r '_fits.csv'])
           saveas(gcf, [res_dir '/faces_' subject '_T' num2str(run) '_cb' cb '_' perception_model '_' observation_model '_' p_or_r '_image.png']);
           clear all; close all;
           break; % break out of for loop because full file ran without error
        end
    catch e
        fprintf("Behavioral file caused script to error for %s\n", subject);
        fprintf("Error message: %s\n", e.message);
        for k = 1:length(e.stack)
            fprintf("Error in %s at line %d\n", e.stack(k).name, e.stack(k).line);
        end
        disp(e); % Still useful to display the full error object
        clear all; close all;
    end

end
%tapas_hgf_binary_plotTraj(x)
