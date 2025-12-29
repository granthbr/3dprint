/*
Weekly Pill Sorting Tray (Pharmacist-style) — OpenSCAD
- 7 counting pockets sized for ~10mm pills
- Sliding gate (separate print) that either blocks or aligns the drop holes
- Straight drop chutes to 7 outlets (you align outlets over your pill organizer)

Print notes (K1 Max / PLA):
- Print BODY flat on the bed (no supports)
- Print GATE flat on the bed (no supports)
- Gate clearance is parameterized (gate_clearance) — tweak if tight/loose.

If you want the outlets to *snap* onto a specific organizer, tell me the exact
center-to-center spacing of the organizer wells, and the well opening size.
*/

$fn = 80;

// -------------------- Parameters --------------------
num_channels      = 7;

// Pills / pockets
pill_d            = 10;        // target pill diameter (mm)
pocket_d          = 12.6;      // pocket diameter (mm) ~ pill_d + clearance
pocket_depth      = 3.8;       // depth of pocket recess (mm)

// Channel geometry
pitch             = 22.0;      // center-to-center spacing across channels (mm)
drop_hole_d       = 12.2;      // drop hole diameter (mm) slightly < pocket_d
chute_d           = 14.0;      // vertical chute ID (mm) guides pill
outlet_d          = 14.5;      // bottom outlet diameter (mm)

// Walls / structure
wall              = 2.0;       // wall thickness around features (mm)
outer_round       = 8.0;       // corner rounding radius (mm)

// Heights
tray_depth        = 55.0;      // front-to-back depth of tray area (mm)
chute_depth       = 32.0;      // depth from gate plane to bottom outlets (mm)
top_lip           = 3.0;       // tray rim height (mm) above tray floor (visual)
body_floor        = 2.2;       // minimum bottom thickness under chutes (mm)

// Gate system
gate_th           = 1.8;       // gate thickness (mm) (print as a flat plate)
gate_plane_z      = 10.0;      // Z height where gate slides (mm from bottom)
gate_clearance    = 0.35;      // clearance between gate and rails (mm)
gate_travel       = 14.0;      // how far the gate moves between "closed" and "open"
gate_handle_len   = 22.0;      // handle length (mm)
gate_handle_w     = 16.0;      // handle width (mm)

// Derived sizes
total_w = (num_channels - 1) * pitch + pocket_d + 2*wall + 10; // +extra side margin
total_d = tray_depth + 22; // add a little back margin for structure
body_h  = max(gate_plane_z + gate_th + 4, chute_depth + body_floor);

// Pocket row Y position
pocket_y = tray_depth - 18; // pockets sit toward back of tray
pocket_x0 = (total_w - ((num_channels - 1) * pitch)) / 2; // centers alignment

// Drop hole Y position (directly under pockets)
drop_y = pocket_y;

// Chute outlets Y position (slightly forward, helps alignment to organizer)
out_y = 16;

// -------------------- Helpers --------------------
module rounded_box(w,d,h,r){
  // simple rounded rectangle prism
  hull(){
    translate([r,r,0]) cylinder(r=r,h=h);
    translate([w-r,r,0]) cylinder(r=r,h=h);
    translate([r,d-r,0]) cylinder(r=r,h=h);
    translate([w-r,d-r,0]) cylinder(r=r,h=h);
  }
}

module chamfered_cylinder(d1,d2,h){
  // linear taper (useful for gentle funnel edges without overhang surprises)
  cylinder(d1=d1,d2=d2,h=h);
}

function cx(i) = pocket_x0 + i*pitch;

