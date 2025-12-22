
// Creality K1 / K1 Max FFC/ZIF Ribbon Clip (v2 - easier to fit)
// ------------------------------------------------------------
// Key change vs v1: you set the *INNER* cavity dimensions (what must fit),
// and then tune clearance/pressure with a couple of simple parameters.
//
// PRINT
// - Print with the open side DOWN (default orientation in file).
// - PLA or PETG. PETG is more forgiving.
//
// INSTALL
// - Power off printer.
// - Seat ribbon, close ZIF latch.
// - Slide clip over connector + ribbon. If too tight, increase `side_clearance`.
//
// --------------------
// MEASURE THESE 3
// --------------------
inner_width  = 22.0;  // mm  : connector body width (left-to-right)
inner_depth  = 4.2;   // mm  : connector body depth (front-to-back)
inner_height = 3.2;   // mm  : connector body height (PCB to top of connector, without cable)

// --------------------
// TUNE FIT / PRESSURE
// --------------------
side_clearance = 0.35;  // mm per side. Increase if arms won't slide on (try 0.45, 0.55)
front_clearance = 0.20; // mm (depth clearance). Increase if it binds front/back
top_clearance   = 0.15; // mm (height clearance). Increase if it binds vertically
top_press       = 0.35; // mm extra downward press on cable (0.2–0.5 typical)

// --------------------
// CLIP GEOMETRY
// --------------------
wall_thickness  = 1.6;  // mm outer plastic thickness
arm_drop        = 3.5;  // mm how far arms extend down sides
lead_in         = 0.8;  // mm chamfer lead-in to help sliding on
split_gap       = 0.8;  // mm slot in top bar to add flex (helps tight connectors)
fillet_r        = 0.6;  // mm rounded edges

$fn = 28;

// helper: rounded rectangle prism
module rounded_prism(x,y,z,r){
  minkowski(){
    cube([x-2*r, y-2*r, z-2*r], center=false);
    sphere(r=r);
  }
}

module clip_v2(){
  // cavity (what must fit)
  cav_w = inner_width  + 2*side_clearance;
  cav_d = inner_depth  + 2*front_clearance;
  cav_h = inner_height + top_clearance;

  // outer
  out_w = cav_w + 2*wall_thickness;
  out_d = cav_d + wall_thickness;              // extra at back for strength
  out_h = cav_h + wall_thickness + top_press;  // add press on top

  difference(){
    // OUTER "U" BODY
    union(){
      // top bar
      translate([0,0,out_h-wall_thickness])
        rounded_prism(out_w, out_d, wall_thickness, fillet_r);

      // left arm
      translate([0,0,out_h-arm_drop])
        rounded_prism(wall_thickness, out_d, arm_drop, fillet_r);

      // right arm
      translate([out_w-wall_thickness,0,out_h-arm_drop])
        rounded_prism(wall_thickness, out_d, arm_drop, fillet_r);
    }

    // CAVITY (connector space)
    translate([wall_thickness, wall_thickness/2, out_h-(cav_h+top_press)])
      cube([cav_w, cav_d, cav_h+top_press]);

    // LEAD-IN CHAMFER (makes it easier to start sliding on)
    translate([wall_thickness-0.01, -0.01, out_h-(cav_h+top_press)])
      linear_extrude(height=cav_h+top_press)
        polygon(points=[
          [0,0],
          [cav_w,0],
          [cav_w,lead_in],
          [0,lead_in]
        ]);

    // FLEX SLOT in top bar (optional)
    if (split_gap > 0){
      translate([out_w/2 - split_gap/2, 0, out_h-wall_thickness-0.1])
        cube([split_gap, out_d, wall_thickness+0.2]);
    }
  }
}

// orient for printing: open side down
rotate([180,0,0]) clip_v2();
