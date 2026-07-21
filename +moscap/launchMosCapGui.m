function launchMosCapGui(params)
%LAUNCHMOSCAPGUI Interactive C-V explorer GUI with real-time simulation.
%   Creates collapsible parameter panels, real-time plotting, measured data comparison.

fig = uifigure('Name', 'MOSCAP C-V Explorer', 'Color', 'w', 'Position', [80 40 1200 800]);

% Main layout: 3 rows (top controls, middle content, bottom metrics)
mainGrid = uigridlayout(fig, [3, 1]);
mainGrid.RowHeight = {40, '1x', 30};

% ===== TOP BAR =====
topGrid = uigridlayout(mainGrid, [1, 7]);
topGrid.Layout.Row = 1;
topGrid.ColumnWidth = {180, 100, 100, 60, 100, 60, '1x'};
topGrid.Padding = [0 5 0 5];

btnLoad = uibutton(topGrid, 'Text', 'Load Measured CSV/TXT', 'ButtonPushedFcn', @onLoadMeasured);
btnSiPreset = uibutton(topGrid, 'Text', 'Apply Si Preset', 'ButtonPushedFcn', @(~,~)applyPreset('Si'));
btnSiCPreset = uibutton(topGrid, 'Text', 'Apply SiC Preset', 'ButtonPushedFcn', @(~,~)applyPreset('4H-SiC'));

lblMaterial = uilabel(topGrid, 'Text', 'Material', 'FontWeight', 'bold');
lblMaterial.HorizontalAlignment = 'right';
materialValue = normalizeMaterialValue(params.material);
ddMaterial = uidropdown(topGrid, 'Items', {'Si', '4H-SiC'}, 'Value', materialValue, ...
    'ValueChangedFcn', @onMaterialChanged);

lblMeasCol = uilabel(topGrid, 'Text', 'Meas C', 'FontWeight', 'bold');
lblMeasCol.HorizontalAlignment = 'right';
ddMeasCol = uidropdown(topGrid, 'Items', {'N/A'}, 'Value', 'N/A', ...
    'ValueChangedFcn', @onMeasuredColumnChanged);

% ===== MAIN CONTENT =====
contentGrid = uigridlayout(mainGrid, [1, 2]);
contentGrid.Layout.Row = 2;
contentGrid.ColumnWidth = {400, '1x'};
contentGrid.Padding = [0 0 0 0];

% Left: Scrollable controls
controlsRoot = uipanel(contentGrid, 'Scrollable', 'on', 'BorderType', 'none');

panelGrid = uigridlayout(controlsRoot, [6, 1]);
panelGrid.RowHeight = {30, 'fit', 30, 'fit', 30, 'fit'};
panelGrid.Padding = [5 5 5 5];
panelGrid.RowSpacing = 2;

% Geometry section
headerGeom = uibutton(panelGrid, 'Text', '▼ Geometry', 'HorizontalAlignment', 'left', ...
    'ButtonPushedFcn', @(~,~)toggleSection('geom'));
headerGeom.Layout.Row = 1;

panelGeom = uipanel(panelGrid, 'Title', '');
panelGeom.Layout.Row = 2;
geomGrid = uigridlayout(panelGeom, [4, 3]);
geomGrid.RowHeight = {25, 25, 25, 25};
geomGrid.ColumnWidth = {140, '1x', 90};
geomGrid.Padding = [2 2 2 2];
geomGrid.RowSpacing = 4;
geomGrid.ColumnSpacing = 8;

% Electrostatics section
headerElectro = uibutton(panelGrid, 'Text', '▼ Electrostatics / Material', 'HorizontalAlignment', 'left', ...
    'ButtonPushedFcn', @(~,~)toggleSection('electro'));
headerElectro.Layout.Row = 3;

panelElectro = uipanel(panelGrid, 'Title', '');
panelElectro.Layout.Row = 4;
electroGrid = uigridlayout(panelElectro, [3, 3]);
electroGrid.RowHeight = {25, 25, 25};
electroGrid.ColumnWidth = {140, '1x', 90};
electroGrid.Padding = [2 2 2 2];
electroGrid.RowSpacing = 4;
electroGrid.ColumnSpacing = 8;

% Non-Ideal section
headerNonIdeal = uibutton(panelGrid, 'Text', '▼ Non-Ideal / Dynamics', 'HorizontalAlignment', 'left', ...
    'ButtonPushedFcn', @(~,~)toggleSection('nonideal'));
headerNonIdeal.Layout.Row = 5;

panelNonIdeal = uipanel(panelGrid, 'Title', '');
panelNonIdeal.Layout.Row = 6;
nonIdealGrid = uigridlayout(panelNonIdeal, [12, 3]);
nonIdealGrid.RowHeight = repmat({25}, 1, 12);
nonIdealGrid.ColumnWidth = {140, '1x', 90};
nonIdealGrid.Padding = [2 2 2 2];
nonIdealGrid.RowSpacing = 4;
nonIdealGrid.ColumnSpacing = 8;

