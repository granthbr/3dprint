# 3D Print Projects

## 7-Day Pill Organizer with Slide-Channel Loading

A parametric pill organizer designed for 3D printing that holds 7 days of medication with 10 different pill types per day.

### Features

- **7 daily compartments** (Sunday through Saturday)
- **10 pill channels** for loading different pill types
- **Slide-channel loading system** - place 7 of each pill type in a row, tilt to dispense into daily compartments
- **Finger grip cutouts** for easy pill retrieval
- **Parametric design** - easily adjust dimensions in OpenSCAD

### Dimensions

| Component | Size |
|-----------|------|
| Total Width | ~186mm |
| Total Depth | ~130mm |
| Total Height | ~42mm |
| Daily Compartment | 25mm x 40mm x 25mm |
| Pill Slot | 12mm wide (for pills up to 10mm) |

### Design Overview

```
SIDE VIEW:
                    ┌─────────────────┐
                    │ LOADING SECTION │  ← 10 rows of pill slots
                    │  (10 channels)  │     (7 per row)
                    └────────\────────┘
                              \  ← Ramp (pills slide down)
┌──────────────────────────────\──────┐
│  SUN │ MON │ TUE │ WED │...        │  ← Daily compartments
│      │     │     │     │           │
└─────────────────────────────────────┘
   ↑ Finger grip cutouts for easy access
```

### How to Use

**Loading:**
1. Place 7 pills of type 1 across the first loading row (S-M-T-W-T-F-S)
2. Repeat for all 10 pill types
3. Tilt the tray slightly toward you - pills slide into daily compartments

**Daily Use:**
- Grab all pills from that day's compartment

### Printing

**Printer:** Creality K1 Max (300x300x300mm build volume)

**Recommended Settings:**
- Layer height: 0.2mm
- Infill: 15-20%
- Walls: 3 perimeters
- Supports: None needed
- Brim: Recommended for bed adhesion

### Files

- `pill_organizer.scad` - OpenSCAD source file (parametric)

### Requirements

- [OpenSCAD](https://openscad.org/downloads.html) to edit and export STL
- Slicer software (Orca Slicer, Cura, etc.)

### Customization

Edit the parameters at the top of `pill_organizer.scad` to adjust:
- `days` - number of daily compartments
- `pill_types` - number of pill channels
- `pill_slot_width` - width of each pill slot
- `compartment_width/depth/height` - daily compartment dimensions
- `wall` - wall thickness
