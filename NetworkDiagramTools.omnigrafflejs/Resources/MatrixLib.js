/*
 * MatrixLib.js - Device Matrix Library
 *
 * Generates grid layouts of network devices arranged in rows and columns.
 * Uses CommonLib for shared constants and utilities.
 */

var _ = function () {
    var MatrixLib = new PlugIn.Library(new Version("0.1"));

    // Accessor for CommonLib (OmniGraffle freezes library objects, so no caching)
    MatrixLib.common = function () {
        return this.plugIn.library('CommonLib');
    };

    // Expose shared constants through accessors for backward compatibility
    Object.defineProperty(MatrixLib, 'SHAPES', {
        get: function () { return this.common().SHAPES; }
    });

    Object.defineProperty(MatrixLib, 'COLOR_PALETTE', {
        get: function () { return this.common().COLOR_PALETTE; }
    });

    Object.defineProperty(MatrixLib, 'TEXT_COLORS', {
        get: function () { return this.common().TEXT_COLORS; }
    });

    // Matrix-specific defaults
    MatrixLib.DEFAULTS = {
        rows: 4,
        cols: 4,
        deviceWidth: 50,
        deviceHeight: 50,
        hSpacing: 50,
        vSpacing: 50,
        shape: 'Rectangle',
        fillColorIndex: 0,
        strokeColorIndex: 0,
        nameTemplate: '{row}-{col}',
        labels: { fontSize: 11, textColorIndex: 0 },
        addBackground: true,
        backgroundMargin: 10
    };

    // Proxy methods to CommonLib for backward compatibility
    MatrixLib.parseHexColor = function (hex) {
        return this.common().parseHexColor(hex);
    };

    MatrixLib.darkenColor = function (rgb) {
        return this.common().darkenColor(rgb);
    };

    MatrixLib.getColorRGB = function (config, key) {
        return this.common().getColorRGB(config, key);
    };

    MatrixLib.getStrokeRGB = function (config, key) {
        return this.common().getStrokeRGB(config, key);
    };

    MatrixLib.createBackground = function (canvas, bounds, margin) {
        return this.common().createBackground(canvas, bounds, margin);
    };

    MatrixLib.calculateBounds = function (graphics) {
        return this.common().calculateBounds(graphics);
    };

    /**
     * Parse naming template for matrix with variable substitution
     * Variables: {row}, {col}, {row0}, {col0}, {index}, {index0}, {total},
     *            {padrow:N}, {padcol:N}, {padindex:N}, {rowalpha}, {colalpha}, {ROWALPHA}, {COLALPHA}
     * @param {string} template - Template string
     * @param {Object} context - Context with row, col, index, total
     * @returns {string} Parsed string
     */
    MatrixLib.parseNameTemplate = function (template, context) {
        if (!template) return '';
        var result = template;

        // Row/col specific
        result = result.replace(/\{row\}/gi, String(context.row));
        result = result.replace(/\{col\}/gi, String(context.col));
        result = result.replace(/\{row0\}/gi, String(context.row - 1));
        result = result.replace(/\{col0\}/gi, String(context.col - 1));

        // Padded versions
        result = result.replace(/\{padrow:(\d+)\}/gi, function (match, digits) {
            var num = String(context.row);
            while (num.length < parseInt(digits, 10)) num = '0' + num;
            return num;
        });
        result = result.replace(/\{padcol:(\d+)\}/gi, function (match, digits) {
            var num = String(context.col);
            while (num.length < parseInt(digits, 10)) num = '0' + num;
            return num;
        });
        result = result.replace(/\{padindex:(\d+)\}/gi, function (match, digits) {
            var num = String(context.index);
            while (num.length < parseInt(digits, 10)) num = '0' + num;
            return num;
        });

        // Alpha versions (uppercase)
        result = result.replace(/\{ROWALPHA\}/g, function () {
            return String.fromCharCode(65 + ((context.row - 1) % 26));
        });
        result = result.replace(/\{COLALPHA\}/g, function () {
            return String.fromCharCode(65 + ((context.col - 1) % 26));
        });

        // Alpha versions (lowercase)
        result = result.replace(/\{rowalpha\}/gi, function () {
            return String.fromCharCode(97 + ((context.row - 1) % 26));
        });
        result = result.replace(/\{colalpha\}/gi, function () {
            return String.fromCharCode(97 + ((context.col - 1) % 26));
        });

        // Sequential index
        result = result.replace(/\{index\}/gi, String(context.index));
        result = result.replace(/\{index0\}/gi, String(context.index - 1));
        result = result.replace(/\{total\}/gi, String(context.total));

        return result;
    };

    /**
     * Calculate device positions for a matrix grid
     * @param {number} rows - Number of rows
     * @param {number} cols - Number of columns
     * @param {number} width - Device width
     * @param {number} height - Device height
     * @param {number} hSpacing - Horizontal spacing
     * @param {number} vSpacing - Vertical spacing
     * @param {Point} topLeft - Top-left corner position
     * @returns {Object[]} Array of position objects with rect, row, col, index
     */
    MatrixLib.calculateMatrixPositions = function (rows, cols, width, height, hSpacing, vSpacing, topLeft) {
        var positions = [];

        for (var row = 0; row < rows; row++) {
            for (var col = 0; col < cols; col++) {
                var x = topLeft.x + col * (width + hSpacing);
                var y = topLeft.y + row * (height + vSpacing);
                positions.push({
                    rect: new Rect(x, y, width, height),
                    row: row + 1,
                    col: col + 1,
                    index: row * cols + col + 1
                });
            }
        }

        return positions;
    };

    /**
     * Create devices for the matrix
     * @param {Canvas} canvas - OmniGraffle canvas
     * @param {Object[]} positions - Array of position objects
     * @param {Object} config - Configuration object
     * @returns {Shape[]} Array of created shapes
     */
    MatrixLib.createDevices = function (canvas, positions, config) {
        var devices = [];
        var common = this.common();
        var fillRGB = common.getColorRGB(config, 'fillColor');
        // For stroke: use hex if provided, otherwise use palette stroke (darkened) color
        var strokeRGB;
        if (config.strokeColorHex) {
            var parsed = common.parseHexColor(config.strokeColorHex);
            strokeRGB = parsed ? parsed : common.getStrokeRGB(config, 'strokeColor');
        } else {
            strokeRGB = common.getStrokeRGB(config, 'strokeColor');
        }
        var textColor = common.TEXT_COLORS[config.labels.textColorIndex];
        var total = positions.length;

        for (var i = 0; i < positions.length; i++) {
            var pos = positions[i];
            var shape = canvas.addShape(config.shape, pos.rect);

            shape.fillColor = Color.RGB(fillRGB[0], fillRGB[1], fillRGB[2], fillRGB[3]);
            shape.strokeColor = Color.RGB(strokeRGB[0], strokeRGB[1], strokeRGB[2], strokeRGB[3]);
            shape.strokeThickness = 1;

            shape.text = this.parseNameTemplate(config.nameTemplate, {
                row: pos.row,
                col: pos.col,
                index: pos.index,
                total: total
            });
            shape.textColor = Color.RGB(textColor.rgb[0], textColor.rgb[1], textColor.rgb[2], textColor.rgb[3]);
            shape.textSize = config.labels.fontSize;

            devices.push(shape);
        }

        return devices;
    };

    /**
     * Generate complete device matrix
     * @param {Canvas} canvas - OmniGraffle canvas
     * @param {Point} viewCenter - Center of the visible view
     * @param {Object} config - Full configuration object
     * @returns {Object} Object with devices, positions, background
     */
    MatrixLib.generateMatrix = function (canvas, viewCenter, config) {
        var common = this.common();

        // Calculate top-left position to center the matrix
        var totalWidth = config.cols * config.deviceWidth + (config.cols - 1) * config.hSpacing;
        var totalHeight = config.rows * config.deviceHeight + (config.rows - 1) * config.vSpacing;

        var topLeft = new Point(
            viewCenter.x - totalWidth / 2,
            viewCenter.y - totalHeight / 2
        );

        var positions = this.calculateMatrixPositions(
            config.rows, config.cols,
            config.deviceWidth, config.deviceHeight,
            config.hSpacing, config.vSpacing,
            topLeft
        );

        var devices = this.createDevices(canvas, positions, config);

        // Create background if enabled
        var background = null;
        if (config.addBackground !== false) {
            var bounds = common.calculateBounds(devices);
            if (bounds) {
                var margin = config.backgroundMargin || 10;
                background = common.createBackground(canvas, bounds, margin);
                // Move background behind all devices
                background.orderBelow(devices[0]);
            }
        }

        return { devices: devices, positions: positions, background: background };
    };

    /**
     * Validate configuration
     * @param {Object} config - Configuration object
     * @returns {Object} Validation result with valid, warnings, errors
     */
    MatrixLib.validateConfig = function (config) {
        var result = { valid: true, warnings: [], errors: [] };

        if (config.rows < 1 || config.rows > 64) {
            result.errors.push('Rows must be between 1 and 64');
            result.valid = false;
        }
        if (config.cols < 1 || config.cols > 64) {
            result.errors.push('Columns must be between 1 and 64');
            result.valid = false;
        }
        if (config.deviceWidth < 20 || config.deviceHeight < 20) {
            result.errors.push('Device dimensions must be at least 20px');
            result.valid = false;
        }

        var totalDevices = config.rows * config.cols;
        if (totalDevices > 500) result.warnings.push('Large matrix (' + totalDevices + ' devices) may impact performance');
        if (totalDevices > 2000) result.warnings.push('Very large matrix - consider reducing dimensions');

        return result;
    };

    return MatrixLib;
}();
_;