% Right: Plot axes
ax = uiaxes(contentGrid);
ax.Box = 'on';
grid(ax, 'on');
xlabel(ax, 'Gate Voltage V_g (V)');
ylabel(ax, 'C_{gg} (pF)');
title(ax, 'Real-Time Simulated vs Measured C-V_g');

% ===== BOTTOM METRICS =====
lblMetrics = uilabel(mainGrid, 'Text', 'Measured metrics: N/A', 'FontWeight', 'bold', 'FontSize', 10);
lblMetrics.Layout.Row = 3;

% === SLIDER SETUP ===
controls = struct();
spec = moscap.guiHelpers.sliderSpecs(params);

controls.W = moscap.guiHelpers.addSlider(geomGrid, spec.W);
controls.L = moscap.guiHelpers.addSlider(geomGrid, spec.L);
controls.NF = moscap.guiHelpers.addSlider(geomGrid, spec.NF);
controls.tox = moscap.guiHelpers.addSlider(geomGrid, spec.tox);

controls.NaPeak = moscap.guiHelpers.addSlider(electroGrid, spec.NaPeak);
controls.phiMs = moscap.guiHelpers.addSlider(electroGrid, spec.phiMs);
controls.Qox = moscap.guiHelpers.addSlider(electroGrid, spec.Qox);

controls.tauGen = moscap.guiHelpers.addSlider(nonIdealGrid, spec.tauGen);
controls.smooth = moscap.guiHelpers.addSlider(nonIdealGrid, spec.smooth);
controls.Rs = moscap.guiHelpers.addSlider(nonIdealGrid, spec.Rs);
controls.Dit = moscap.guiHelpers.addSlider(nonIdealGrid, spec.Dit);
controls.tauIt = moscap.guiHelpers.addSlider(nonIdealGrid, spec.tauIt);
controls.Cbt = moscap.guiHelpers.addSlider(nonIdealGrid, spec.Cbt);
controls.tauBt = moscap.guiHelpers.addSlider(nonIdealGrid, spec.tauBt);
controls.Cpar = moscap.guiHelpers.addSlider(nonIdealGrid, spec.Cpar);
controls.stretch = moscap.guiHelpers.addSlider(nonIdealGrid, spec.stretch);
controls.invGain = moscap.guiHelpers.addSlider(nonIdealGrid, spec.invGain);
controls.invWidth = moscap.guiHelpers.addSlider(nonIdealGrid, spec.invWidth);

% === SETUP STATE AND INITIAL PLOT ===
state = struct();
state.params = params;
state.measured = [];
state.sectionExpanded = struct('geom', true, 'electro', true, 'nonideal', true);
state.baseSpec = spec;

sim0 = moscap.simulateMosCapCV(state.params);
state.sim = sim0;
state.curves = moscap.drawCurves(ax, sim0, state.measured);
guidata(fig, state);

% Set slider callbacks
setSliderCallback(controls.tox);
setSliderCallback(controls.W);
setSliderCallback(controls.L);
setSliderCallback(controls.NF);
setSliderCallback(controls.NaPeak);
setSliderCallback(controls.phiMs);
setSliderCallback(controls.Qox);
setSliderCallback(controls.Dit);
setSliderCallback(controls.tauIt);
setSliderCallback(controls.Cbt);
setSliderCallback(controls.tauBt);
setSliderCallback(controls.Cpar);
setSliderCallback(controls.stretch);
setSliderCallback(controls.Rs);
setSliderCallback(controls.smooth);
setSliderCallback(controls.invGain);
setSliderCallback(controls.invWidth);
setSliderCallback(controls.tauGen);

updateMetricsLabel();

