/*
 * CommonLib.js - Shared Constants and Utilities
 *
 * Common functionality shared between ClosLib and MatrixLib.
 */

var _ = function () {
    var CommonLib = new PlugIn.Library(new Version("0.1"));

    // Available shapes for network devices
    CommonLib.SHAPES = [
        'Rectangle', 'RoundedRectangle', 'Circle', 'Diamond',
        'Hexagon', 'Parallelogram', 'Cloud', 'Horizontal Cylinder', 'Vertical Cylinder'
    ];

    // Color palette with fill, stroke, and hex values
    CommonLib.COLOR_PALETTE = [
        { name: '🟦 Blue', rgb: [0.29, 0.56, 0.85, 1], stroke: [0.18, 0.35, 0.53, 1], hex: '#4A8FD9' },
        { name: '🟩 Green', rgb: [0.49, 0.83, 0.13, 1], stroke: [0.29, 0.51, 0.08, 1], hex: '#7DD421' },
        { name: '🟥 Red', rgb: [0.82, 0.01, 0.11, 1], stroke: [0.55, 0.01, 0.07, 1], hex: '#D1031C' },
        { name: '🟧 Orange', rgb: [0.96, 0.65, 0.14, 1], stroke: [0.70, 0.47, 0.10, 1], hex: '#F5A624' },
        { name: '🟪 Purple', rgb: [0.56, 0.07, 1.00, 1], stroke: [0.35, 0.04, 0.65, 1], hex: '#8F12FF' },
        { name: '🩵 Teal', rgb: [0.31, 0.89, 0.76, 1], stroke: [0.19, 0.55, 0.47, 1], hex: '#4FE3C2' },
        { name: '🟨 Yellow', rgb: [0.95, 0.85, 0.20, 1], stroke: [0.70, 0.63, 0.15, 1], hex: '#F2D933' },
        { name: '⬜ Gray', rgb: [0.61, 0.61, 0.61, 1], stroke: [0.40, 0.40, 0.40, 1], hex: '#9C9C9C' },
        { name: '🔲 Dark Gray', rgb: [0.33, 0.33, 0.33, 1], stroke: [0.20, 0.20, 0.20, 1], hex: '#545454' },
        { name: '⬜ White', rgb: [1.00, 1.00, 1.00, 1], stroke: [0.70, 0.70, 0.70, 1], hex: '#FFFFFF' },
        { name: '⬛ Black', rgb: [0.00, 0.00, 0.00, 1], stroke: [0.00, 0.00, 0.00, 1], hex: '#000000' }
    ];

    // Text color options
    CommonLib.TEXT_COLORS = [
        { name: '⬜ White', rgb: [1.00, 1.00, 1.00, 1] },
        { name: '⬛ Black', rgb: [0.00, 0.00, 0.00, 1] },
        { name: '🔲 Dark Gray', rgb: [0.20, 0.20, 0.20, 1] }
    ];

    /**
     * Parse hex color string to RGB array [r, g, b, a] (values 0-1)
     * @param {string} hex - Hex color string (with or without #)
     * @returns {number[]|null} RGB array or null if invalid
     */
    CommonLib.parseHexColor = function (hex) {
        if (!hex || typeof hex !== 'string') return null;
        hex = hex.replace(/^#/, '');
        if (!/^[0-9A-Fa-f]{6}$/.test(hex)) return null;
        var r = parseInt(hex.substring(0, 2), 16) / 255;
        var g = parseInt(hex.substring(2, 4), 16) / 255;
        var b = parseInt(hex.substring(4, 6), 16) / 255;
        return [r, g, b, 1];
    };

    /**
     * Create darker stroke color from fill color (65% brightness)
     * @param {number[]} rgb - RGB array [r, g, b, a]
     * @returns {number[]} Darkened RGB array
     */
    CommonLib.darkenColor = function (rgb) {
        return [rgb[0] * 0.65, rgb[1] * 0.65, rgb[2] * 0.65, rgb[3]];
    };

    /**
     * Get color RGB array from config (supports palette index or custom hex)
     * @param {Object} config - Configuration object
     * @param {string} key - Base key name (e.g., 'fillColor' looks for 'fillColorHex' and 'fillColorIndex')
     * @returns {number[]} RGB array
     */
    CommonLib.getColorRGB = function (config, key) {
        var hexKey = key + 'Hex';
        if (config[hexKey]) {
            var parsed = this.parseHexColor(config[hexKey]);
            if (parsed) return parsed;
        }
        var idx = config[key + 'Index'];
        if (idx !== undefined && this.COLOR_PALETTE[idx]) {
            return this.COLOR_PALETTE[idx].rgb;
        }
        return this.COLOR_PALETTE[0].rgb;
    };

    /**
     * Get stroke color RGB (darker version of fill or from palette)
     * @param {Object} config - Configuration object
     * @param {string} key - Base key name
     * @returns {number[]} RGB array for stroke
     */
    CommonLib.getStrokeRGB = function (config, key) {
        var hexKey = key + 'Hex';
        if (config[hexKey]) {
            var parsed = this.parseHexColor(config[hexKey]);
            if (parsed) return this.darkenColor(parsed);
        }
        var idx = config[key + 'Index'];
        if (idx !== undefined && this.COLOR_PALETTE[idx]) {
            return this.COLOR_PALETTE[idx].stroke;
        }
        return this.COLOR_PALETTE[0].stroke;
    };

    /**
     * Create background rectangle behind graphics
     * @param {Canvas} canvas - OmniGraffle canvas
     * @param {Rect} bounds - Bounding rectangle of content
     * @param {number} margin - Margin around content
     * @returns {Shape} Background shape
     */
    CommonLib.createBackground = function (canvas, bounds, margin) {
        var bgRect = new Rect(
            bounds.x - margin,
            bounds.y - margin,
            bounds.width + margin * 2,
            bounds.height + margin * 2
        );
        var bg = canvas.addShape('Rectangle', bgRect);
        bg.fillColor = Color.white;
        bg.strokeColor = Color.RGB(0.8, 0.8, 0.8, 1);
        bg.strokeThickness = 1;
        return bg;
    };

    /**
     * Calculate bounding box for an array of graphics
     * @param {Graphic[]} graphics - Array of graphics
     * @returns {Rect|null} Bounding rectangle or null if empty
     */
    CommonLib.calculateBounds = function (graphics) {
        if (graphics.length === 0) return null;

        var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (var i = 0; i < graphics.length; i++) {
            var g = graphics[i].geometry;
            if (g.x < minX) minX = g.x;
            if (g.y < minY) minY = g.y;
            if (g.x + g.width > maxX) maxX = g.x + g.width;
            if (g.y + g.height > maxY) maxY = g.y + g.height;
        }
        return new Rect(minX, minY, maxX - minX, maxY - minY);
    };

    return CommonLib;
}();
_;
