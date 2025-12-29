/*
Weekly Pill Distributor (Manual Guided Tray)
- 7 lanes (Mon..Sun)
- Staging area with 7 parking pockets
- Separate comb/sweeper rides in guide rails
Designed for ~10–11 mm round tablets/capsules.

Print notes:
- Tray: print flat on bed.
- Comb: print flat on bed.
- Tolerances are built-in; if your printer is tight, increase clearance_* params.

Units: mm
*/

// ---------- Parameters ----------
$fn = 64;

// Pills
pill_max_d = 11;            // max pill diameter

// Lanes
lanes = 7;
lane_inner_w = 13.0;        // inside width of each lane
lane_wall_t = 2.2;          // wall thickness
lane_depth = 20;            // wall height (depth)
lane_len = 105;             // length of lanes (front-to-back)

// Parking pockets (1 pill each)
pocket_d = 12.4;            // pocket diameter (slightly larger than pill)
pocket_depth = 3.2;         // pocket recess depth
pocket_pitch = 16.0;        // center-to-center spacing

// Staging area
staging_w = 130;
staging_d = 75;
staging_wall_h = 12;
staging_wall_t = 2.2;

// Base plate
base_t = 2.4;
outer_margin = 8;

// Comb / sweeper
comb_t = 2.8;               // thickness
comb_handle_h = 12;
comb_handle_t = 6;
tooth_len = 12;             // how far teeth push into lane entrance
tooth_clear = 0.25;         // clearance per side vs lane walls

// Guide rails
rail_h = 5;
rail_t = 3.0;
clearance_slide = 0.35;     // clearance per side between rails and comb groove

// Feature toggles
show_tray = true;
show_comb = true;

// ---------- Derived ----------
lane_outer_w = lane_inner_w + 2*lane_wall_t;
lanes_block_w = lanes*lane_outer_w;

pockets_row_w = (lanes-1)*pocket_pitch + pocket_d;
tray_w = max(staging_w, lanes_block_w) + 2*outer_margin;
tray_d = staging_d + lane_len + 2*outer_margin;

// Positioning
x0 = -tray_w/2;
y0 = -tray_d/2;

// Put pockets centered above lane entrances
pockets_x_start = -((lanes-1)*pocket_pitch)/2;
pockets_y = y0 + outer_margin + staging_d - 18; // pocket row slightly above lane entrances

lane_y_start = y0 + outer_margin + staging_d;   // lanes start right after staging area

// Rails run along staging area + pocket row down across lane entrances
rail_span_y0 = y0 + outer_margin + 8;
rail_span_y1 = lane_y_start + 22;

// ---------- Helpers ----------
module rounded_rect(w,d,r){
  // 2D rounded rectangle centered
  offset(r=r) square([w-2*r, d-2*r], center=true);
}

module tray_body(){
  // Base plate
  difference(){
    translate([0,0,base_t/2]) cube([tray_w, tray_d, base_t], center=true);

    // Optional: cut a small finger notch on one side
    translate([0, y0 + 1.2, -0.1]) cylinder(d=28, h=base_t+1, center=false);
  }

  // Staging area walls (no floor—base plate is floor)
  translate([0, y0 + outer_margin + staging_d/2, base_t])
  difference(){
    // outer wall
    linear_extrude(height=staging_wall_h)
      rounded_rect(staging_w, staging_d, 8);
    // inner void
    translate([0,0,-0.1])
      linear_extrude(height=staging_wall_h+0.2)
        rounded_rect(staging_w - 2*staging_wall_t, staging_d - 2*staging_wall_t, 6);
  }

