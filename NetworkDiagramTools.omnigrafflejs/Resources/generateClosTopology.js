/*
 * generateClosTopology.js - Clos Topology Generator Action
 */

var _ = function () {
    var action = new PlugIn.Action(function (selection) {
        var lib = this.ClosLib;
        var canvas = selection.canvas;

        // Build main form (simplified)
        var form = new Form();

        var colorNames = lib.COLOR_PALETTE.map(function (c) { return c.name; });
        var colorIndices = [];
        for (var i = 0; i < lib.COLOR_PALETTE.length; i++) colorIndices.push(i);

        // Main settings
        form.addField(new Form.Field.Option('orientation', 'Layout',
            ['vertical', 'horizontal'],
            ['Vertical (A top, B bottom)', 'Horizontal (A left, B right)'],
            'vertical'));

        form.addField(new Form.Field.String('sideACount', 'Side A Count', '4'));
        form.addField(new Form.Field.String('sideAName', 'Side A Name', 'A-{index}'));
        form.addField(new Form.Field.Option('sideAColor', 'Side A Color', colorIndices, colorNames, 0));

        form.addField(new Form.Field.String('sideBCount', 'Side B Count', '4'));
        form.addField(new Form.Field.String('sideBName', 'Side B Name', 'B-{index}'));
        form.addField(new Form.Field.Option('sideBColor', 'Side B Color', colorIndices, colorNames, 1));

        form.addField(new Form.Field.Option('linkStyle', 'Links',
            ['straight', 'curved'], ['Straight', 'Curved'], 'straight'));

        form.addField(new Form.Field.Checkbox('addBackground', 'Add Background', true));
        form.addField(new Form.Field.Checkbox('customize', 'Customize...', false));

        // Validation
        form.validate = function (f) {
            var v = f.values;
            var a = parseInt(v['sideACount'], 10);
            var b = parseInt(v['sideBCount'], 10);
            return !isNaN(a) && a >= 1 && a <= 64 && !isNaN(b) && b >= 1 && b <= 64;
        };

        // Show main form
        form.show('Clos Topology', 'Generate').then(function (result) {
            var v = result.values;

            // Build config with defaults
            var config = {
                orientation: v['orientation'],
                layerSpacing: 150,
                deviceSpacing: 50,
                sideA: {
                    count: parseInt(v['sideACount'], 10),
                    shape: 'Rectangle',
                    width: 50,
                    height: 50,
                    fillColorIndex: v['sideAColor'],
                    strokeColorIndex: v['sideAColor'],
                    nameTemplate: v['sideAName']
                },
                sideB: {
                    count: parseInt(v['sideBCount'], 10),
                    shape: 'Rectangle',
                    width: 50,
                    height: 50,
                    fillColorIndex: v['sideBColor'],
                    strokeColorIndex: v['sideBColor'],
                    nameTemplate: v['sideBName']
                },
                labels: { fontSize: 11, textColorIndex: 0 },
                links: {
                    style: v['linkStyle'],
                    colorIndex: 7,
                    weight: 1.0,
                    pattern: 'Solid'
                },
                addBackground: v['addBackground'],
                backgroundMargin: 10
            };

            if (v['customize']) {
                // Show advanced form
                showAdvancedForm(lib, canvas, config);
            } else {
                // Generate with defaults
                generateTopology(lib, canvas, config);
            }
        }).catch(function () { });
    });

    function showAdvancedForm(lib, canvas, config) {
        var form = new Form();
        var i; // Loop variable for index arrays

        var shapeIndices = [], colorIndices = [], patternIndices = [];
        for (i = 0; i < lib.SHAPES.length; i++) shapeIndices.push(i);
        for (i = 0; i < lib.COLOR_PALETTE.length; i++) colorIndices.push(i);
        for (i = 0; i < lib.LINE_PATTERNS.length; i++) patternIndices.push(i);

        var colorNames = lib.COLOR_PALETTE.map(function (c) { return c.name; });
        var textColorNames = lib.TEXT_COLORS.map(function (c) { return c.name; });
        var textColorIndices = [];
        for (i = 0; i < lib.TEXT_COLORS.length; i++) textColorIndices.push(i);

        // Spacing
        form.addField(new Form.Field.String('layerSpacing', 'Layer Spacing (px)', String(config.layerSpacing)));
        form.addField(new Form.Field.String('deviceSpacing', 'Device Spacing (px)', String(config.deviceSpacing)));

        // Side A
        var sideAShapeIdx = lib.SHAPES.indexOf(config.sideA.shape);
        form.addField(new Form.Field.Option('sideAShape', 'Side A Shape', shapeIndices, lib.SHAPES, sideAShapeIdx >= 0 ? sideAShapeIdx : 0));
        form.addField(new Form.Field.String('sideAWidth', 'Side A Width (px)', String(config.sideA.width)));
        form.addField(new Form.Field.String('sideAHeight', 'Side A Height (px)', String(config.sideA.height)));
        form.addField(new Form.Field.String('sideAColorHex', 'Side A Color Hex', ''));

        // Side B
        var sideBShapeIdx = lib.SHAPES.indexOf(config.sideB.shape);
        form.addField(new Form.Field.Option('sideBShape', 'Side B Shape', shapeIndices, lib.SHAPES, sideBShapeIdx >= 0 ? sideBShapeIdx : 0));
        form.addField(new Form.Field.String('sideBWidth', 'Side B Width (px)', String(config.sideB.width)));
        form.addField(new Form.Field.String('sideBHeight', 'Side B Height (px)', String(config.sideB.height)));
        form.addField(new Form.Field.String('sideBColorHex', 'Side B Color Hex', ''));

        // Labels
        form.addField(new Form.Field.String('fontSize', 'Font Size (pt)', String(config.labels.fontSize)));
        form.addField(new Form.Field.Option('textColor', 'Text Color', textColorIndices, textColorNames, config.labels.textColorIndex));

        // Links
        form.addField(new Form.Field.Option('linkColor', 'Link Color', colorIndices, colorNames, config.links.colorIndex));
        form.addField(new Form.Field.String('linkColorHex', 'Link Color Hex', ''));
        form.addField(new Form.Field.String('linkWeight', 'Link Weight (pt)', String(config.links.weight)));
        form.addField(new Form.Field.Option('linkPattern', 'Link Pattern', patternIndices, lib.LINE_PATTERNS, 0));

        form.validate = function (f) {
            var v = f.values;
            var idx, val, hex;
            var nums = ['layerSpacing', 'deviceSpacing', 'sideAWidth', 'sideAHeight', 'sideBWidth', 'sideBHeight', 'fontSize'];
            for (idx = 0; idx < nums.length; idx++) {
                val = parseInt(v[nums[idx]], 10);
                if (isNaN(val) || val < 10) return false;
            }
            var weight = parseFloat(v['linkWeight']);
            if (isNaN(weight) || weight < 0.1 || weight > 10) return false;
            // Validate hex colors if provided
            var hexFields = ['sideAColorHex', 'sideBColorHex', 'linkColorHex'];
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
            config.layerSpacing = parseInt(v['layerSpacing'], 10);
            config.deviceSpacing = parseInt(v['deviceSpacing'], 10);

            config.sideA.shape = lib.SHAPES[v['sideAShape']];
            config.sideA.width = parseInt(v['sideAWidth'], 10);
            config.sideA.height = parseInt(v['sideAHeight'], 10);
            if (v['sideAColorHex'] && v['sideAColorHex'].length > 0) {
                config.sideA.fillColorHex = v['sideAColorHex'];
                config.sideA.strokeColorHex = v['sideAColorHex'];
            }

            config.sideB.shape = lib.SHAPES[v['sideBShape']];
            config.sideB.width = parseInt(v['sideBWidth'], 10);
            config.sideB.height = parseInt(v['sideBHeight'], 10);
            if (v['sideBColorHex'] && v['sideBColorHex'].length > 0) {
                config.sideB.fillColorHex = v['sideBColorHex'];
                config.sideB.strokeColorHex = v['sideBColorHex'];
            }

            config.labels.fontSize = parseInt(v['fontSize'], 10);
            config.labels.textColorIndex = v['textColor'];

            config.links.colorIndex = v['linkColor'];
            if (v['linkColorHex'] && v['linkColorHex'].length > 0) {
                config.links.colorHex = v['linkColorHex'];
            }
            config.links.weight = parseFloat(v['linkWeight']);
            config.links.pattern = lib.LINE_PATTERNS[v['linkPattern']];

            generateTopology(lib, canvas, config);
        }).catch(function () { });
    }

    function generateTopology(lib, canvas, config) {
        var validation = lib.validateConfig(config);
        if (!validation.valid) {
            new Alert('Error', validation.errors.join('\n')).show();
            return;
        }

        var viewCenter = document.windows[0].centerVisiblePoint;
        var topology = lib.generateTopology(canvas, viewCenter, config);

        var msg = 'Created ' + (topology.sideAGraphics.length + topology.sideBGraphics.length) +
            ' devices and ' + topology.lines.length + ' links';
        if (validation.warnings.length > 0) msg += '\n\n' + validation.warnings.join('\n');

        new Alert('Done', msg).show();
    }

    action.validate = function (selection) {
        return selection.canvas !== null;
    };

    return action;
}();
_;
