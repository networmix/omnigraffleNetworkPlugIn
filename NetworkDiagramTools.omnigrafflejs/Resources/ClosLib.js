/*
 * ClosLib.js - Clos Topology Library
 *
 * Generates two-layer Clos (spine-leaf) network topologies with full-mesh connectivity.
 * Uses CommonLib for shared constants and utilities.
 */

var _ = function () {
    var ClosLib = new PlugIn.Library(new Version("0.1"));

    // Accessor for CommonLib (OmniGraffle freezes library objects, so no caching)
    ClosLib.common = function () {
        return this.plugIn.library('CommonLib');
    };

    // Expose shared constants through accessors for backward compatibility
    Object.defineProperty(ClosLib, 'SHAPES', {
        get: function () { return this.common().SHAPES; }
    });

    Object.defineProperty(ClosLib, 'COLOR_PALETTE', {
        get: function () { return this.common().COLOR_PALETTE; }
    });

    Object.defineProperty(ClosLib, 'TEXT_COLORS', {
        get: function () { return this.common().TEXT_COLORS; }
    });

    // Clos-specific constants
    ClosLib.LINE_PATTERNS = ['Solid', 'Dashed', 'Dotted'];

    ClosLib.DEFAULTS = {
        orientation: 'vertical',
        layerSpacing: 150,
        deviceSpacing: 50,
        sideA: {
            count: 4, shape: 'Rectangle', width: 50, height: 50,
            fillColorIndex: 0, strokeColorIndex: 0, nameTemplate: 'A-{index}'
        },
        sideB: {
            count: 4, shape: 'Rectangle', width: 50, height: 50,
            fillColorIndex: 0, strokeColorIndex: 0, nameTemplate: 'B-{index}'
        },
        labels: { fontSize: 11, textColorIndex: 0 },
        links: { style: 'straight', colorIndex: 7, weight: 1.0, pattern: 'Solid' },
        addBackground: true,
        backgroundMargin: 10
    };

    // Proxy methods to CommonLib for backward compatibility
    ClosLib.parseHexColor = function (hex) {
        return this.common().parseHexColor(hex);
    };

    ClosLib.darkenColor = function (rgb) {
        return this.common().darkenColor(rgb);
    };

    ClosLib.getColorRGB = function (config, key) {
        return this.common().getColorRGB(config, key);
    };

    ClosLib.getStrokeRGB = function (config, key) {
        return this.common().getStrokeRGB(config, key);
    };

    ClosLib.createBackground = function (canvas, bounds, margin) {
        return this.common().createBackground(canvas, bounds, margin);
    };

    ClosLib.calculateBounds = function (graphics) {
        return this.common().calculateBounds(graphics);
    };

    /**
     * Parse naming template with variable substitution
     * Variables: {index}, {index0}, {padindex:N}, {alpha}, {ALPHA}, {total}, {layer}
     * @param {string} template - Template string
     * @param {Object} context - Context with index, total, layer
     * @returns {string} Parsed string
     */
    ClosLib.parseNameTemplate = function (template, context) {
        if (!template) return '';
        var result = template;
        result = result.replace(/\{index\}/gi, String(context.index));
        result = result.replace(/\{index0\}/gi, String(context.index - 1));
        result = result.replace(/\{padindex:(\d+)\}/gi, function (match, digits) {
            var num = String(context.index);
            while (num.length < parseInt(digits, 10)) num = '0' + num;
            return num;
        });
        // {ALPHA} must be processed before {alpha} (case-sensitive vs case-insensitive)
        result = result.replace(/\{ALPHA\}/g, function () {
            return String.fromCharCode(65 + ((context.index - 1) % 26));
        });
        result = result.replace(/\{alpha\}/gi, function () {
            return String.fromCharCode(97 + ((context.index - 1) % 26));
        });
        result = result.replace(/\{total\}/gi, String(context.total));
        result = result.replace(/\{layer\}/gi, context.layer);
        return result;
    };

    /**
     * Calculate layer center points for vertical or horizontal layout
     * @param {Point} viewCenter - Center of the visible view
     * @param {number} layerSpacing - Distance between layers
     * @param {string} orientation - 'vertical' or 'horizontal'
     * @returns {Object} Object with sideA and sideB center points
     */
    ClosLib.calculateLayerCenters = function (viewCenter, layerSpacing, orientation) {
        var half = layerSpacing / 2;
        if (orientation === 'vertical') {
            return {
                sideA: new Point(viewCenter.x, viewCenter.y - half),
                sideB: new Point(viewCenter.x, viewCenter.y + half)
            };
        } else {
            return {
                sideA: new Point(viewCenter.x - half, viewCenter.y),
                sideB: new Point(viewCenter.x + half, viewCenter.y)
            };
        }
    };

    /**
     * Calculate device positions within a layer
     * @param {number} count - Number of devices
     * @param {number} width - Device width
     * @param {number} height - Device height
     * @param {number} spacing - Spacing between devices
     * @param {Point} layerCenter - Center point of the layer
     * @param {string} orientation - 'vertical' or 'horizontal'
     * @returns {Rect[]} Array of device rectangles
     */
    ClosLib.calculateDevicePositions = function (count, width, height, spacing, layerCenter, orientation) {
        if (count === 0) return [];

        var positions = [];
        var totalSpan = (orientation === 'vertical')
            ? (count * width) + ((count - 1) * spacing)
            : (count * height) + ((count - 1) * spacing);
        var startOffset = -totalSpan / 2;

        for (var i = 0; i < count; i++) {
            var x, y;
            if (orientation === 'vertical') {
                x = layerCenter.x + startOffset + (i * (width + spacing));
                y = layerCenter.y - (height / 2);
            } else {
                x = layerCenter.x - (width / 2);
                y = layerCenter.y + startOffset + (i * (height + spacing));
            }
            positions.push(new Rect(x, y, width, height));
        }
        return positions;
    };

    /**
     * Create devices for a layer
     * @param {Canvas} canvas - OmniGraffle canvas
     * @param {Rect[]} positions - Array of device rectangles
     * @param {Object} sideConfig - Configuration for this side
     * @param {Object} labelConfig - Label configuration
     * @param {string} layerId - Layer identifier (A or B)
     * @returns {Shape[]} Array of created shapes
     */
    ClosLib.createDevices = function (canvas, positions, sideConfig, labelConfig, layerId) {
        var devices = [];
        var common = this.common();
        var fillRGB = common.getColorRGB(sideConfig, 'fillColor');
        var strokeRGB = common.getStrokeRGB(sideConfig, 'strokeColor');
        var textColor = common.TEXT_COLORS[labelConfig.textColorIndex];

        for (var i = 0; i < positions.length; i++) {
            var shape = canvas.addShape(sideConfig.shape, positions[i]);

            shape.fillColor = Color.RGB(fillRGB[0], fillRGB[1], fillRGB[2], fillRGB[3]);
            shape.strokeColor = Color.RGB(strokeRGB[0], strokeRGB[1], strokeRGB[2], strokeRGB[3]);
            shape.strokeThickness = 1;

            shape.text = this.parseNameTemplate(sideConfig.nameTemplate, {
                index: i + 1, total: positions.length, layer: layerId
            });
            shape.textColor = Color.RGB(textColor.rgb[0], textColor.rgb[1], textColor.rgb[2], textColor.rgb[3]);
            shape.textSize = labelConfig.fontSize;

            devices.push(shape);
        }
        return devices;
    };

    /**
     * Create full mesh connections between two device sets
     * @param {Canvas} canvas - OmniGraffle canvas
     * @param {Shape[]} sideA - Side A devices
     * @param {Shape[]} sideB - Side B devices
     * @param {Object} linkConfig - Link configuration
     * @returns {Line[]} Array of created lines
     */
    ClosLib.createFullMeshConnections = function (canvas, sideA, sideB, linkConfig) {
        var lines = [];
        var common = this.common();
        var linkRGB = common.getColorRGB(linkConfig, 'color');

        for (var i = 0; i < sideA.length; i++) {
            for (var j = 0; j < sideB.length; j++) {
                var line = canvas.connect(sideA[i], sideB[j]);
                line.lineType = (linkConfig.style === 'curved') ? LineType.Curved : LineType.Straight;
                line.strokeColor = Color.RGB(linkRGB[0], linkRGB[1], linkRGB[2], linkRGB[3]);
                line.strokeThickness = linkConfig.weight;

                if (linkConfig.pattern === 'Dashed') line.strokePattern = StrokeDash.all[1];
                else if (linkConfig.pattern === 'Dotted') line.strokePattern = StrokeDash.all[4];

                lines.push(line);
            }
        }
        return lines;
    };

    /**
     * Generate complete Clos topology
     * @param {Canvas} canvas - OmniGraffle canvas
     * @param {Point} viewCenter - Center of the visible view
     * @param {Object} config - Full configuration object
     * @returns {Object} Object with sideAGraphics, sideBGraphics, lines, background
     */
    ClosLib.generateTopology = function (canvas, viewCenter, config) {
        var common = this.common();
        var layerCenters = this.calculateLayerCenters(viewCenter, config.layerSpacing, config.orientation);

        var sideAPositions = this.calculateDevicePositions(
            config.sideA.count, config.sideA.width, config.sideA.height,
            config.deviceSpacing, layerCenters.sideA, config.orientation
        );
        var sideBPositions = this.calculateDevicePositions(
            config.sideB.count, config.sideB.width, config.sideB.height,
            config.deviceSpacing, layerCenters.sideB, config.orientation
        );

        var sideAGraphics = this.createDevices(canvas, sideAPositions, config.sideA, config.labels, 'A');
        var sideBGraphics = this.createDevices(canvas, sideBPositions, config.sideB, config.labels, 'B');
        var lines = this.createFullMeshConnections(canvas, sideAGraphics, sideBGraphics, config.links);

        // Create background if enabled
        var background = null;
        if (config.addBackground !== false) {
            var allGraphics = sideAGraphics.concat(sideBGraphics);
            var bounds = common.calculateBounds(allGraphics);
            if (bounds) {
                var margin = config.backgroundMargin || 10;
                background = common.createBackground(canvas, bounds, margin);
                // Move background behind everything
                background.orderBelow(lines.length > 0 ? lines[0] : sideAGraphics[0]);
            }
        }

        // Move shapes above lines
        if (lines.length > 0) {
            var topLine = lines[lines.length - 1];
            for (var i = 0; i < sideAGraphics.length; i++) sideAGraphics[i].orderAbove(topLine);
            for (var j = 0; j < sideBGraphics.length; j++) sideBGraphics[j].orderAbove(topLine);
        }

        return { sideAGraphics: sideAGraphics, sideBGraphics: sideBGraphics, lines: lines, background: background };
    };

    /**
     * Validate configuration
     * @param {Object} config - Configuration object
     * @returns {Object} Validation result with valid, warnings, errors
     */
    ClosLib.validateConfig = function (config) {
        var result = { valid: true, warnings: [], errors: [] };

        if (config.sideA.count < 1 || config.sideA.count > 64) {
            result.errors.push('Side A count must be between 1 and 64');
            result.valid = false;
        }
        if (config.sideB.count < 1 || config.sideB.count > 64) {
            result.errors.push('Side B count must be between 1 and 64');
            result.valid = false;
        }
        if (config.sideA.width < 20 || config.sideA.height < 20) {
            result.errors.push('Side A dimensions must be at least 20px');
            result.valid = false;
        }
        if (config.sideB.width < 20 || config.sideB.height < 20) {
            result.errors.push('Side B dimensions must be at least 20px');
            result.valid = false;
        }

        var totalLinks = config.sideA.count * config.sideB.count;
        if (totalLinks > 500) result.warnings.push('Large topology (' + totalLinks + ' links) may impact performance');
        if (totalLinks > 2000) result.warnings.push('Very large topology - consider reducing device counts');

        return result;
    };

    return ClosLib;
}();
_;
