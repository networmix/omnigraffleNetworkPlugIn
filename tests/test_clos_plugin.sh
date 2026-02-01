#!/bin/bash
#
# Automated tests for Network Diagram Tools plugin - Clos Topology
# Runs via AppleScript/JavaScript in OmniGraffle
#

set -e

echo "=========================================="
echo "Network Diagram Tools - Clos Topology Tests"
echo "=========================================="
echo ""

# Check if OmniGraffle is running
if ! pgrep -x "OmniGraffle" > /dev/null; then
    echo "Starting OmniGraffle..."
    open -a OmniGraffle
    sleep 3
fi

# Test 1: Plugin Loading
echo "Test 1: Plugin Loading..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"Plugin Loading\", passed: false };
        try {
            var plugin = PlugIn.find(\"com.networmix.NetworkDiagramTools\");
            if (plugin) {
                result.pluginFound = true;
                result.pluginId = plugin.identifier;
                result.version = plugin.version.versionString;

                var lib = plugin.library(\"ClosLib\");
                if (lib) {
                    result.libraryFound = true;
                    result.libraryVersion = lib.version.versionString;
                    result.passed = true;
                } else {
                    result.error = \"Library ClosLib not found\";
                }
            } else {
                result.error = \"Plugin not found\";
            }
        } catch(e) {
            result.error = e.message;
        }
        JSON.stringify(result, null, 2);
    "
    evaluate javascript jsCode
end tell
')
echo "$RESULT"
echo ""

# Test 2: Constants
echo "Test 2: Constants Verification..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"Constants\", checks: {}, passed: false };
        try {
            var lib = PlugIn.find(\"com.networmix.NetworkDiagramTools\").library(\"ClosLib\");

            result.checks.shapesCount = lib.SHAPES.length === 9;
            result.checks.shapesContainsRect = lib.SHAPES.indexOf(\"Rectangle\") >= 0;
            result.checks.colorPaletteCount = lib.COLOR_PALETTE.length === 11;
            result.checks.textColorsCount = lib.TEXT_COLORS.length === 3;
            result.checks.linePatternsCount = lib.LINE_PATTERNS.length === 3;
            result.checks.defaultsExist = lib.DEFAULTS !== undefined;
            result.checks.defaultSideACount = lib.DEFAULTS.sideA.count === 4;
            result.checks.defaultSideBCount = lib.DEFAULTS.sideB.count === 4;

            result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
        } catch(e) {
            result.error = e.message;
        }
        JSON.stringify(result, null, 2);
    "
    evaluate javascript jsCode
end tell
')
echo "$RESULT"
echo ""

# Test 3: Name Template Parser
echo "Test 3: Name Template Parser..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"Name Template Parser\", checks: {}, passed: false };
        try {
            var lib = PlugIn.find(\"com.networmix.NetworkDiagramTools\").library(\"ClosLib\");

            // Test {index}
            var r1 = lib.parseNameTemplate(\"Side_A-{index}\", {index: 1, total: 4, layer: \"A\"});
            result.checks.index1 = r1 === \"Side_A-1\";

            var r2 = lib.parseNameTemplate(\"Node{index}\", {index: 10, total: 20, layer: \"B\"});
            result.checks.index10 = r2 === \"Node10\";

            // Test {index0}
            var r3 = lib.parseNameTemplate(\"SW-{index0}\", {index: 1, total: 4, layer: \"A\"});
            result.checks.index0 = r3 === \"SW-0\";

            // Test {padindex:N}
            var r4 = lib.parseNameTemplate(\"Spine-{padindex:2}\", {index: 1, total: 4, layer: \"A\"});
            result.checks.padindex2_1 = r4 === \"Spine-01\";

            var r5 = lib.parseNameTemplate(\"Leaf-{padindex:3}\", {index: 5, total: 10, layer: \"B\"});
            result.checks.padindex3_5 = r5 === \"Leaf-005\";

            // Test {alpha}
            var r6 = lib.parseNameTemplate(\"Node-{alpha}\", {index: 1, total: 4, layer: \"A\"});
            result.checks.alpha_a = r6 === \"Node-a\";

            var r7 = lib.parseNameTemplate(\"Node-{alpha}\", {index: 3, total: 4, layer: \"A\"});
            result.checks.alpha_c = r7 === \"Node-c\";

            // Test {ALPHA}
            var r8 = lib.parseNameTemplate(\"SW-{ALPHA}\", {index: 1, total: 4, layer: \"A\"});
            result.checks.ALPHA_A = r8 === \"SW-A\";

            var r9 = lib.parseNameTemplate(\"SW-{ALPHA}\", {index: 26, total: 30, layer: \"A\"});
            result.checks.ALPHA_Z = r9 === \"SW-Z\";

            // Test {total}
            var r10 = lib.parseNameTemplate(\"Node {index} of {total}\", {index: 2, total: 8, layer: \"A\"});
            result.checks.total = r10 === \"Node 2 of 8\";

            // Test {layer}
            var r11 = lib.parseNameTemplate(\"Layer_{layer}-{index}\", {index: 3, total: 4, layer: \"A\"});
            result.checks.layer = r11 === \"Layer_A-3\";

            // Test combined
            var r12 = lib.parseNameTemplate(\"{layer}-{ALPHA}{padindex:2}\", {index: 5, total: 10, layer: \"B\"});
            result.checks.combined = r12 === \"B-E05\";

            result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
            result.details = {
                index1: r1,
                index10: r2,
                index0: r3,
                padindex2_1: r4,
                padindex3_5: r5,
                alpha_a: r6,
                alpha_c: r7,
                ALPHA_A: r8,
                ALPHA_Z: r9,
                total: r10,
                layer: r11,
                combined: r12
            };
        } catch(e) {
            result.error = e.message;
            result.stack = e.stack;
        }
        JSON.stringify(result, null, 2);
    "
    evaluate javascript jsCode
end tell
')
echo "$RESULT"
echo ""

# Test 4: Geometry Calculations - Layer Centers
echo "Test 4: Layer Centers Calculation..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"Layer Centers\", checks: {}, passed: false };
        try {
            var lib = PlugIn.find(\"com.networmix.NetworkDiagramTools\").library(\"ClosLib\");

            var viewCenter = new Point(500, 400);
            var spacing = 200;

            // Test vertical orientation
            var vertical = lib.calculateLayerCenters(viewCenter, spacing, \"vertical\");
            result.checks.verticalSideAY = vertical.sideA.y === 300; // 400 - 100
            result.checks.verticalSideBY = vertical.sideB.y === 500; // 400 + 100
            result.checks.verticalSideAX = vertical.sideA.x === 500;
            result.checks.verticalSideBX = vertical.sideB.x === 500;

            // Test horizontal orientation
            var horizontal = lib.calculateLayerCenters(viewCenter, spacing, \"horizontal\");
            result.checks.horizontalSideAX = horizontal.sideA.x === 400; // 500 - 100
            result.checks.horizontalSideBX = horizontal.sideB.x === 600; // 500 + 100
            result.checks.horizontalSideAY = horizontal.sideA.y === 400;
            result.checks.horizontalSideBY = horizontal.sideB.y === 400;

            result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
            result.values = { vertical: vertical, horizontal: horizontal };
        } catch(e) {
            result.error = e.message;
        }
        JSON.stringify(result, null, 2);
    "
    evaluate javascript jsCode
end tell
')
echo "$RESULT"
echo ""

# Test 5: Device Positions Calculation
echo "Test 5: Device Positions Calculation..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"Device Positions\", checks: {}, passed: false };
        try {
            var lib = PlugIn.find(\"com.networmix.NetworkDiagramTools\").library(\"ClosLib\");

            var layerCenter = new Point(500, 300);
            var count = 4;
            var width = 80;
            var height = 50;
            var spacing = 100;

            // Test vertical orientation (devices in horizontal row)
            var positions = lib.calculateDevicePositions(count, width, height, spacing, layerCenter, \"vertical\");

            result.checks.positionCount = positions.length === 4;
            result.checks.allRects = positions.every(function(p) { return p instanceof Rect; });
            result.checks.correctWidth = positions.every(function(p) { return p.width === 80; });
            result.checks.correctHeight = positions.every(function(p) { return p.height === 50; });

            // Total span: 4*80 + 3*100 = 620, half = 310
            // First device x: 500 - 310 = 190
            result.checks.firstDeviceX = Math.abs(positions[0].x - 190) < 1;

            // Y should be centered: 300 - 25 = 275
            result.checks.deviceY = Math.abs(positions[0].y - 275) < 1;

            // Spacing check: second device at 190 + 80 + 100 = 370
            result.checks.secondDeviceX = Math.abs(positions[1].x - 370) < 1;

            // Test single device
            var single = lib.calculateDevicePositions(1, 80, 50, 100, layerCenter, \"vertical\");
            result.checks.singleCount = single.length === 1;
            result.checks.singleCentered = Math.abs(single[0].x - (500 - 40)) < 1;

            // Test empty
            var empty = lib.calculateDevicePositions(0, 80, 50, 100, layerCenter, \"vertical\");
            result.checks.emptyCount = empty.length === 0;

            result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
            result.positions = positions.map(function(p) { return {x: p.x, y: p.y, w: p.width, h: p.height}; });
        } catch(e) {
            result.error = e.message;
            result.stack = e.stack;
        }
        JSON.stringify(result, null, 2);
    "
    evaluate javascript jsCode
end tell
')
echo "$RESULT"
echo ""

# Test 6: Validation
echo "Test 6: Configuration Validation..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"Validation\", checks: {}, passed: false };
        try {
            var lib = PlugIn.find(\"com.networmix.NetworkDiagramTools\").library(\"ClosLib\");

            // Valid config
            var validConfig = {
                sideA: { count: 4, width: 80, height: 50 },
                sideB: { count: 4, width: 80, height: 50 }
            };
            var v1 = lib.validateConfig(validConfig);
            result.checks.validConfigPasses = v1.valid === true;
            result.checks.validConfigNoErrors = v1.errors.length === 0;

            // Invalid count (too low)
            var invalidCount = {
                sideA: { count: 0, width: 80, height: 50 },
                sideB: { count: 4, width: 80, height: 50 }
            };
            var v2 = lib.validateConfig(invalidCount);
            result.checks.zeroCountFails = v2.valid === false;

            // Invalid count (too high)
            var tooHighCount = {
                sideA: { count: 65, width: 80, height: 50 },
                sideB: { count: 4, width: 80, height: 50 }
            };
            var v3 = lib.validateConfig(tooHighCount);
            result.checks.highCountFails = v3.valid === false;

            // Large topology warning
            var largeConfig = {
                sideA: { count: 30, width: 80, height: 50 },
                sideB: { count: 30, width: 80, height: 50 }
            };
            var v4 = lib.validateConfig(largeConfig);
            result.checks.largeTopologyWarns = v4.warnings.length > 0;
            result.checks.largeTopologyValid = v4.valid === true;

            // Small dimensions
            var smallDims = {
                sideA: { count: 4, width: 10, height: 50 },
                sideB: { count: 4, width: 80, height: 50 }
            };
            var v5 = lib.validateConfig(smallDims);
            result.checks.smallDimsFails = v5.valid === false;

            result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
        } catch(e) {
            result.error = e.message;
        }
        JSON.stringify(result, null, 2);
    "
    evaluate javascript jsCode
end tell
')
echo "$RESULT"
echo ""

# Test 7: Full Topology Generation (4x4) - Creates a new document first
echo "Test 7: Full Topology Generation (4x4)..."
RESULT=$(osascript << 'APPLESCRIPT'
tell application "OmniGraffle"
    activate
    delay 0.5

    -- Create a new document
    set newDoc to make new document with properties {name:"Clos Test"}
    delay 1

    set jsCode to "
        var result = { test: 'Topology Generation', checks: {}, passed: false };
        try {
            var lib = PlugIn.find('com.networmix.NetworkDiagramTools').library('ClosLib');

            // Get the canvas - use portfolio to get the first canvas
            var portfolio = document.portfolio;
            var canvas = portfolio.canvases[0];

            if (!canvas) {
                result.error = 'No canvas available in portfolio';
            } else {
                // Count initial graphics
                var initialCount = canvas.graphics.length;

                // Configuration
                var config = {
                    orientation: 'vertical',
                    layerSpacing: 150,
                    deviceSpacing: 100,
                    sideA: {
                        count: 4,
                        shape: 'Rectangle',
                        width: 80,
                        height: 50,
                        fillColorIndex: 0,
                        strokeColorIndex: 0,
                        nameTemplate: 'Side_A-{index}'
                    },
                    sideB: {
                        count: 4,
                        shape: 'Rectangle',
                        width: 80,
                        height: 50,
                        fillColorIndex: 1,
                        strokeColorIndex: 1,
                        nameTemplate: 'Side_B-{index}'
                    },
                    labels: {
                        fontSize: 11,
                        textColorIndex: 0
                    },
                    links: {
                        style: 'straight',
                        colorIndex: 7,
                        weight: 1.0,
                        pattern: 'Solid'
                    }
                };

                var viewCenter = new Point(400, 300);

                // Generate topology
                var topology = lib.generateTopology(canvas, viewCenter, config);

                // Verify results
                result.checks.sideACount = topology.sideAGraphics.length === 4;
                result.checks.sideBCount = topology.sideBGraphics.length === 4;
                result.checks.lineCount = topology.lines.length === 16; // 4x4 full mesh

                // Check shape types
                result.checks.sideAShapes = topology.sideAGraphics.every(function(g) {
                    return g instanceof Shape;
                });
                result.checks.sideBShapes = topology.sideBGraphics.every(function(g) {
                    return g instanceof Shape;
                });
                result.checks.linesAreLines = topology.lines.every(function(l) {
                    return l instanceof Line;
                });

                // Check labels
                result.checks.sideALabels = topology.sideAGraphics[0].text === 'Side_A-1' &&
                                            topology.sideAGraphics[3].text === 'Side_A-4';
                result.checks.sideBLabels = topology.sideBGraphics[0].text === 'Side_B-1' &&
                                            topology.sideBGraphics[3].text === 'Side_B-4';

                // Check canvas graphics count (8 shapes + 16 lines + 1 background)
                var finalCount = canvas.graphics.length;
                result.checks.canvasGraphicsAdded = finalCount === initialCount + 8 + 16 + 1;

                // Check colors (Side A should be blue)
                var sideAFill = topology.sideAGraphics[0].fillColor;
                result.checks.sideAColorBlue = Math.abs(sideAFill.red - 0.29) < 0.1 &&
                                               Math.abs(sideAFill.blue - 0.85) < 0.1;

                // Check colors (Side B should be green)
                var sideBFill = topology.sideBGraphics[0].fillColor;
                result.checks.sideBColorGreen = Math.abs(sideBFill.green - 0.83) < 0.1;

                result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
                result.summary = {
                    sideADevices: topology.sideAGraphics.length,
                    sideBDevices: topology.sideBGraphics.length,
                    links: topology.lines.length,
                    totalGraphics: finalCount
                };
            }
        } catch(e) {
            result.error = e.message;
            result.stack = e.stack;
        }
        JSON.stringify(result, null, 2);
    "
    set testResult to evaluate javascript jsCode
    return testResult
end tell
APPLESCRIPT
)
echo "$RESULT"
echo ""

# Test 8: Horizontal Orientation
echo "Test 8: Horizontal Orientation..."
RESULT=$(osascript << 'APPLESCRIPT'
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: 'Horizontal Orientation', checks: {}, passed: false };
        try {
            var lib = PlugIn.find('com.networmix.NetworkDiagramTools').library('ClosLib');
            var portfolio = document.portfolio;
            var canvas = portfolio.canvases[0];

            if (!canvas) {
                result.error = 'No canvas available';
            } else {
                var config = {
                    orientation: 'horizontal',
                    layerSpacing: 200,
                    deviceSpacing: 80,
                    sideA: { count: 3, shape: 'Rectangle', width: 60, height: 40, fillColorIndex: 2, strokeColorIndex: 2, nameTemplate: 'Left-{index}' },
                    sideB: { count: 3, shape: 'Rectangle', width: 60, height: 40, fillColorIndex: 3, strokeColorIndex: 3, nameTemplate: 'Right-{index}' },
                    labels: { fontSize: 10, textColorIndex: 1 },
                    links: { style: 'curved', colorIndex: 8, weight: 1.5, pattern: 'Dashed' }
                };

                var viewCenter = new Point(400, 500);
                var topology = lib.generateTopology(canvas, viewCenter, config);

                // Side A should be left of Side B (lower X)
                var sideAX = topology.sideAGraphics[0].geometry.center.x;
                var sideBX = topology.sideBGraphics[0].geometry.center.x;
                result.checks.sideALeftOfSideB = sideAX < sideBX;

                // Devices in each layer should be vertically stacked (same X)
                var sideADevice1X = topology.sideAGraphics[0].geometry.center.x;
                var sideADevice2X = topology.sideAGraphics[1].geometry.center.x;
                result.checks.sideAVerticalAlign = Math.abs(sideADevice1X - sideADevice2X) < 1;

                // Lines should be curved
                result.checks.curvedLines = topology.lines[0].lineType === LineType.Curved;

                // Labels
                result.checks.leftLabels = topology.sideAGraphics[0].text === 'Left-1';
                result.checks.rightLabels = topology.sideBGraphics[0].text === 'Right-1';

                // Line count: 3x3 = 9
                result.checks.lineCount = topology.lines.length === 9;

                result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
            }
        } catch(e) {
            result.error = e.message;
            result.stack = e.stack;
        }
        JSON.stringify(result, null, 2);
    "
    evaluate javascript jsCode
end tell
APPLESCRIPT
)
echo "$RESULT"
echo ""

# Test 9: Different Shapes
echo "Test 9: Different Shapes per Layer..."
RESULT=$(osascript << 'APPLESCRIPT'
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: 'Different Shapes', checks: {}, passed: false };
        try {
            var lib = PlugIn.find('com.networmix.NetworkDiagramTools').library('ClosLib');
            var portfolio = document.portfolio;
            var canvas = portfolio.canvases[0];

            if (!canvas) {
                result.error = 'No canvas available';
            } else {
                var config = {
                    orientation: 'vertical',
                    layerSpacing: 150,
                    deviceSpacing: 100,
                    sideA: { count: 2, shape: 'Circle', width: 60, height: 60, fillColorIndex: 4, strokeColorIndex: 4, nameTemplate: 'Circle-{index}' },
                    sideB: { count: 2, shape: 'Diamond', width: 70, height: 70, fillColorIndex: 5, strokeColorIndex: 5, nameTemplate: 'Diamond-{index}' },
                    labels: { fontSize: 10, textColorIndex: 0 },
                    links: { style: 'straight', colorIndex: 7, weight: 1.0, pattern: 'Dotted' }
                };

                var viewCenter = new Point(200, 700);
                var topology = lib.generateTopology(canvas, viewCenter, config);

                // Check that shapes were created (they exist and have correct dimensions)
                result.checks.sideACreated = topology.sideAGraphics.length === 2;
                result.checks.sideBCreated = topology.sideBGraphics.length === 2;

                // Check dimensions
                result.checks.sideAWidth = Math.abs(topology.sideAGraphics[0].geometry.width - 60) < 1;
                result.checks.sideBWidth = Math.abs(topology.sideBGraphics[0].geometry.width - 70) < 1;

                // Check labels
                result.checks.circleLabel = topology.sideAGraphics[0].text === 'Circle-1';
                result.checks.diamondLabel = topology.sideBGraphics[0].text === 'Diamond-1';

                result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
            }
        } catch(e) {
            result.error = e.message;
            result.stack = e.stack;
        }
        JSON.stringify(result, null, 2);
    "
    evaluate javascript jsCode
end tell
APPLESCRIPT
)
echo "$RESULT"
echo ""

# Test 10: Hex Color Support
echo "Test 10: Hex Color Support..."
RESULT=$(osascript << 'APPLESCRIPT'
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: 'Hex Color Support', checks: {}, passed: false };
        try {
            var lib = PlugIn.find('com.networmix.NetworkDiagramTools').library('ClosLib');

            // Test parseHexColor
            var parsed = lib.parseHexColor('#FF5500');
            result.checks.parseHexRed = Math.abs(parsed[0] - 1.0) < 0.01;
            result.checks.parseHexGreen = Math.abs(parsed[1] - 0.333) < 0.01;
            result.checks.parseHexBlue = Math.abs(parsed[2] - 0) < 0.01;
            result.checks.parseHexAlpha = parsed[3] === 1;

            // Test without #
            var parsed2 = lib.parseHexColor('00FF00');
            result.checks.parseHexNoHash = Math.abs(parsed2[1] - 1.0) < 0.01;

            // Test invalid hex
            var invalid = lib.parseHexColor('invalid');
            result.checks.invalidHexReturnsNull = invalid === null;

            // Test darkenColor
            var dark = lib.darkenColor([1.0, 0.5, 0.25, 1]);
            result.checks.darkenRed = Math.abs(dark[0] - 0.65) < 0.01;
            result.checks.darkenGreen = Math.abs(dark[1] - 0.325) < 0.01;

            // Test topology generation with hex colors
            var portfolio = document.portfolio;
            var canvas = portfolio.canvases[0];

            if (canvas) {
                var config = {
                    orientation: 'vertical',
                    layerSpacing: 150,
                    deviceSpacing: 100,
                    sideA: {
                        count: 2, shape: 'Rectangle', width: 80, height: 50,
                        fillColorHex: '#FF0000', strokeColorHex: '#FF0000',
                        nameTemplate: 'HexA-{index}'
                    },
                    sideB: {
                        count: 2, shape: 'Rectangle', width: 80, height: 50,
                        fillColorHex: '#00FF00', strokeColorHex: '#00FF00',
                        nameTemplate: 'HexB-{index}'
                    },
                    labels: { fontSize: 11, textColorIndex: 0 },
                    links: { style: 'straight', colorHex: '#0000FF', weight: 1.0, pattern: 'Solid' }
                };

                var viewCenter = new Point(700, 500);
                var topology = lib.generateTopology(canvas, viewCenter, config);

                // Check Side A is red
                var sideAFill = topology.sideAGraphics[0].fillColor;
                result.checks.hexSideARed = sideAFill.red > 0.9 && sideAFill.green < 0.1 && sideAFill.blue < 0.1;

                // Check Side B is green
                var sideBFill = topology.sideBGraphics[0].fillColor;
                result.checks.hexSideBGreen = sideBFill.red < 0.1 && sideBFill.green > 0.9 && sideBFill.blue < 0.1;

                // Check links are blue
                var linkColor = topology.lines[0].strokeColor;
                result.checks.hexLinkBlue = linkColor.red < 0.1 && linkColor.green < 0.1 && linkColor.blue > 0.9;
            }

            result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
        } catch(e) {
            result.error = e.message;
            result.stack = e.stack;
        }
        JSON.stringify(result, null, 2);
    "
    evaluate javascript jsCode
end tell
APPLESCRIPT
)
echo "$RESULT"
echo ""

# Test 11: Emoji Color Names
echo "Test 11: Emoji Color Names in Palette..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"Emoji Color Names\", checks: {}, passed: false };
        try {
            var lib = PlugIn.find(\"com.networmix.NetworkDiagramTools\").library(\"ClosLib\");

            // Check that color names include emoji
            result.checks.blueHasEmoji = lib.COLOR_PALETTE[0].name.indexOf(\"🟦\") >= 0;
            result.checks.greenHasEmoji = lib.COLOR_PALETTE[1].name.indexOf(\"🟩\") >= 0;
            result.checks.redHasEmoji = lib.COLOR_PALETTE[2].name.indexOf(\"🟥\") >= 0;
            result.checks.orangeHasEmoji = lib.COLOR_PALETTE[3].name.indexOf(\"🟧\") >= 0;
            result.checks.purpleHasEmoji = lib.COLOR_PALETTE[4].name.indexOf(\"🟪\") >= 0;
            result.checks.yellowHasEmoji = lib.COLOR_PALETTE[6].name.indexOf(\"🟨\") >= 0;
            result.checks.blackHasEmoji = lib.COLOR_PALETTE[10].name.indexOf(\"⬛\") >= 0;

            // Check that color palette has hex values
            result.checks.blueHasHex = lib.COLOR_PALETTE[0].hex === \"#4A8FD9\";
            result.checks.redHasHex = lib.COLOR_PALETTE[2].hex === \"#D1031C\";

            // Check text colors have emoji
            result.checks.textWhiteEmoji = lib.TEXT_COLORS[0].name.indexOf(\"⬜\") >= 0;
            result.checks.textBlackEmoji = lib.TEXT_COLORS[1].name.indexOf(\"⬛\") >= 0;

            result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
        } catch(e) {
            result.error = e.message;
        }
        JSON.stringify(result, null, 2);
    "
    evaluate javascript jsCode
end tell
')
echo "$RESULT"
echo ""

echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""
echo "All tests completed. Review output above for PASSED/FAILED status."
echo ""
