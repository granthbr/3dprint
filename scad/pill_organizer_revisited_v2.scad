// ============================================
// 7-Day Pill Organizer with Slide-Channel Loading
// For Creality K1 Max (300x300x300mm build volume)
// ============================================

// === PARAMETERS (adjust these to customize) ===

// Number of days (columns)
days = 7;

// Number of pill types (rows/channels)
pill_types = 10;

// Pill slot dimensions (for small pills up to 10mm)
pill_slot_width = 12;      // Width per pill channel
pill_slot_depth = 12;      // Depth of loading channel slots

// Daily compartment dimensions
compartment_width = 25;    // Width of each day's compartment
compartment_depth = 40;    // Front-to-back depth
compartment_height = 25;   // How deep the storage area is

// Wall thickness
wall = 2;

// Loading tray dimensions (calculated)
loading_channel_length = days * (compartment_width + wall) + wall;
loading_channel_width = pill_slot_width;

// Base/frame dimensions
total_width = days * (compartment_width + wall) + wall;
total_depth = compartment_depth + (pill_types * (pill_slot_depth + wall)) + wall * 3 + 15; // +15 for slide ramp
total_height = compartment_height + wall * 2;

// Loading section height
loading_height = 15;

// Ramp angle for pills to slide
ramp_angle = 20;

// Day labels (full names for clarity)
day_labels_short = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];

// Label settings
label_depth = 0.8;         // How deep/raised the embossed text is
label_font_size = 6;       // Font size for day labels
pill_label_font_size = 5;  // Font size for pill type numbers

// === MODULES ===

// Main storage compartments (bottom section)


// ============================================
// REVISION NOTES (v2)
// - Removes the integrated ramp from the main body to eliminate hard-to-remove supports.
// - Adds a "ramp_insert" that prints support-free as a simple wedge and slides into a slot.
// - Adds an optional "pusher" as a separate print (no supports).
//
// How to use:
// 1) Set part="base" and render/export STL.
// 2) Set part="ramp" and render/export STL.
// 3) Optional: part="pusher".
// 4) Assemble by sliding ramp tongue into the slot at the back of the base.
//
// TIP: If you still want a one-piece print, you *can* set part="all_one_piece",
// but it will likely require supports under the ramp underside.
// ============================================

part = "base"; // "base" | "ramp" | "pusher" | "lid" | "all_one_piece"

// Ramp insert / slot parameters
ramp_len = 18;             // how far the ramp insert extends over the compartments
ramp_drop = 10;            // vertical drop across ramp_len (controls slope)
ramp_wall_h = 10;          // side wall height on the ramp insert
ramp_tongue_th = 3;        // tongue thickness (Z)
ramp_tongue_len = 12;      // tongue depth (Y)
ramp_tongue_clear = 0.25;  // clearance so it slides nicely

// Slot position: back of storage section (where loading section begins)
slot_y0 = compartment_depth + wall*2 - ramp_tongue_len;
slot_z0 = compartment_height + wall; // top of storage shell

module base_with_slot(){
    // Base = storage + loading, but cut a slot to accept the ramp tongue.
    difference(){
        union(){
            storage_section();
            loading_section();
        }

        // Slot cut (a shallow pocket in the top surface)
        translate([0, slot_y0, slot_z0]){
            cube([total_width, ramp_tongue_len, ramp_tongue_th + 2], center=false);
        }
    }
}

module ramp_insert(){
    // Prints as a simple wedge (support-free).
    // Orientation: print with the large flat bottom on the bed.
    ramp_w = total_width;
    ramp_y = ramp_len;
    ramp_h0 = loading_height;          // high end
    ramp_h1 = loading_height - ramp_drop; // low end

    // main wedge body (polyhedron)
    // Coordinates are local; we will place it at assembly time.
    polyhedron(
      points=[
        [0,0,0],        [ramp_w,0,0],
        [ramp_w,ramp_y,0],[0,ramp_y,0],

        [0,0,ramp_h0],      [ramp_w,0,ramp_h0],
        [ramp_w,ramp_y,ramp_h1],[0,ramp_y,ramp_h1]
      ],
      faces=[
        [0,1,2,3],      // bottom
        [4,7,6,5],      // top (sloped)
        [0,4,5,1],      // back (high end)
        [1,5,6,2],      // right
        [2,6,7,3],      // front (low end)
        [3,7,4,0]       // left
      ]
    );

    // add side walls (vertical = support-free)
    translate([0,0,0])
      difference(){
        // outer shell
        cube([ramp_w, ramp_y, ramp_wall_h], center=false);
        // hollow middle, leaving perimeter walls
        translate([wall, wall, -1])
          cube([ramp_w-2*wall, ramp_y-wall, ramp_wall_h+2], center=false);
      }

    // tongue that slides into base slot (prints with no supports)
    translate([0, -ramp_tongue_len, 0])
      cube([ramp_w, ramp_tongue_len, ramp_tongue_th], center=false);
}

module pusher(){
    // Separate pusher/spatula – keep it out of the base so you never need supports for it.
    blade_w = total_width;
    blade_l = 90;
    blade_t = 2.0;

    handle_w = 22;
    handle_l = 75;
    handle_h = 12;

