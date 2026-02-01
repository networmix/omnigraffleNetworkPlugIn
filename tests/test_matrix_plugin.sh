#!/bin/bash
#
# Automated tests for Network Diagram Tools plugin - Device Matrix
# Runs via AppleScript/JavaScript in OmniGraffle
#

set -e

echo "=========================================="
echo "Network Diagram Tools - Device Matrix Tests"
echo "=========================================="
echo ""

# Check if OmniGraffle is running
if ! pgrep -x "OmniGraffle" > /dev/null; then
    echo "Starting OmniGraffle..."
    open -a OmniGraffle
    sleep 3
fi

# Test 1: Plugin and MatrixLib Loading
echo "Test 1: Plugin and MatrixLib Loading..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"MatrixLib Loading\", passed: false };
        try {
            var plugin = PlugIn.find(\"com.networmix.NetworkDiagramTools\");
            if (plugin) {
                result.pluginFound = true;
                result.pluginId = plugin.identifier;
                result.version = plugin.version.versionString;

                var matrixLib = plugin.library(\"MatrixLib\");
                var commonLib = plugin.library(\"CommonLib\");

                if (matrixLib && commonLib) {
                    result.matrixLibFound = true;
                    result.commonLibFound = true;
                    result.matrixLibVersion = matrixLib.version.versionString;
                    result.commonLibVersion = commonLib.version.versionString;
                    result.passed = true;
                } else {
                    result.error = \"Libraries not found: MatrixLib=\" + !!matrixLib + \", CommonLib=\" + !!commonLib;
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

# Test 2: Constants from CommonLib
echo "Test 2: Constants from CommonLib..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"CommonLib Constants\", checks: {}, passed: false };
        try {
            var plugin = PlugIn.find(\"com.networmix.NetworkDiagramTools\");
            var lib = plugin.library(\"MatrixLib\");

            // Access constants through MatrixLib (which proxies to CommonLib)
            result.checks.shapesCount = lib.SHAPES.length === 9;
            result.checks.shapesContainsRect = lib.SHAPES.indexOf(\"Rectangle\") >= 0;
            result.checks.colorPaletteCount = lib.COLOR_PALETTE.length === 11;
            result.checks.textColorsCount = lib.TEXT_COLORS.length === 3;
            result.checks.defaultsExist = lib.DEFAULTS !== undefined;
            result.checks.defaultRows = lib.DEFAULTS.rows === 4;
            result.checks.defaultCols = lib.DEFAULTS.cols === 4;

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

# Test 3: Matrix Name Template Parser
echo "Test 3: Matrix Name Template Parser..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"Matrix Name Template Parser\", checks: {}, passed: false };
        try {
            var lib = PlugIn.find(\"com.networmix.NetworkDiagramTools\").library(\"MatrixLib\");

            // Test {row} and {col}
            var r1 = lib.parseNameTemplate(\"{row}-{col}\", {row: 2, col: 3, index: 7, total: 16});
            result.checks.rowCol = r1 === \"2-3\";

            // Test {row0} and {col0} (0-based)
            var r2 = lib.parseNameTemplate(\"R{row0}C{col0}\", {row: 1, col: 1, index: 1, total: 16});
            result.checks.rowCol0 = r2 === \"R0C0\";

            // Test {padrow:N} and {padcol:N}
            var r3 = lib.parseNameTemplate(\"{padrow:2}-{padcol:2}\", {row: 1, col: 5, index: 5, total: 16});
            result.checks.padRowCol = r3 === \"01-05\";

            // Test {ROWALPHA} and {COLALPHA}
            var r4 = lib.parseNameTemplate(\"{ROWALPHA}{COLALPHA}\", {row: 1, col: 2, index: 2, total: 16});
            result.checks.alphaUpper = r4 === \"AB\";

            // Test {rowalpha} and {colalpha}
            var r5 = lib.parseNameTemplate(\"{rowalpha}{colalpha}\", {row: 3, col: 4, index: 12, total: 16});
            result.checks.alphaLower = r5 === \"cd\";

            // Test {index} and {index0}
            var r6 = lib.parseNameTemplate(\"Device-{index}\", {row: 2, col: 3, index: 7, total: 16});
            result.checks.index = r6 === \"Device-7\";

            var r7 = lib.parseNameTemplate(\"D{index0}\", {row: 1, col: 1, index: 1, total: 16});
            result.checks.index0 = r7 === \"D0\";

            // Test {padindex:N}
            var r8 = lib.parseNameTemplate(\"Node-{padindex:3}\", {row: 2, col: 2, index: 6, total: 16});
            result.checks.padIndex = r8 === \"Node-006\";

            // Test {total}
            var r9 = lib.parseNameTemplate(\"{index} of {total}\", {row: 3, col: 4, index: 12, total: 16});
            result.checks.total = r9 === \"12 of 16\";

            // Test combined template
            var r10 = lib.parseNameTemplate(\"{ROWALPHA}{padcol:2}-{padindex:3}\", {row: 2, col: 5, index: 9, total: 20});
            result.checks.combined = r10 === \"B05-009\";

            result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
            result.details = {
                rowCol: r1,
                rowCol0: r2,
                padRowCol: r3,
                alphaUpper: r4,
                alphaLower: r5,
                index: r6,
                index0: r7,
                padIndex: r8,
                total: r9,
                combined: r10
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

# Test 4: Matrix Position Calculations
echo "Test 4: Matrix Position Calculations..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"Matrix Positions\", checks: {}, passed: false };
        try {
            var lib = PlugIn.find(\"com.networmix.NetworkDiagramTools\").library(\"MatrixLib\");

            var topLeft = new Point(100, 100);
            var rows = 3;
            var cols = 4;
            var width = 50;
            var height = 40;
            var hSpacing = 20;
            var vSpacing = 30;

            var positions = lib.calculateMatrixPositions(rows, cols, width, height, hSpacing, vSpacing, topLeft);

            // Check count: 3 rows * 4 cols = 12
            result.checks.positionCount = positions.length === 12;

            // Check first position (row 1, col 1)
            result.checks.firstRow = positions[0].row === 1;
            result.checks.firstCol = positions[0].col === 1;
            result.checks.firstIndex = positions[0].index === 1;
            result.checks.firstX = positions[0].rect.x === 100;
            result.checks.firstY = positions[0].rect.y === 100;

            // Check second position (row 1, col 2)
            result.checks.secondX = positions[1].rect.x === 170; // 100 + 50 + 20
            result.checks.secondY = positions[1].rect.y === 100;
            result.checks.secondCol = positions[1].col === 2;

            // Check fifth position (row 2, col 1)
            result.checks.fifthRow = positions[4].row === 2;
            result.checks.fifthCol = positions[4].col === 1;
            result.checks.fifthIndex = positions[4].index === 5;
            result.checks.fifthX = positions[4].rect.x === 100;
            result.checks.fifthY = positions[4].rect.y === 170; // 100 + 40 + 30

            // Check last position (row 3, col 4)
            result.checks.lastRow = positions[11].row === 3;
            result.checks.lastCol = positions[11].col === 4;
            result.checks.lastIndex = positions[11].index === 12;

            // Check dimensions
            result.checks.correctWidth = positions.every(function(p) { return p.rect.width === 50; });
            result.checks.correctHeight = positions.every(function(p) { return p.rect.height === 40; });

            result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
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

# Test 5: Configuration Validation
echo "Test 5: Configuration Validation..."
RESULT=$(osascript -e '
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: \"Matrix Validation\", checks: {}, passed: false };
        try {
            var lib = PlugIn.find(\"com.networmix.NetworkDiagramTools\").library(\"MatrixLib\");

            // Valid config
            var validConfig = {
                rows: 4, cols: 4,
                deviceWidth: 50, deviceHeight: 50
            };
            var v1 = lib.validateConfig(validConfig);
            result.checks.validConfigPasses = v1.valid === true;
            result.checks.validConfigNoErrors = v1.errors.length === 0;

            // Invalid rows (zero)
            var invalidRows = {
                rows: 0, cols: 4,
                deviceWidth: 50, deviceHeight: 50
            };
            var v2 = lib.validateConfig(invalidRows);
            result.checks.zeroRowsFails = v2.valid === false;

            // Invalid cols (too high)
            var invalidCols = {
                rows: 4, cols: 65,
                deviceWidth: 50, deviceHeight: 50
            };
            var v3 = lib.validateConfig(invalidCols);
            result.checks.highColsFails = v3.valid === false;

            // Invalid dimensions (too small)
            var smallDims = {
                rows: 4, cols: 4,
                deviceWidth: 10, deviceHeight: 50
            };
            var v4 = lib.validateConfig(smallDims);
            result.checks.smallDimsFails = v4.valid === false;

            // Large matrix warning
            var largeConfig = {
                rows: 30, cols: 30,
                deviceWidth: 50, deviceHeight: 50
            };
            var v5 = lib.validateConfig(largeConfig);
            result.checks.largeMatrixWarns = v5.warnings.length > 0;
            result.checks.largeMatrixValid = v5.valid === true;

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

# Test 6: Full Matrix Generation (3x3) - Creates a new document first
echo "Test 6: Full Matrix Generation (3x3)..."
RESULT=$(osascript << 'APPLESCRIPT'
tell application "OmniGraffle"
    activate
    delay 0.5

    -- Create a new document
    set newDoc to make new document with properties {name:"Matrix Test"}
    delay 1

    set jsCode to "
        var result = { test: 'Matrix Generation', checks: {}, passed: false };
        try {
            var lib = PlugIn.find('com.networmix.NetworkDiagramTools').library('MatrixLib');

            // Get the canvas
            var portfolio = document.portfolio;
            var canvas = portfolio.canvases[0];

            if (!canvas) {
                result.error = 'No canvas available in portfolio';
            } else {
                // Count initial graphics
                var initialCount = canvas.graphics.length;

                // Configuration
                var config = {
                    rows: 3,
                    cols: 3,
                    deviceWidth: 60,
                    deviceHeight: 50,
                    hSpacing: 40,
                    vSpacing: 40,
                    shape: 'Rectangle',
                    fillColorIndex: 0,
                    strokeColorIndex: 0,
                    nameTemplate: 'R{row}C{col}',
                    labels: { fontSize: 10, textColorIndex: 0 },
                    addBackground: true,
                    backgroundMargin: 15
                };

                var viewCenter = new Point(400, 300);

                // Generate matrix
                var matrix = lib.generateMatrix(canvas, viewCenter, config);

                // Verify results
                result.checks.deviceCount = matrix.devices.length === 9; // 3x3
                result.checks.positionCount = matrix.positions.length === 9;
                result.checks.backgroundCreated = matrix.background !== null;

                // Check shape types
                result.checks.allShapes = matrix.devices.every(function(g) {
                    return g instanceof Shape;
                });

                // Check labels
                result.checks.firstLabel = matrix.devices[0].text === 'R1C1';
                result.checks.lastLabel = matrix.devices[8].text === 'R3C3';
                result.checks.middleLabel = matrix.devices[4].text === 'R2C2';

                // Check canvas graphics count (9 devices + 1 background)
                var finalCount = canvas.graphics.length;
                result.checks.canvasGraphicsAdded = finalCount === initialCount + 10;

                // Check colors (should be blue - index 0)
                var firstFill = matrix.devices[0].fillColor;
                result.checks.colorBlue = Math.abs(firstFill.red - 0.29) < 0.1 &&
                                          Math.abs(firstFill.blue - 0.85) < 0.1;

                // Check dimensions
                result.checks.correctWidth = Math.abs(matrix.devices[0].geometry.width - 60) < 1;
                result.checks.correctHeight = Math.abs(matrix.devices[0].geometry.height - 50) < 1;

                result.passed = Object.keys(result.checks).every(function(k) { return result.checks[k]; });
                result.summary = {
                    devices: matrix.devices.length,
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

# Test 7: Different Shapes
echo "Test 7: Different Shapes..."
RESULT=$(osascript << 'APPLESCRIPT'
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: 'Matrix Shapes', checks: {}, passed: false };
        try {
            var lib = PlugIn.find('com.networmix.NetworkDiagramTools').library('MatrixLib');
            var portfolio = document.portfolio;
            var canvas = portfolio.canvases[0];

            if (!canvas) {
                result.error = 'No canvas available';
            } else {
                var config = {
                    rows: 2,
                    cols: 2,
                    deviceWidth: 60,
                    deviceHeight: 60,
                    hSpacing: 30,
                    vSpacing: 30,
                    shape: 'Circle',
                    fillColorIndex: 4, // Purple
                    strokeColorIndex: 4,
                    nameTemplate: 'C{index}',
                    labels: { fontSize: 10, textColorIndex: 0 },
                    addBackground: false,
                    backgroundMargin: 10
                };

                var viewCenter = new Point(200, 500);
                var matrix = lib.generateMatrix(canvas, viewCenter, config);

                result.checks.deviceCount = matrix.devices.length === 4;
                result.checks.noBackground = matrix.background === null;
                result.checks.circleLabel = matrix.devices[0].text === 'C1';

                // Check dimensions (circles)
                result.checks.correctDimensions = Math.abs(matrix.devices[0].geometry.width - 60) < 1;

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

# Test 8: Hex Color Support
echo "Test 8: Hex Color Support..."
RESULT=$(osascript << 'APPLESCRIPT'
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: 'Matrix Hex Colors', checks: {}, passed: false };
        try {
            var lib = PlugIn.find('com.networmix.NetworkDiagramTools').library('MatrixLib');

            // Test parseHexColor (via CommonLib)
            var parsed = lib.parseHexColor('#FF5500');
            result.checks.parseHexRed = Math.abs(parsed[0] - 1.0) < 0.01;
            result.checks.parseHexGreen = Math.abs(parsed[1] - 0.333) < 0.01;
            result.checks.parseHexBlue = Math.abs(parsed[2] - 0) < 0.01;

            // Test invalid hex
            var invalid = lib.parseHexColor('invalid');
            result.checks.invalidHexReturnsNull = invalid === null;

            // Test darkenColor
            var dark = lib.darkenColor([1.0, 0.5, 0.25, 1]);
            result.checks.darkenRed = Math.abs(dark[0] - 0.65) < 0.01;

            // Test matrix generation with hex colors
            var portfolio = document.portfolio;
            var canvas = portfolio.canvases[0];

            if (canvas) {
                var config = {
                    rows: 2,
                    cols: 2,
                    deviceWidth: 50,
                    deviceHeight: 50,
                    hSpacing: 30,
                    vSpacing: 30,
                    shape: 'Diamond',
                    fillColorHex: '#FF0000',
                    strokeColorHex: '#AA0000',
                    nameTemplate: 'Hex-{index}',
                    labels: { fontSize: 10, textColorIndex: 1 },
                    addBackground: false,
                    backgroundMargin: 10
                };

                var viewCenter = new Point(400, 500);
                var matrix = lib.generateMatrix(canvas, viewCenter, config);

                // Check fill is red
                var fill = matrix.devices[0].fillColor;
                result.checks.hexFillRed = fill.red > 0.9 && fill.green < 0.1 && fill.blue < 0.1;

                result.checks.hexLabel = matrix.devices[0].text === 'Hex-1';
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

# Test 9: Single Row and Single Column
echo "Test 9: Single Row and Single Column..."
RESULT=$(osascript << 'APPLESCRIPT'
tell application "OmniGraffle"
    set jsCode to "
        var result = { test: 'Single Row/Column', checks: {}, passed: false };
        try {
            var lib = PlugIn.find('com.networmix.NetworkDiagramTools').library('MatrixLib');
            var portfolio = document.portfolio;
            var canvas = portfolio.canvases[0];

            if (!canvas) {
                result.error = 'No canvas available';
            } else {
                // Test single row (1x4)
                var singleRowConfig = {
                    rows: 1,
                    cols: 4,
                    deviceWidth: 50,
                    deviceHeight: 50,
                    hSpacing: 20,
                    vSpacing: 20,
                    shape: 'Rectangle',
                    fillColorIndex: 2,
                    strokeColorIndex: 2,
                    nameTemplate: 'Col{col}',
                    labels: { fontSize: 10, textColorIndex: 0 },
                    addBackground: false,
                    backgroundMargin: 10
                };

                var viewCenter = new Point(300, 600);
                var singleRow = lib.generateMatrix(canvas, viewCenter, singleRowConfig);

                result.checks.singleRowCount = singleRow.devices.length === 4;
                result.checks.singleRowLabel = singleRow.devices[2].text === 'Col3';

                // Test single column (4x1)
                var singleColConfig = {
                    rows: 4,
                    cols: 1,
                    deviceWidth: 50,
                    deviceHeight: 50,
                    hSpacing: 20,
                    vSpacing: 20,
                    shape: 'Rectangle',
                    fillColorIndex: 3,
                    strokeColorIndex: 3,
                    nameTemplate: 'Row{row}',
                    labels: { fontSize: 10, textColorIndex: 0 },
                    addBackground: false,
                    backgroundMargin: 10
                };

                var viewCenter2 = new Point(500, 600);
                var singleCol = lib.generateMatrix(canvas, viewCenter2, singleColConfig);

                result.checks.singleColCount = singleCol.devices.length === 4;
                result.checks.singleColLabel = singleCol.devices[2].text === 'Row3';

                // Test 1x1
                var oneByOneConfig = {
                    rows: 1,
                    cols: 1,
                    deviceWidth: 80,
                    deviceHeight: 80,
                    hSpacing: 20,
                    vSpacing: 20,
                    shape: 'Circle',
                    fillColorIndex: 5,
                    strokeColorIndex: 5,
                    nameTemplate: 'Single',
                    labels: { fontSize: 12, textColorIndex: 0 },
                    addBackground: false,
                    backgroundMargin: 10
                };

                var viewCenter3 = new Point(700, 600);
                var oneByOne = lib.generateMatrix(canvas, viewCenter3, oneByOneConfig);

                result.checks.oneByOneCount = oneByOne.devices.length === 1;
                result.checks.oneByOneLabel = oneByOne.devices[0].text === 'Single';

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

echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""
echo "All tests completed. Review output above for PASSED/FAILED status."
echo ""