  // Lane block (7 channels)
  translate([0, lane_y_start + lane_len/2, base_t])
  difference(){
    // outer solid for walls
    translate([0,0,lane_depth/2])
      cube([lanes_block_w, lane_len, lane_depth], center=true);

    // carve each lane interior
    for(i=[0:lanes-1]){
      x = -lanes_block_w/2 + lane_wall_t + lane_inner_w/2 + i*lane_outer_w;
      translate([x, 0, lane_depth/2 + 0.1])
        cube([lane_inner_w, lane_len+0.2, lane_depth+0.4], center=true);
    }

    // Open the top (so it's hollow) - already hollow, but ensure no roof
    // Not needed; walls are formed by subtraction.
  }

  // Pocket recesses (row of 7)
  difference(){
    // nothing: we subtract from base plate + staging floor area
  }
  for(i=[0:lanes-1]){
    x = pockets_x_start + i*pocket_pitch;
    translate([x, pockets_y, base_t - pocket_depth + 0.01])
      cylinder(d=pocket_d, h=pocket_depth+0.02, center=false);
  }

  // Lane labels (engraved)
  labels = ["M","T","W","T","F","S","S"];
  for(i=[0:lanes-1]){
    x = -lanes_block_w/2 + lane_wall_t + lane_inner_w/2 + i*lane_outer_w;
    translate([x, lane_y_start + 10, base_t + 0.6])
      linear_extrude(height=1.0)
        text(labels[i], size=7, halign="center", valign="center");
  }

  // Guide rails (two rails, left & right of pockets row)
  rail_gap = pockets_row_w + 16; // rails slightly outside pocket row
  for(side=[-1,1]){
    xr = side*(rail_gap/2);
    translate([xr, (rail_span_y0+rail_span_y1)/2, base_t])
      cube([rail_t, (rail_span_y1-rail_span_y0), rail_h], center=true);
  }

  // Lane entrance "funnel" chamfer (simple wedge) to help sweeping into lanes
  // This is subtle and optional: small bevel at lane entrances
  bevel_w = lanes_block_w;
  bevel_d = 8;
  bevel_h = 6;
  translate([0, lane_y_start + bevel_d/2, base_t])
    rotate([90,0,0])
      linear_extrude(height=bevel_d)
        polygon(points=[[-bevel_w/2,0],[bevel_w/2,0],[bevel_w/2,bevel_h],[-bevel_w/2,bevel_h]]);
}

// Comb that slides down, teeth align with lanes
module comb(){
  // overall width spans all lanes, plus small side flanges that ride rails
  comb_w = lanes_block_w - 0.2; // slight overall shrink
  // groove centers match tray rails
  rail_gap = pockets_row_w + 16;
  groove_w = rail_t + 2*clearance_slide;
  groove_d = 10; // depth of groove into comb body (in X)
  body_h = 14;   // height of comb body (Y thickness area)
  body_d = 18;   // front-to-back (Y) size of comb body

  // Teeth widths fit lane inner width with clearance
  tooth_w = lane_inner_w - 2*tooth_clear;

  difference(){
    union(){
      // Main comb body
      translate([0,0,comb_t/2])
        cube([comb_w, body_d, comb_t], center=true);

      // Teeth (7)
      for(i=[0:lanes-1]){
        x = -lanes_block_w/2 + lane_wall_t + lane_inner_w/2 + i*lane_outer_w;
        translate([x, -(body_d/2 + tooth_len/2), comb_t/2])
          cube([tooth_w, tooth_len, comb_t], center=true);
      }

      // Handle (rear side)
      translate([0, body_d/2 + comb_handle_t/2, comb_handle_h/2])
        cube([comb_w*0.55, comb_handle_t, comb_handle_h], center=true);
    }

    // Rail grooves (so it rides on tray rails)
    for(side=[-1,1]){
      xg = side*(rail_gap/2);
      translate([xg, 0, comb_t/2])
        cube([groove_w, body_d+2, comb_t+1], center=true);
    }
  }
}

// ---------- Build ----------
if(show_tray){
  tray_body();
}

// Place comb above tray for viewing (not physically printed together)
if(show_comb){
  translate([0, y0 + outer_margin + staging_d - 8, base_t + rail_h + 2.0])
    comb();
}
