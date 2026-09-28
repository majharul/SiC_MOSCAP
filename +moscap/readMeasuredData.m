function measured = readMeasuredData(filePath)
%READMEASUREDDATA Load measured C-Vg data from CSV/TXT file.
%   Supports absolute capacitance and already-normalized C/max(C) columns.

measured = [];
try
    T = readtable(filePath, 'VariableNamingRule', 'preserve');
    data = table2array(T);
    if size(data, 2) < 2 || ~isnumeric(data)
        return;
    end

    Vg = data(:, 1);
    Cmatrix = data(:, 2:end);
    rawNames = T.Properties.VariableNames(2:end);

    % Spreadsheet exports commonly leave trailing empty columns. Remove
    % them before fillmissing/all-finite validation.
    keepColumn = any(isfinite(Cmatrix), 1);
    Cmatrix = Cmatrix(:, keepColumn);
    rawNames = rawNames(keepColumn);
    if isempty(Cmatrix)
        return;
    end
    validRow = isfinite(Vg) & any(isfinite(Cmatrix), 2);
    Vg = Vg(validRow);
    Cmatrix = Cmatrix(validRow, :);

    if isempty(Vg)
        return;
    end

    nameText = lower(strjoin(rawNames, ' '));
    isNormalized = contains(nameText, 'c/cmax') || ...
        contains(nameText, 'c/max') || contains(nameText, 'normalized');

    % Auto-detect absolute units only when the file is not normalized.
    for c = 1:size(Cmatrix, 2)
        cc = Cmatrix(:, c);
        medVal = median(abs(cc(isfinite(cc))));
        if ~isNormalized && ~isempty(medVal) && medVal < 1e-6
            Cmatrix(:, c) = cc * 1e12;
        end
    end

    Cmatrix = fillmissing(Cmatrix, 'linear', 1, 'EndValues', 'nearest');
    valid = isfinite(Vg) & all(isfinite(Cmatrix), 2);
    Vg = Vg(valid);
    Cmatrix = Cmatrix(valid, :);

    if isempty(Vg)
        return;
    end

    if isempty(rawNames)
        rawNames = arrayfun(@(k) sprintf('C%d', k), 1:size(Cmatrix, 2), 'UniformOutput', false);
    end

    measured = struct();
    measured.Vg = Vg(:).';
    measured.Ccols = Cmatrix.';
    measured.Ccols_pF = Cmatrix.';
    measured.colNames = rawNames;
    measured.selectedCol = 1;
    measured.isNormalized = isNormalized;
    if isNormalized
        measured.normalizationMode = 'max';
        measured.unitLabel = 'C/max(C)';
    else
        measured.normalizationMode = 'cox';
        measured.unitLabel = 'pF';
    end
    measured.frequenciesHz = nan(1, numel(rawNames));
    for c = 1:numel(rawNames)
        measured.frequenciesHz(c) = parseFrequency(rawNames{c});
    end
    measured.source = filePath;

catch
    measured = [];
end
end

function frequencyHz = parseFrequency(name)
%PARSEFREQUENCY Extract frequency and SI prefix from a column heading.

frequencyHz = NaN;
token = regexp(lower(name), '([0-9]*\.?[0-9]+)\s*(ghz|mhz|khz|hz)', ...
    'tokens', 'once');
if isempty(token)
    return;
end
frequencyHz = str2double(token{1});
switch token{2}
    case 'ghz'
        frequencyHz = frequencyHz * 1e9;
    case 'mhz'
        frequencyHz = frequencyHz * 1e6;
    case 'khz'
        frequencyHz = frequencyHz * 1e3;
end
end
