close all
file = 'data/c9_p0635_s04.wav';
[data, sample_rate]=audioread(file);

% normalizace dat
data=data./abs(max(data));

% the minimal value of a sample to be considered talking volume
open_threshold=0.15;
% how long to keep the gate open for after the samples fall below the
% threshold in seconds
release_time=0.2;

% used to ignore pops and clicks (sample count) - presneji nahravku s
% cislem 3
start_minimum=500;

% start and end of the word
start_sample=0;
end_sample=0;

% states
open=false;
closing=false;
closed=true;

% closing state counter
release_left=0;
start_counter=0;
first_above_threshold=0;

% loop through all the samples
for index=1:length(data)
    sample=data(index);
    if abs(sample) >= open_threshold
        % save, where we first hit above treashold in case this is the
        % actual start of the word
        if first_above_threshold==0
            first_above_threshold=index;
        end
        if index-first_above_threshold >= start_minimum
            % set the state to OPEN and use the previously saved index
            open=true;
            closing=false;
            closed=false;
            if start_sample == 0
                 % if the start of the word hasn't been recorded yet,
                 % record it
                start_sample=first_above_threshold;
            end
        end
    else
        if open
            % start closing the gate
            open=false;
            closing=true;
            release_left=sample_rate*release_time;
        elseif closing
            if release_left == 0
                % after the specified release time, close the gate and
                % record the end of the word
                closing=false;
                closed=true;
                if end_sample == 0
                    % if the end of the word hasn't been recorded yet,
                    % record it
                    end_sample=index;
                end
            end
            % decrease the release counter
            release_left=release_left-1;
        elseif closed
            % after some time, twice as long as the minimum requirement in
            % this case, drop the first_above_threshold
            if index-first_above_threshold >= 2*start_minimum
                first_above_threshold=0;
            end
        end
    end
end
fprintf('File: %s - Word starts at %0.2fs (sample %d) and ends at %0.2fs (sample %d)\n', file, start_sample/sample_rate, start_sample, end_sample/sample_rate, end_sample)
sound(data(start_sample:end_sample), sample_rate)

plot(data)
hold on
xline(start_sample,Label='Začátek slova')
xline(end_sample, Label='Konec slova')