% ===== NESTED CALLBACKS =====

    function applyPreset(mat)
        st = guidata(fig);
        st.params.material = mat;
        st.params = moscap.enforceMaterialConsistency(st.params, true);
        ddMaterial.Value = st.params.material;

        s = moscap.guiHelpers.sliderSpecs(st.params);
        moscap.guiHelpers.applyAllSpecsToControls(controls, s);
        moscap.guiHelpers.refreshSliderValueLabels(controls);

        st.sim = moscap.simulateMosCapCV(st.params);
        st.curves = moscap.drawCurves(ax, st.sim, st.measured); % redraw from scratch
        guidata(fig, st);
        updateMetricsLabel();
    end

            function toggleSection(sectionName)
        st = guidata(fig);
        if isempty(st) || ~isstruct(st) || ~isfield(st, 'sectionExpanded')
            return;  % GUI not fully initialized yet
        end
        current = st.sectionExpanded.(sectionName);
        st.sectionExpanded.(sectionName) = ~current;
        guidata(fig, st);
    end

    function onMaterialChanged(~, ~)
        applyPreset(ddMaterial.Value);
    end

    function onLoadMeasured(~, ~)
        [file, path] = uigetfile({'*.csv;*.txt', 'Data Files (*.csv, *.txt)'}, ...
            'Select measured C-Vg data');
        if isequal(file, 0)
            return;
        end

        measured = moscap.readMeasuredData(fullfile(path, file));
        if isempty(measured)
            uialert(fig, 'Measured file must have at least 2 numeric columns: Vg, Cgg(pF).', ...
                'Invalid File');
            return;
        end

        st = guidata(fig);
        st.measured = measured;
        ddMeasCol.Items = measured.colNames;
        ddMeasCol.Value = measured.colNames{measured.selectedCol};
        st.curves = moscap.drawCurves(ax, st.sim, st.measured); % redraw
        guidata(fig, st);
        updateMetricsLabel();
    end

    function onMeasuredColumnChanged(~, ~)
        st = guidata(fig);
        if isempty(st.measured)
            return;
        end
        idx = find(strcmp(st.measured.colNames, ddMeasCol.Value), 1, 'first');
        if isempty(idx)
            idx = 1;
        end
        st.measured.selectedCol = idx;
        st.curves = moscap.drawCurves(ax, st.sim, st.measured); % redraw
        guidata(fig, st);
        updateMetricsLabel();
    end

    function onAnySliderChanged(~, ~)
        st = guidata(fig);
        p = st.params;

        p.W = controls.W.slider.Value * 1e-6;
        p.L = controls.L.slider.Value * 1e-6;
        p.NF = max(1, round(controls.NF.slider.Value));
        p.tox = controls.tox.slider.Value * 1e-9;
        p.Na_peak = controls.NaPeak.slider.Value * 1e22;
        p.phi_ms = controls.phiMs.slider.Value;
        p.Qox_m2 = controls.Qox.slider.Value * 1e11;
        p.Dit_cm2eV = controls.Dit.slider.Value * 1e11;
        p.tau_it = controls.tauIt.slider.Value * 1e-6;
        p.Cbt_cm2eV = controls.Cbt.slider.Value * 1e11;
        p.tau_bt = controls.tauBt.slider.Value * 1e-6;
        p.Cpar_pF = controls.Cpar.slider.Value;
        p.stretch = max(controls.stretch.slider.Value, 1);
        p.Rs = controls.Rs.slider.Value;
        p.smoothWindow = max(1, round(controls.smooth.slider.Value));
        p.tau_gen = controls.tauGen.slider.Value * 1e-6;
        p.invGain = max(min(controls.invGain.slider.Value, 1), 0);
        p.invWidth = max(controls.invWidth.slider.Value, 0.01);
        p.lfFreqHz = 1;
        p.hfFreqHz = 1e6;

        p = moscap.enforceMaterialConsistency(p, false);

        moscap.guiHelpers.refreshSliderValueLabels(controls);

        sim = moscap.simulateMosCapCV(p);
        st.params = p;
        st.sim = sim;
        st.curves = moscap.drawCurves(ax, sim, st.measured); % redraw
        guidata(fig, st);
        updateMetricsLabel();
    end

    function updateMetricsLabel()
        st = guidata(fig);
        if isempty(st.measured)
            lblMetrics.Text = sprintf(['Measured metrics: N/A | ', ...
                'Material=%s | Sim Cmax = %.3f pF, Cmin = %.3f pF, Vfb = %.3f V, Na_eff = %.2e m^-3'], ...
                st.params.material, max(st.sim.Cmeas) * 1e12, min(st.sim.Cmeas) * 1e12, st.sim.Vfb, st.sim.Na_eff);
        else
            [rmsePf, maePf, nPts] = moscap.compareMeasured(st.sim, st.measured);
            lblMetrics.Text = sprintf(['Measured metrics: N = %d, RMSE = %.3f pF, MAE = %.3f pF | ', ...
                'Material=%s | Sim Cmax = %.3f pF, Cmin = %.3f pF'], ...
                nPts, rmsePf, maePf, st.params.material, max(st.sim.Cmeas) * 1e12, min(st.sim.Cmeas) * 1e12);
        end
    end

    function setSliderCallback(ctrl)
        ctrl.slider.ValueChangingFcn = [];
        ctrl.slider.ValueChangedFcn = @onAnySliderChanged;
    end

end

function value = normalizeMaterialValue(value)
%NORMALIZEMATERIALVALUE Map material aliases to GUI dropdown items.

if nargin == 0 || isempty(value)
    value = 'Si';
    return;
end

switch lower(strtrim(value))
    case {'sic', '4h-sic', '4h_siC', '4h sic'}
        value = '4H-SiC';
    otherwise
        value = 'Si';
end
end