    union(){
      cube([blade_w, blade_l, blade_t], center=false);
      translate([blade_w/2-handle_w/2, blade_l-15, blade_t])
        minkowski(){
          cube([handle_w-6, handle_l-6, handle_h], center=false);
          cylinder(r=3, h=0.01, $fn=32);
        }
    }
}

module assemble_one_piece_with_supports(){
    // Old behavior: includes a built-in ramp volume.
    // Kept for reference, but expect supports in slicer.
    union(){
      storage_section();
      loading_section();
      // Legacy ramp call (if you want to keep it, add your old ramp_section() here)
      // ramp_section();
    }
}

// Assembly view helper (base + ramp positioned)
module assembly_preview(){
    base_with_slot();
    // place ramp so tongue slides into slot; wedge starts at slot_y0
    translate([0, slot_y0 + ramp_tongue_clear, slot_z0 + 0.01])
      ramp_insert();
}

// Selector
if(part=="base") base_with_slot();
else if(part=="ramp") ramp_insert();
else if(part=="pusher") pusher();
else if(part=="lid") storage_lid();
else if(part=="all_one_piece") assemble_one_piece_with_supports();
else assembly_preview();


module storage_section() {
    difference() {
        // Outer shell
        cube([total_width, compartment_depth + wall * 2, compartment_height + wall]);

        // Cut out compartments for each day
        for (i = [0:days-1]) {
            translate([wall + i * (compartment_width + wall), wall, wall]) {
                cube([compartment_width, compartment_depth, compartment_height + 1]);
            }
        }
    }

    // Add embossed day labels on front face (raised text)
    for (i = [0:days-1]) {
        translate([wall + i * (compartment_width + wall) + compartment_width/2,
                   label_depth - 0.01,
                   compartment_height * 0.7]) {
            rotate([90, 0, 0]) {
                linear_extrude(height = label_depth) {
                    text(day_labels_short[i], size = label_font_size,
                         halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
                }
            }
        }
    }

    // Add embossed day labels on bottom inside of each compartment
    for (i = [0:days-1]) {
        translate([wall + i * (compartment_width + wall) + compartment_width/2,
                   wall + compartment_depth/2,
                   wall + label_depth - 0.01]) {
            linear_extrude(height = label_depth) {
                text(day_labels_short[i], size = label_font_size,
                     halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
            }
        }
    }
}

module loading_section() {
    channel_section_depth = pill_types * (pill_slot_depth + wall) + wall;

    translate([0, compartment_depth + wall * 2, 0]) {
        difference() {
            // Outer shell of loading section
            cube([total_width, channel_section_depth, loading_height]);

            // Cut channels for each pill type row
            for (row = [0:pill_types-1]) {
                for (col = [0:days-1]) {
                    translate([wall + col * (compartment_width + wall) + (compartment_width - pill_slot_width)/2,
                               wall + row * (pill_slot_depth + wall),
                               wall]) {
                        cube([pill_slot_width, pill_slot_depth, loading_height]);
                    }
                }
            }
        }

        // Embossed row number labels on the left side
        for (row = [0:pill_types-1]) {
            translate([label_depth - 0.01,
                       wall + row * (pill_slot_depth + wall) + pill_slot_depth/2,
                       loading_height/2]) {
                rotate([90, 0, 90]) {
                    linear_extrude(height = label_depth) {
                        text(str(row + 1), size = pill_label_font_size,
                             halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
                    }
                }
            }
        }

        // Embossed row number labels on the right side (mirrored)
        for (row = [0:pill_types-1]) {
            translate([total_width - label_depth + 0.01,
                       wall + row * (pill_slot_depth + wall) + pill_slot_depth/2,
                       loading_height/2]) {
                rotate([90, 0, -90]) {
                    linear_extrude(height = label_depth) {
                        text(str(row + 1), size = pill_label_font_size,
                             halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
                    }
                }
            }
        }

        // Day column headers at the back of loading section
        for (col = [0:days-1]) {
            translate([wall + col * (compartment_width + wall) + compartment_width/2,
                       channel_section_depth - label_depth + 0.01,
                       loading_height/2]) {
                rotate([90, 0, 0]) {
                    linear_extrude(height = label_depth) {
                        text(day_labels_short[col], size = pill_label_font_size,
                             halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
                    }
                }
            }
        }
    }
}

module storage_lid() {
    lid_clearance = 0.3;

    // Lid base
    cube([total_width + wall * 2, compartment_depth + wall * 4, wall]);

    // Lip that fits into compartments
    translate([wall + lid_clearance, wall + lid_clearance, wall]) {
        difference() {
            cube([total_width - lid_clearance * 2, compartment_depth + wall * 2 - lid_clearance * 2, 5]);

            // Hollow out to save material
            translate([wall, wall, -1]) {
                cube([total_width - wall * 2 - lid_clearance * 2,
                      compartment_depth + wall * 2 - wall * 2 - lid_clearance * 2,
                      7]);
            }
        }
    }

    // Handle/grip
    translate([total_width/2, compartment_depth/2 + wall * 2, 0]) {
        translate([-20, -5, 0])
            cube([40, 10, wall + 3]);
    }
}
