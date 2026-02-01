/*
 * generateDeviceMatrix.js - Device Matrix Generator Action
 */

var _ = function () {
    var action = new PlugIn.Action(function (selection) {
        var lib = this.MatrixLib;
        var canvas = selection.canvas;

        // Build main form
        var form = new Form();

        var colorNames = lib.COLOR_PALETTE.map(function (c) { return c.name; });
        var colorIndices = [];
        for (var i = 0; i < lib.COLOR_PALETTE.length; i++) colorIndices.push(i);

        // Main settings
        form.addField(new Form.Field.String('rows', 'Rows', '4'));
        form.addField(new Form.Field.String('cols', 'Columns', '4'));
        form.addField(new Form.Field.String('nameTemplate', 'Name Template', '{row}-{col}'));
        form.addField(new Form.Field.Option('fillColor', 'Fill Color', colorIndices, colorNames, 0));
        form.addField(new Form.Field.Option('strokeColor', 'Stroke Color', colorIndices, colorNames, 0));

        form.addField(new Form.Field.Checkbox('addBackground', 'Add Background', true));
        form.addField(new Form.Field.Checkbox('customize', 'Customize...', false));

        // Validation
        form.validate = function (f) {
            var v = f.values;
            var rows = parseInt(v['rows'], 10);
            var cols = parseInt(v['cols'], 10);
            return !isNaN(rows) && rows >= 1 && rows <= 64 &&
                !isNaN(cols) && cols >= 1 && cols <= 64;
        };

        // Show main form
        form.show('Device Matrix', 'Generate').then(function (result) {
            var v = result.values;

            // Build config with defaults
            var config = {
                rows: parseInt(v['rows'], 10),
                cols: parseInt(v['cols'], 10),
                deviceWidth: 50,
                deviceHeight: 50,
                hSpacing: 50,
                vSpacing: 50,
                shape: 'Rectangle',
                fillColorIndex: v['fillColor'],
                strokeColorIndex: v['strokeColor'],
                nameTemplate: v['nameTemplate'],
                labels: { fontSize: 11, textColorIndex: 0 },
                addBackground: v['addBackground'],
                backgroundMargin: 10
            };

            if (v['customize']) {
                showAdvancedForm(lib, canvas, config);
            } else {
                generateMatrix(lib, canvas, config);
            }
        }).catch(function () { });
    });

    function showAdvancedForm(lib, canvas, config) {
        var form = new Form();
        var i; // Loop variable for index arrays

        var shapeIndices = [], colorIndices = [];
        for (i = 0; i < lib.SHAPES.length; i++) shapeIndices.push(i);
        for (i = 0; i < lib.COLOR_PALETTE.length; i++) colorIndices.push(i);

        var textColorNames = lib.TEXT_COLORS.map(function (c) { return c.name; });
        var textColorIndices = [];
        for (i = 0; i < lib.TEXT_COLORS.length; i++) textColorIndices.push(i);

        // Device settings
        var shapeIdx = lib.SHAPES.indexOf(config.shape);
        form.addField(new Form.Field.Option('shape', 'Shape', shapeIndices, lib.SHAPES, shapeIdx >= 0 ? shapeIdx : 0));
        form.addField(new Form.Field.String('deviceWidth', 'Device Width (px)', String(config.deviceWidth)));
        form.addField(new Form.Field.String('deviceHeight', 'Device Height (px)', String(config.deviceHeight)));
        form.addField(new Form.Field.String('fillColorHex', 'Fill Color Hex', ''));
        form.addField(new Form.Field.String('strokeColorHex', 'Stroke Color Hex', ''));

        // Spacing
        form.addField(new Form.Field.String('hSpacing', 'Horizontal Spacing (px)', String(config.hSpacing)));
        form.addField(new Form.Field.String('vSpacing', 'Vertical Spacing (px)', String(config.vSpacing)));

        // Labels
        form.addField(new Form.Field.String('fontSize', 'Font Size (pt)', String(config.labels.fontSize)));
        form.addField(new Form.Field.Option('textColor', 'Text Color', textColorIndices, textColorNames, config.labels.textColorIndex));

        form.validate = function (f) {
            var v = f.values;
            var idx, val, hex;
            var nums = ['deviceWidth', 'deviceHeight', 'hSpacing', 'vSpacing', 'fontSize'];
            for (idx = 0; idx < nums.length; idx++) {
                val = parseInt(v[nums[idx]], 10);
                if (isNaN(val) || val < 10) return false;
            }
            // Validate hex colors if provided
            var hexFields = ['fillColorHex', 'strokeColorHex'];
            for (idx = 0; idx < hexFields.length; idx++) {
                hex = v[hexFields[idx]];
                if (hex && hex.length > 0) {
                    hex = hex.replace(/^#/, '');
                    if (!/^[0-9A-Fa-f]{6}$/.test(hex)) return false;
                }
            }
            return true;
        };

        form.show('Advanced Options', 'Generate').then(function (result) {
            var v = result.values;

            // Update config with advanced settings
            config.shape = lib.SHAPES[v['shape']];
            config.deviceWidth = parseInt(v['deviceWidth'], 10);
            config.deviceHeight = parseInt(v['deviceHeight'], 10);

            if (v['fillColorHex'] && v['fillColorHex'].length > 0) {
                config.fillColorHex = v['fillColorHex'];
            }
            if (v['strokeColorHex'] && v['strokeColorHex'].length > 0) {
                config.strokeColorHex = v['strokeColorHex'];
            }

            config.hSpacing = parseInt(v['hSpacing'], 10);
            config.vSpacing = parseInt(v['vSpacing'], 10);

            config.labels.fontSize = parseInt(v['fontSize'], 10);
            config.labels.textColorIndex = v['textColor'];

            generateMatrix(lib, canvas, config);
        }).catch(function () { });
    }

    function generateMatrix(lib, canvas, config) {
        var validation = lib.validateConfig(config);
        if (!validation.valid) {
            new Alert('Error', validation.errors.join('\n')).show();
            return;
        }

        var viewCenter = document.windows[0].centerVisiblePoint;
        var result = lib.generateMatrix(canvas, viewCenter, config);

        var msg = 'Created ' + result.devices.length + ' devices (' +
            config.rows + ' rows × ' + config.cols + ' columns)';
        if (validation.warnings.length > 0) msg += '\n\n' + validation.warnings.join('\n');

        new Alert('Done', msg).show();
    }

    action.validate = function (selection) {
        return selection.canvas !== null;
    };

    return action;
}();
_;
