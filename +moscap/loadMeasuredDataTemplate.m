function measData = loadMeasuredDataTemplate(csvFilePath, varargin)
%LOADMEASUREDDATATEMPLATE Load measured C-V data from CSV template format.
%
% USAGE:
%   measData = moscap.loadMeasuredDataTemplate('measured_sic.csv')
%   measData = moscap.loadMeasuredDataTemplate(csvPath, 'Unit', 'pF', 'SkipRows', 1)
%
% CSV FORMAT (with header row):
%   First column:  Vg (V) OR Freq (Hz) OR Temp (K) - labeled in header
%   Remaining cols: Measured capacitances with headers like "Clow_1Hz", "Chigh_1MHz"
%
% EXAMPLE CSV:
%   Vg,Clow@1Hz,Chigh@1MHz
%   -10,406,405
%   -5,410,408
%   0,415,390
%   5,420,150
%   10,420,150
%
% INPUTS:
%   csvFilePath - Path to CSV file
%   
%   Name-Value Options:
%       'Unit'       - 'F', 'pF', 'nF' (default: 'pF')
%       'SkipRows'   - Rows to skip after header (default: 0)
%       'VgColumn'   - Column name or index for gate voltage (default: auto-detect)
%       'ClowColumn' - Column name for low-freq capacitance (default: auto-detect)
%       'ChighColumn'- Column name for high-freq capacitance (default: auto-detect)
%       'Verbose'    - Print progress (default: true)
%
% OUTPUTS:
%   measData - struct with fields:
%       .Vg         - Gate voltage (V)
%       .Clow       - Low-frequency capacitance (F)
%       .Chigh      - High-frequency capacitance (F) [if present in CSV]
%       .freq       - Frequency values (Hz) [if first column is frequency]
%       .temp       - Temperature values (K) [if first column is temperature]
%       .header     - Original CSV header line
%       .source     - Source file path
%
% AUTO-DETECTION LOGIC:
%   - First column header: "Vg", "Gate", "V" → gate voltage
%   - First column header: "Freq", "Frequency", "Hz" → frequency sweep
%   - First column header: "Temp", "Temperature", "K" → temperature sweep
%   - Remaining columns: "Clow", "C_low", "CLF" OR "Chigh", "C_high", "CHF"
%

% Parse options
p = inputParser();
addParameter(p, 'Unit', 'pF', @ischar);
addParameter(p, 'SkipRows', 0, @isnumeric);
addParameter(p, 'VgColumn', '', @ischar);
addParameter(p, 'ClowColumn', '', @ischar);
addParameter(p, 'ChighColumn', '', @ischar);
addParameter(p, 'Verbose', true, @islogical);
parse(p, varargin{:});

unit = p.Results.Unit;
skipRows = p.Results.SkipRows;
vgColName = p.Results.VgColumn;
clowColName = p.Results.ClowColumn;
chighColName = p.Results.ChighColumn;
verbose = p.Results.Verbose;

if verbose
    fprintf('Loading measured data from: %s\n', csvFilePath);
end

% Read CSV with preserved variable names
opts = detectImportOptions(csvFilePath, 'FileType', 'text');
opts.VariableNamingRule = 'preserve';
data = readtable(csvFilePath, opts);

% Get header
header = data.Properties.VariableNames;
if verbose
    fprintf('Detected columns: %s\n', strjoin(header, ', '));
end

% ===== AUTO-DETECT FIRST COLUMN TYPE =====
firstColName = header{1};
% Remove parentheses and special chars for matching
firstColNameClean = regexprep(lower(firstColName), '[()_@]', '');

% Detect what first column represents
isVgColumn = any(contains(firstColNameClean, {'vg', 'gate', 'voltage'}));
isFreqColumn = any(contains(firstColNameClean, {'freq', 'hz', 'omega'}));
isTempColumn = any(contains(firstColNameClean, {'temp', 'kelvin', 'k'}));

if verbose
    if isVgColumn
        fprintf('→ First column detected as: Gate Voltage (V)\n');
    elseif isFreqColumn
        fprintf('→ First column detected as: Frequency (Hz)\n');
    elseif isTempColumn
        fprintf('→ First column detected as: Temperature (K)\n');
    else
        fprintf('→ First column type unknown, assuming Gate Voltage\n');
        isVgColumn = true;
    end
