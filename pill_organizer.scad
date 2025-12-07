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

// Loading channel section with guide walls
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

// Ramp section to guide pills from loading area to compartments
module ramp_section() {
    ramp_length = 15;
    ramp_height = loading_height;

    translate([0, compartment_depth + wall * 2 - ramp_length, compartment_height + wall]) {
        difference() {
            // Ramp base
            cube([total_width, ramp_length, ramp_height]);

            // Cut angled channels for each day
            for (i = [0:days-1]) {
                translate([wall + i * (compartment_width + wall), -1, -1]) {
                    // Angled cut for the ramp
                    hull() {
                        translate([0, 0, 0])
                            cube([compartment_width, 1, ramp_height + 2]);
                        translate([0, ramp_length + 1, ramp_height - 5])
                            cube([compartment_width, 1, 5]);
                    }
                }
            }
        }
    }
}

// Finger grip cutouts on the front for easy pill removal
module finger_grips() {
    grip_radius = 8;
    for (i = [0:days-1]) {
        translate([wall + i * (compartment_width + wall) + compartment_width/2,
                   -1,
                   compartment_height + wall - grip_radius + 2]) {
            rotate([-90, 0, 0]) {
                cylinder(h = wall + 2, r = grip_radius, $fn = 32);
            }
        }
    }
}

// Optional lid for the storage section
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

// === ASSEMBLY ===

// Main organizer
module pill_organizer() {
    difference() {
        union() {
            storage_section();
            loading_section();
            ramp_section();
        }
        finger_grips();
    }
}

// === RENDER OPTIONS ===
// Uncomment the part you want to render/export

// Full assembled organizer (main part)
pill_organizer();

// Optional: Storage lid (print separately)
// Uncomment the next line to render just the lid
// translate([0, -60, 0]) storage_lid();

// === PRINT SETTINGS RECOMMENDATIONS ===
// Layer height: 0.2mm
// Infill: 15-20%
// Walls: 3 perimeters
// Support: Not needed if printed in this orientation
// Brim: Recommended for bed adhesion

echo("=== DIMENSIONS ===");
echo(str("Total Width: ", total_width, "mm"));
echo(str("Total Depth: ", total_depth, "mm"));
echo(str("Total Height: ", compartment_height + wall + loading_height, "mm"));
echo("=================");
