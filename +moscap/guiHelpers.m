classdef guiHelpers
%GUIHELPERS Static utility methods for MOSCAP GUI slider management.
%   All methods are Static so they can be called as:
%       moscap.guiHelpers.methodName(...)

    methods (Static)

        function ctrl = addSlider(parent, spec)
        %ADDSLIDER Create slider with label and value display in grid layout parent.

            ctrl = struct();
            ctrl.fmt = spec.fmt;
            ctrl.step = spec.step;

            row = moscap.guiHelpers.nextGridRow(parent);

            % Create label
            ctrl.label = uilabel(parent, 'Text', spec.name, 'FontWeight', 'bold', 'FontSize', 9);
            ctrl.label.Layout.Row = row;
            ctrl.label.Layout.Column = 1;

            % Create slider
            ctrl.slider = uislider(parent, 'Limits', [spec.min spec.max], 'Value', spec.value);
            ctrl.slider.Layout.Row = row;
            ctrl.slider.Layout.Column = 2;
            moscap.guiHelpers.applySliderStep(ctrl.slider, spec.min, spec.max, spec.step);

            % Create value display
            ctrl.value = uilabel(parent, 'Text', sprintf(spec.fmt, spec.value), ...
                'HorizontalAlignment', 'right', 'FontSize', 9);
            ctrl.value.Layout.Row = row;
            ctrl.value.Layout.Column = 3;
        end

        function row = nextGridRow(parent)
        %NEXTGRIDROW Return the next available row index for a slider row layout.

            if isempty(parent.UserData) || ~isstruct(parent.UserData) || ~isfield(parent.UserData, 'nextSliderRow')
                parent.UserData = struct('nextSliderRow', 1);
            end

            row = parent.UserData.nextSliderRow;
            parent.UserData.nextSliderRow = row + 1;
        end
        function applySpecToControl(ctrl, spec)
        %APPLYSPECTOCONTROL Update control limits, value, formatting to match spec.

            ctrl.slider.Limits = [spec.min spec.max];
            ctrl.slider.Value = spec.value;
            ctrl.fmt = spec.fmt;
            ctrl.step = spec.step;
            ctrl.label.Text = spec.name;
            ctrl.value.Text = sprintf(spec.fmt, spec.value);
            moscap.guiHelpers.applySliderStep(ctrl.slider, spec.min, spec.max, spec.step);
        end

        function refreshSliderValueLabels(controls)
        %REFRESHSLIDERVALUELABELS Update all slider value display labels from slider values.

            names = fieldnames(controls);
            for i = 1:numel(names)
                c = controls.(names{i});
                c.value.Text = sprintf(c.fmt, c.slider.Value);
            end
        end

        function applyAllSpecsToControls(controls, spec)
        %APPLYALLSPECSTOCONTROLS Apply all specifications to their respective controls.

            names = fieldnames(controls);
            for i = 1:numel(names)
                name = names{i};
                if isfield(spec, name)
                    moscap.guiHelpers.applySpecToControl(controls.(name), spec.(name));
                end
            end
        end

        function spec = sliderSpecs(params)
        %SLIDERSPECS Generate slider specification struct from parameters.

            spec = struct();

            spec.W = moscap.guiHelpers.makePositiveSpec('W [um]', params.W * 1e6, 100, 1, 2000, '%.1f');
            spec.W.step = 5;
            spec.L = moscap.guiHelpers.makePositiveSpec('L [um]', params.L * 1e6, 100, 1, 2000, '%.1f');
            spec.L.step = 5;
            spec.NF = moscap.guiHelpers.makePositiveSpec('NF [-]', params.NF, 50, 1, 500, '%.0f');
            spec.NF.step = 1;
            spec.tox = moscap.guiHelpers.makePositiveSpec('tox [nm]', params.tox * 1e9, 50, 2, 300, '%.2f');
            spec.tox.step = 0.5;
            [naMin, naMax] = moscap.materialNaBounds(params.material);
            isSiC = strcmpi(strtrim(params.material), '4H-SiC');
            if isSiC
                naRef = max(params.Na_peak / 1e22, 0.1);
                naHardMin = max(naMin / 1e22, 0.01);
                naHardMax = naMax / 1e22;
                spec.NaPeak = moscap.guiHelpers.makePositiveSpec('Na_peak [x1e22 m^-3]', naRef, naRef, naHardMin, naHardMax, '%.3f');
                spec.NaPeak.step = max(0.01, naRef * 0.1);
            else
                spec.NaPeak = moscap.guiHelpers.makePositiveSpec('Na_peak [x1e22 m^-3]', params.Na_peak / 1e22, ...
                    max(5, naMin / 1e22), naMin / 1e22, naMax / 1e22, '%.2f');
                spec.NaPeak.step = 0.1;
            end

            spec.phiMs = moscap.guiHelpers.makeSignedSpec('phi_ms [V]', params.phi_ms, 0.2, -2, 2, '%.2f');
            spec.phiMs.step = 0.01;
            if isSiC
                spec.Qox = moscap.guiHelpers.makeSignedSpec('Qox [x1e11 m^-2]', params.Qox_m2 / 1e11, 10.0, -200, 200, '%.2f');
                spec.Dit = moscap.guiHelpers.makePositiveSpec('Dit [x1e11 cm^-2eV^-1]', params.Dit_cm2eV / 1e11, 10, 0.1, 200, '%.2f');
                spec.tauIt = moscap.guiHelpers.makePositiveSpec('tau_it [us]', params.tau_it * 1e6, 10, 0.01, 1e5, '%.3g');
            else
                spec.Qox = moscap.guiHelpers.makeSignedSpec('Qox [x1e11 m^-2]', params.Qox_m2 / 1e11, 2.0, -50, 50, '%.2f');
                spec.Dit = moscap.guiHelpers.makePositiveSpec('Dit [x1e11 cm^-2eV^-1]', params.Dit_cm2eV / 1e11, 8, 0.05, 100, '%.2f');
                spec.tauIt = moscap.guiHelpers.makePositiveSpec('tau_it [us]', params.tau_it * 1e6, 0.1, 0.005, 1e3, '%.3g');
            end
            spec.Qox.step = 0.5;
            spec.Dit.step = 0.1;
            spec.tauIt.step = 0.05;
            spec.Cbt = moscap.guiHelpers.makePositiveSpec('Cbt [x1e11 cm^-2eV^-1]', params.Cbt_cm2eV / 1e11, 2, 0, 100, '%.2f');
            spec.Cbt.step = 0.1;
            spec.tauBt = moscap.guiHelpers.makePositiveSpec('tau_bt [us]', params.tau_bt * 1e6, 5, 0.01, 1e4, '%.3g');
            spec.tauBt.step = 0.05;
            spec.Cpar = moscap.guiHelpers.makePositiveSpec('Cpar [pF]', params.Cpar_pF, 2, 0, 5e4, '%.2f');
            spec.Cpar.step = 0.5;
            spec.stretch = moscap.guiHelpers.makePositiveSpec('Stretch factor [-]', params.stretch, 1.1, 1, 5, '%.2f');
            spec.stretch.step = 0.01;
            spec.Rs = moscap.guiHelpers.makePositiveSpec('Rs [ohm]', params.Rs, 3e3, 0, 1e6, '%.0f');
            spec.Rs.step = 10;
            spec.freq = moscap.guiHelpers.makePositiveSpec('freq [MHz]', max(params.hfFreqHz, 1) / 1e6, max(params.hfFreqHz, 1) / 1e6, 0.001, 1e4, '%.3g');
            spec.freq.step = max(spec.freq.value * 0.1, 0.001);
            spec.smooth = moscap.guiHelpers.makePositiveSpec('Smooth pts [-]', params.smoothWindow, 5, 1, 41, '%.0f');
            spec.smooth.step = 1;
            spec.tauGen = moscap.guiHelpers.makePositiveSpec('tau_gen [us]', params.tau_gen * 1e6, 5, 0.01, 1e6, '%.3g');
            spec.tauGen.step = 0.1;
        end

        function applySliderStep(sliderObj, minV, maxV, stepV)
        %APPLYSLIDERSTEP Set major ticks and labels based on step size.

            if stepV <= 0 || maxV <= minV
                return;
            end
            ticks = minV:stepV:maxV;
            if numel(ticks) < 2
                ticks = [minV maxV];
            elseif numel(ticks) > 9
                ticks = linspace(minV, maxV, 7);
            end
            sliderObj.MajorTicks = ticks;
            sliderObj.MajorTickLabels = arrayfun(@(x) sprintf('%.3g', x), ticks, 'UniformOutput', false);
        end

        function stepV = estimateSliderStep(sliderObj)
        %ESTIMATESLIDERSTEP Estimate reasonable step size from slider ticks.

            ticks = sliderObj.MajorTicks;
            if numel(ticks) >= 2
                stepV = abs(ticks(2) - ticks(1));
            else
                lims = sliderObj.Limits;
                stepV = max((lims(2) - lims(1)) / 20, eps);
            end
        end

        function out = ternary(cond, a, b)
        %TERNARY Conditional value selection (ternary operator).

            if cond
                out = a;
            else
                out = b;
            end
        end

        function spec = makePositiveSpec(name, value, ref, hardMin, hardMax, fmt)
        %MAKEPOSITIVESPEC Create slider spec for positive parameter.

            base = max(abs(value), ref);
            minV = max(hardMin, 0.2 * base);
            maxV = min(hardMax, 5.0 * base);
            if minV >= maxV
                minV = hardMin;
                maxV = hardMax;
            end

            spec = struct('name', name, 'value', min(max(value, minV), maxV), ...
                'min', minV, 'max', maxV, 'fmt', fmt);
        end

        function spec = makeSignedSpec(name, value, ref, hardMin, hardMax, fmt)
        %MAKESIGNEDSPEC Create slider spec for signed (positive or negative) parameter.

            base = max(abs(value), ref);
            minV = max(hardMin, -3.0 * base);
            maxV = min(hardMax, 3.0 * base);
            if minV >= maxV
                minV = hardMin;
                maxV = hardMax;
            end

            spec = struct('name', name, 'value', min(max(value, minV), maxV), ...
                'min', minV, 'max', maxV, 'fmt', fmt);
        end

    end % methods (Static)
end % classdef












