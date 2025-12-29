/*
Wall-mount tabs for Cable_organiser_Medium.stl
- Easy offsets: tabs_dx (left/right), tabs_dy (front/back), tabs_dz (up/down)
- Handles whether "back" is MIN_Y or MAX_Y
*/

$fn = 64;

import_stl = "Cable_organiser_Medium.stl";

// ---- MEASURED VALUES (edit once) ----
model_min_x = 0;
model_max_x = 190;

model_min_y = 0;
model_max_y = 120;   // measure this too!

model_min_z = 0;
model_max_z = 80;

// ---- Choose which face is the "back" ----
back_is_min_y = true;   // set false if the back is MAX_Y

model_back_y = back_is_min_y ? model_min_y : model_max_y;

// ---- Tab parameters ----
tab_w = 30;
tab_h = 18;
tab_t = 8;
edge_inset = 18;

// ---- Screw hole ----
hole_d = 5.2;           // M5-ish
hole_z_ratio = 0.70;    // 70% up

// ---- Global placement offsets (THIS is what you want) ----
// Move tabs LEFT:  tabs_dx = -10;
// Move tabs BACK:  tabs_dy = -5 or +5 depending on your back_is_min_y setting
tabs_dx = -28;   // + right, - left
tabs_dy = 38;   // + toward +Y, - toward -Y
tabs_dz = 0;   // + up, - down

function hole_z() = model_min_z + (model_max_z - model_min_z) * hole_z_ratio;

// back face anchor: tab grows "outward" from the back
function tab_y0() =
  back_is_min_y ? (model_back_y - tab_t + tabs_dy) : (model_back_y + tabs_dy);

module mount_tab(cx) {
  difference() {
    // tab body
    translate([
      cx - tab_w/2 + tabs_dx,
      tab_y0(),
      hole_z() - tab_h/2 + tabs_dz
    ])
      cube([tab_w, tab_t, tab_h]);

    // hole (drilled through thickness direction)
    translate([
      cx + tabs_dx,
      tab_y0() + tab_t/2,
      hole_z() + tabs_dz
    ])
      rotate([90,0,0])
        cylinder(d=hole_d, h=tab_t + 2, center=true);
  }
}

union() {
  import(import_stl);

  // Left tab
  mount_tab(model_min_x + edge_inset + tab_w/2);

  // Right tab
  mount_tab(model_max_x - edge_inset - tab_w/2);
}
//