end

% ===== AUTO-DETECT CAPACITANCE COLUMNS =====
clowIdx = [];
chighIdx = [];

for i = 1:length(header)
    % Clean header for matching - keep letters only for easier matching
    colName_lower = lower(header{i});
    colNameLettersOnly = regexprep(colName_lower, '[^a-z]', '');
    
    if isempty(clowIdx)
        % Check for "clow" patterns: clow, clowfreq, c1hz, clf, clf, c_low, clow_freq, etc
        if contains(colNameLettersOnly, 'clow') || ...
           (contains(colNameLettersOnly, 'c') && contains(colNameLettersOnly, 'hz') && ~contains(colNameLettersOnly, 'high'))
            clowIdx = i;
        end
    end
    
    if isempty(chighIdx)
        % Check for "chigh" patterns: chigh, chighfreq, c1mhz, chf, c_high, chigh_freq, etc
        if contains(colNameLettersOnly, 'chigh') || ...
           (contains(colNameLettersOnly, 'c') && contains(colNameLettersOnly, 'mhz'))
            chighIdx = i;
        end
    end
end

if isempty(clowIdx)
    error('Could not find low-frequency capacitance column. Check CSV headers.');
end

if verbose
    fprintf('→ Clow column: %s (index %d)\n', header{clowIdx}, clowIdx);
    if ~isempty(chighIdx)
        fprintf('→ Chigh column: %s (index %d)\n', header{chighIdx}, chighIdx);
    else
        fprintf('→ Chigh column: Not found\n');
    end
end

% ===== EXTRACT DATA =====
% Convert units to Farads
unitScale = 1;
switch lower(unit)
    case 'pf'
        unitScale = 1e-12;
    case 'nf'
        unitScale = 1e-9;
    case 'f'
        unitScale = 1;
    otherwise
        warning('Unknown unit %s, assuming pF', unit);
        unitScale = 1e-12;
end

% Extract first column
firstColData = data.(header{1});

% Extract capacitance columns
ClowRaw = data.(header{clowIdx});
Clow = double(ClowRaw) * unitScale;

if ~isempty(chighIdx)
    ChighRaw = data.(header{chighIdx});
    Chigh = double(ChighRaw) * unitScale;
else
    Chigh = [];
end

% ===== POPULATE OUTPUT STRUCT =====
measData = struct();
measData.header = header;
measData.source = csvFilePath;

if isVgColumn
    measData.Vg = double(firstColData);
    measData.Clow = Clow;
    measData.Chigh = Chigh;
    measData.freq = [];
    measData.temp = [];
elseif isFreqColumn
    % For frequency-dependent measurements, create Vg from row index or separate column
    measData.freq = double(firstColData);
    measData.Clow = Clow;
    measData.Chigh = Chigh;
    measData.Vg = (1:length(Clow))';  % Default: use row index
    measData.temp = [];
    if verbose
        fprintf('→ Frequency sweep: %d points, Freq range %.2e - %.2e Hz\n', ...
            length(measData.freq), min(measData.freq), max(measData.freq));
    end
elseif isTempColumn
    % For temperature-dependent measurements
    measData.temp = double(firstColData);
    measData.Clow = Clow;
    measData.Chigh = Chigh;
    measData.Vg = (1:length(Clow))';  % Default: use row index
    measData.freq = [];
    if verbose
        fprintf('→ Temperature sweep: %d points, Temp range %.1f - %.1f K\n', ...
            length(measData.temp), min(measData.temp), max(measData.temp));
    end
else
    measData.Vg = double(firstColData);
    measData.Clow = Clow;
    measData.Chigh = Chigh;
    measData.freq = [];
    measData.temp = [];
end

if verbose
    fprintf('Data loaded: %d points\n', length(measData.Clow));
    fprintf('Clow range: %.2f - %.2f pF\n', min(measData.Clow)*1e12, max(measData.Clow)*1e12);
    if ~isempty(measData.Chigh)
        fprintf('Chigh range: %.2f - %.2f pF\n', min(measData.Chigh)*1e12, max(measData.Chigh)*1e12);
    end
end

end
