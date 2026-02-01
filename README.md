# Network Diagram Tools for OmniGraffle

Generate network topology diagrams with configurable layouts and styling.

## Installation

1. Download `NetworkDiagramTools.omnigrafflejs`
2. Double-click to install, or drag into **Automation > Configure... > Plug-Ins**

## Tools

### Clos Topology

Generate two-layer Clos (spine-leaf) network diagrams with full-mesh connectivity.

**Automation > Network Diagram Tools > Clos Topology**

| Field | Description |
|-------|-------------|
| Layout | Vertical (A top, B bottom) or Horizontal (A left, B right) |
| Side A/B Count | Number of devices per side (1-64) |
| Side A/B Name | Name template for device labels |
| Side A/B Color | Fill color with auto-darkened stroke |
| Links | Straight or curved connection lines |
| Add Background | White rectangle behind topology |
| Customize... | Opens advanced options |

**Advanced Options:** Layer/device spacing, shapes, dimensions, hex colors, text settings, link color/weight/pattern.

### Device Matrix

Generate a grid of devices arranged in rows and columns.

**Automation > Network Diagram Tools > Device Matrix**

| Field | Description |
|-------|-------------|
| Rows / Columns | Grid dimensions (1-64 each) |
| Name Template | Label template for devices |
| Fill Color | Device fill color |
| Stroke Color | Device border color |
| Add Background | White rectangle behind matrix |
| Customize... | Opens advanced options |

**Advanced Options:** Shape, dimensions, hex colors, spacing, text settings.

## Name Template Variables

### Clos Topology

| Variable | Output | Example |
|----------|--------|---------|
| `{index}` | 1-based index | 1, 2, 3 |
| `{index0}` | 0-based index | 0, 1, 2 |
| `{padindex:N}` | Zero-padded index | 01, 02 |
| `{alpha}` | Lowercase letter | a, b, c |
| `{ALPHA}` | Uppercase letter | A, B, C |
| `{total}` | Total device count | 4 |
| `{layer}` | Layer identifier | A, B |

### Device Matrix

| Variable | Output | Example |
|----------|--------|---------|
| `{row}` | 1-based row | 1, 2, 3 |
| `{col}` | 1-based column | 1, 2, 3 |
| `{row0}`, `{col0}` | 0-based | 0, 1, 2 |
| `{padrow:N}`, `{padcol:N}` | Zero-padded | 01, 02 |
| `{ROWALPHA}`, `{COLALPHA}` | Uppercase letter | A, B, C |
| `{rowalpha}`, `{colalpha}` | Lowercase letter | a, b, c |
| `{index}` | Sequential index | 1, 2, 3 |
| `{padindex:N}` | Zero-padded index | 01, 02 |
| `{total}` | Total device count | 16 |

## Colors

Colors can be selected from the palette (with emoji indicators) or specified as hex codes in advanced options.

**Palette:** Blue, Green, Red, Orange, Purple, Teal, Yellow, Gray, Dark Gray, White, Black

**Hex format:** `#RRGGBB` (e.g., `#FF5500`)

When using palette colors, strokes are automatically darkened for a professional monochromatic look.

## Development

To modify the plugin, copy to OmniGraffle's plugin directory:

```bash
cp -R NetworkDiagramTools.omnigrafflejs ~/Library/Containers/com.omnigroup.OmniGraffle7/Data/Library/Application\ Support/Plug-Ins/
```

Re-copy after changes and reload via **Automation > Configure... > Plug-Ins**.

Automated tests are in `tests/` (requires OmniGraffle installed).

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

Andrey Golovanov
