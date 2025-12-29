/*
Weekly Pill Sorter – merged concept
- 7 counting pockets (10mm pills)
- Sliding gate (prints separately) that either blocks pocket drop holes or aligns them
- Funnels/channels below to guide pills into a 7-day organizer

Print recommendation:
- Print BASE and GATE as separate parts.
- BASE: flat on build plate.
- GATE: flat on build plate (no supports).
- Optional PUSHER: separate part.

Units: mm
*/

$fn = 64;

// ---------- User Parameters ----------
pill_d          = 10;      // target pill diameter
count           = 7;       // days
wall            = 2.0;     // wall thickness
base_th         = 3.0;     // base plate thickness under funnels
tray_depth      = 60;      // top loading tray depth
tray_width_pad  = 20;      // extra width around pockets
pocket_depth    = 3.2;     // recess depth for pocket (enough to "seat" pill)
pocket_pitch    = 16.0;    // center-to-center spacing between pockets
pocket_r        = pill_d/2 + 1.0;

gate_th         = 2.0;     // gate thickness
gate_clearance  = 0.25;    // XY clearance for gate sliding
slot_h          = gate_th + 0.6;   // height of gate slot inside base

drop_hole_d     = pill_d - 2.0;    // hole below each pocket (smaller than pill)
drop_hole_r     = drop_hole_d/2;

channel_w       = 14.0;    // width of each funnel/channel (target ~10mm pills)
channel_h       = 12.0;    // channel wall height above floor
funnel_len      = 65.0;    // sloped section length
exit_len        = 15.0;    // straight exit length (to line up to organizer)
slope_h         = 18.0;    // total height drop across funnel_len (controls slope angle)

lip_h           = 8.0;     // side walls height around tray
corner_r        = 6.0;     // outer rounding

// Derived
total_pocket_span = (count-1)*pocket_pitch;
inner_w           = total_pocket_span + 2*pocket_r;
outer_w           = inner_w + 2*tray_width_pad;
total_len         = tray_depth + funnel_len + exit_len + wall*2;

// Gate travel: closed <-> open distance
gate_travel       = drop_hole_d + 3.0;

// ---------- Part Selector ----------
part = "base";   // "base" | "gate" | "pusher" | "all"

// ---------- Helpers ----------
module rounded_box(w,l,h,r){
  // Minkowski is heavy; for simple prints this is OK at $fn=64
  minkowski(){
    cube([w-2*r, l-2*r, h], center=false);
    cylinder(r=r, h=0.01);
  }
}

module pocket_centers(){
  for(i=[0:count-1]){
    translate([outer_w/2 - total_pocket_span/2 + i*pocket_pitch, tray_depth*0.60, 0])
      children();
  }
}

// ---------- BASE ----------
module base(){
  difference(){
    // Outer shell block (tray + funnel volume)
    translate([0,0,0])
      rounded_box(outer_w, total_len, base_th + channel_h + slope_h + lip_h, corner_r);

    // Hollow out tray area (creates shallow tray + walls)
    translate([wall, wall, base_th + slope_h])
      rounded_box(outer_w-2*wall, tray_depth, (channel_h + lip_h + 20), max(0,corner_r-wall));

    // Lower out funnel region volume (we'll re-add floor later)
    translate([wall, tray_depth+wall, 0])
      cube([outer_w-2*wall, funnel_len+exit_len, base_th + slope_h + channel_h + lip_h + 30]);

    // Gate slot (under pockets): a cavity that allows the gate to slide
    translate([wall, wall, base_th + slope_h - slot_h])
      cube([outer_w-2*wall, tray_depth-2*wall, slot_h]);

    // Pocket recesses (shallow cups)
    translate([0,0,base_th + slope_h + 0.01])
      pocket_centers()
        cylinder(r=pocket_r, h=pocket_depth, center=false);

    // Drop holes (vertical) through the tray floor down to gate slot
    translate([0,0,0])
      pocket_centers()
        translate([0,0,0])
          cylinder(r=drop_hole_r, h=base_th + slope_h + 5, center=false);

    // Add a finger cutout for grabbing the gate
    translate([outer_w - 18, wall+6, base_th + slope_h - slot_h + 0.2])
      cube([14, 14, slot_h+2], center=false);
  }

  // Now add the funnel floors and dividers as positive geometry
  funnels_and_dividers();

