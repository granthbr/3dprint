# Claude Code Project Guide

## Project Overview

This is a 3D printing project repository containing parametric designs for 3D printable objects, starting with a 7-day pill organizer.

## Key Files

- `pill_organizer.scad` - OpenSCAD parametric design for the pill organizer
- `pill_organizer.stl` - Exported STL ready for slicing

## Design Tool

**OpenSCAD** is the primary CAD tool for this project (not Fusion 360).

- Code-based parametric modeling
- Parameters at top of `.scad` files control dimensions
- F5 to preview, F6 to render, then export STL

Note: A Fusion 360 Python script was attempted but removed due to API complexity. OpenSCAD is simpler and free.

## Printer

Creality K1 Max (300x300x300mm build volume)

## Current Design: 7-Day Pill Organizer

A weekly medication organizer with:
- 7 daily compartments (SUN-SAT)
- 10 pill type channels for loading
- Slide-channel system: place 7 of each pill type in a row, tilt to dispense into daily compartments
- Embossed labels on compartments and channels

### Dimensions
- Width: ~186mm
- Depth: ~130mm
- Height: ~42mm

### Print Settings
- Layer height: 0.2mm
- Infill: 15-20%
- Walls: 3 perimeters
- Supports: None needed
- Brim: Recommended

## Workflow

1. Edit `.scad` file parameters as needed
2. Preview in OpenSCAD (F5)
3. Render (F6) and export STL
4. Import STL into Orca Slicer or Cura
5. Slice and print

## Project Status

- [x] Initial design complete with slide-channel loading system
- [x] Embossed labels added (SUN-SAT on compartments, 1-10 on pill channels)
- [x] STL exported and ready for slicing
- [ ] Test print
- [ ] Adjust dimensions based on test fit

## Future Enhancements (not yet implemented)

- Individual day lids (hinged or snap-on)
- Stackable design for multiple weeks
- Travel version (4-day variant)
