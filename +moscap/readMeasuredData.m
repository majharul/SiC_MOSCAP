function measured = readMeasuredData(filePath)
%READMEASUREDDATA Load measured C-Vg data from CSV/TXT file.
%   Auto-detects columns, converts units (F->pF), interpolates missing values.

measured = [];
try
    T = readtable(filePath, 'VariableNamingRule', 'preserve');
    data = table2array(T);
    if size(data, 2) < 2 || ~isnumeric(data)
        return;
    end

    Vg = data(:, 1);
    Cmatrix = data(:, 2:end);
    validRow = isfinite(Vg) & any(isfinite(Cmatrix), 2);
    Vg = Vg(validRow);
    Cmatrix = Cmatrix(validRow, :);

    if isempty(Vg)
        return;
    end

    % Auto-detect unit per column: convert from Farads to pF if values are very small.
    for c = 1:size(Cmatrix, 2)
        cc = Cmatrix(:, c);
        medVal = median(abs(cc(isfinite(cc))));
        if ~isempty(medVal) && medVal < 1e-6
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

    if width(T) >= 2
        rawNames = T.Properties.VariableNames(2:end);
    else
        rawNames = {};
    end

    if isempty(rawNames)
        rawNames = arrayfun(@(k) sprintf('C%d', k), 1:size(Cmatrix, 2), 'UniformOutput', false);
    end

    measured = struct();
    measured.Vg = Vg(:).';
    measured.Ccols_pF = Cmatrix.';
    measured.colNames = rawNames;
    measured.selectedCol = 1;

catch
    measured = [];
end
end