// -------------------- Main: BODY --------------------
module body(){
  difference(){
    // Outer shell
    rounded_box(total_w, total_d, body_h, outer_round);

    // Top tray recess (shallow)
    translate([wall, wall, body_h - (top_lip + pocket_depth + 1.2)])
      rounded_box(total_w - 2*wall, tray_depth, top_lip + pocket_depth + 1.2, max(outer_round-3,2));

    // Pocket recesses (7)
    for(i=[0:num_channels-1]){
      translate([cx(i), pocket_y, body_h - (top_lip + 0.8)])
        translate([0,0,-pocket_depth])
          cylinder(d=pocket_d, h=pocket_depth + 0.2);
    }

    // Gate slot cavity (a horizontal slit through the body)
    // This creates the "tunnel" the gate plate slides through.
    translate([0, 0, gate_plane_z - gate_clearance])
      cube([total_w, total_d, gate_th + 2*gate_clearance], center=false);

    // Drop holes ABOVE the gate (these are where pills sit when gate is closed)
    // They go down to the gate plane, but not through it.
    for(i=[0:num_channels-1]){
      translate([cx(i), drop_y, gate_plane_z + gate_th + gate_clearance])
        cylinder(d=drop_hole_d, h=body_h); // subtract all above; the slot stops them at gate
    }

    // Chutes BELOW the gate (straight vertical guides down to outlets)
    // These start just below the gate plane and go to the bottom.
    for(i=[0:num_channels-1]){
      translate([cx(i), out_y, 0])
        cylinder(d=chute_d, h=gate_plane_z - gate_clearance);
    }

    // Bottom outlets: a tiny flare/chamfer to help pills exit cleanly
    for(i=[0:num_channels-1]){
      translate([cx(i), out_y, 0])
        chamfered_cylinder(outlet_d, chute_d, 2.2);
    }

    // Optional: front pour lip / scoop notch (helps dumping pills into tray)
    translate([total_w/2, 6, body_h-6])
      rotate([90,0,0]) cylinder(d=28,h=20);
  }

  // Rails / stops: keep gate aligned in the slit (prints as positive geometry)
  // Two thin rails above and below gate plane along the sides of the tray.
  rail_h = 1.2;
  rail_w = 3.2;
  // Left rail
  translate([wall, wall, gate_plane_z + gate_th + gate_clearance])
    cube([rail_w, total_d-2*wall, rail_h]);
  translate([wall, wall, gate_plane_z - rail_h - gate_clearance])
    cube([rail_w, total_d-2*wall, rail_h]);
  // Right rail
  translate([total_w-wall-rail_w, wall, gate_plane_z + gate_th + gate_clearance])
    cube([rail_w, total_d-2*wall, rail_h]);
  translate([total_w-wall-rail_w, wall, gate_plane_z - rail_h - gate_clearance])
    cube([rail_w, total_d-2*wall, rail_h]);

  // Travel stops: blocks to prevent over-pulling
  stop_w = 6;
  stop_d = 8;
  translate([0, total_d-stop_d-wall, gate_plane_z-2])
    cube([stop_w, stop_d, 6]);
  translate([total_w-stop_w, total_d-stop_d-wall, gate_plane_z-2])
    cube([stop_w, stop_d, 6]);
}

// -------------------- Separate Part: GATE --------------------
/*
Gate positions:
- "Closed": holes are offset so pills cannot fall into the chutes
- "Open": slide gate by gate_travel so holes align and pills drop

You physically slide the gate; you can add a detent later if you want.
*/
module gate(){
  gate_w = total_w - 2*wall - 2.0;     // inside shell
  gate_d = total_d - 2*wall - 2.0;

  // Offset for CLOSED state (misalignment)
  // For OPEN state, you move the gate by +gate_travel in Y (or X—your choice).
  offset = gate_travel;

  difference(){
    // Main plate
    translate([wall+1, wall+1, 0])
      rounded_box(gate_w, gate_d, gate_th, 3);

    // Gate holes: aligned to chutes when in OPEN position.
    // We cut them at (out_y) but shifted by "offset" so default printed gate = CLOSED.
    for(i=[0:num_channels-1]){
      translate([cx(i), out_y + offset, -0.1])
        cylinder(d=drop_hole_d, h=gate_th+0.2);
    }

    // Clearance scallops to avoid rubbing on the rails (optional)
    translate([wall+1.2, wall+1.2, -0.1])
      cube([3.0, gate_d-2.4, gate_th+0.2]);
    translate([total_w-wall-4.2, wall+1.2, -0.1])
      cube([3.0, gate_d-2.4, gate_th+0.2]);
  }

  // Handle tab (front-left)
  translate([wall+6, 2, 0])
    rounded_box(gate_handle_w, gate_handle_len, gate_th, 3);
  // Finger hole
  translate([wall+6 + gate_handle_w/2, 2 + gate_handle_len/2, -0.1])
    cylinder(d=9.0, h=gate_th+0.2);
}

// -------------------- Layout for printing --------------------
// Uncomment ONE of these to export STLs cleanly:

body();                 // export as BODY STL
//translate([0, total_d+20, 0]) gate();  // export as GATE STL beside it