  // Add tray walls (lip)
  tray_lip();
}

module tray_lip(){
  // simple perimeter lip
  translate([0,0,base_th + slope_h])
  difference(){
    rounded_box(outer_w, tray_depth+wall*2, lip_h, corner_r);
    translate([wall, wall, -1])
      rounded_box(outer_w-2*wall, tray_depth, lip_h+3, max(0,corner_r-wall));
  }
}

module funnels_and_dividers(){
  // Create one continuous sloped floor across the funnel region, then carve channels
  // Floor wedge (slope down toward exits)
  translate([wall, tray_depth+wall, base_th])
  difference(){
    // wedge volume
    polyhedron(
      points=[
        [0,0, slope_h], [outer_w-2*wall,0, slope_h],
        [outer_w-2*wall, funnel_len+exit_len, 0], [0, funnel_len+exit_len, 0],
        [0,0, slope_h+channel_h], [outer_w-2*wall,0, slope_h+channel_h],
        [outer_w-2*wall, funnel_len+exit_len, channel_h], [0, funnel_len+exit_len, channel_h]
      ],
      faces=[
        [0,1,2,3],      // bottom
        [4,7,6,5],      // top
        [0,4,5,1],      // back (near tray)
        [1,5,6,2],      // right
        [2,6,7,3],      // front (exits)
        [3,7,4,0]       // left
      ]
    );

    // Carve 7 channels into the wedge
    for(i=[0:count-1]){
      x0 = (outer_w-2*wall)/2 - ((count*channel_w)+(count-1)*wall)/2 + i*(channel_w+wall);
      translate([x0, 0, -1])
        cube([channel_w, funnel_len+exit_len, slope_h+channel_h+3], center=false);
    }
  }

  // Add the vertical dividers as walls between channels (they are self-supporting because they're vertical)
  translate([wall, tray_depth+wall, base_th])
  for(i=[0:count]){
    xw = (outer_w-2*wall)/2 - ((count*channel_w)+(count-1)*wall)/2 + i*channel_w + max(0,i-1)*wall;
    translate([xw, 0, 0])
      cube([wall, funnel_len+exit_len, slope_h+channel_h], center=false);
  }
}

// ---------- GATE ----------
module gate(){
  // A flat plate that slides under the tray.
  // It has "open" holes offset by gate_travel. Closed position is solid under drop holes.
  w = outer_w - 2*wall - 2*gate_clearance;
  l = tray_depth - 2*wall - 2*gate_clearance;

  difference(){
    translate([0,0,0])
      rounded_box(w, l, gate_th, max(0,corner_r-wall-gate_clearance));

    // "Open" holes are offset so you can slide to align
    for(i=[0:count-1]){
      cx = w/2 - total_pocket_span/2 + i*pocket_pitch;
      cy = l*0.60;
      translate([cx + gate_travel, cy, -1])
        cylinder(r=drop_hole_r+0.15, h=gate_th+3);
    }

    // finger notch
    translate([w-16, 6, -1]) cube([12, 12, gate_th+3]);
  }

  // small handle tab
  translate([w-10, 0, 0])
    cube([10, 18, gate_th], center=false);
}

// ---------- PUSHER (optional) ----------
module pusher(){
  // Simple spatula/pusher – keep it separate so the main model needs no supports.
  blade_w = channel_w*count + wall*(count-1);
  blade_t = 2.0;
  blade_l = 80;

  handle_w = 18;
  handle_l = 70;
  handle_h = 10;

  union(){
    // blade
    translate([0,0,0]) cube([blade_w, blade_l, blade_t], center=false);
    // handle (centered)
    translate([blade_w/2-handle_w/2, blade_l-10, blade_t])
      rounded_box(handle_w, handle_l, handle_h, 4);
  }
}

// ---------- Assembly ----------
module all_parts(){
  base();
  // show gate positioned "closed" and "open" for visualization
  translate([wall+gate_clearance, wall+gate_clearance, base_th + slope_h - slot_h + 0.2])
    gate();
  // open position ghost (comment out if you want)
  // translate([wall+gate_clearance + gate_travel, wall+gate_clearance, base_th + slope_h - slot_h + 0.2])
  //   color([0.6,0.6,0.6,0.4]) gate();
}

if(part=="base") base();
else if(part=="gate") gate();
else if(part=="pusher") pusher();
else all_parts();
