import struct

def generate_pill_ramp_stl(filename="weekly_pill_ramp.stl"):
    """
    Generates a 3D printable STL file for a Weekly Pill Sorting Ramp.
    Design: A solid wedge with a flat sorting tray at the top and 7 channels 
    leading down to the exits.
    
    Dimensions:
    - Total Width: ~226mm (7 channels * 30mm + walls)
    - Ramp Length: 100mm
    - Tray Length: 60mm
    - Height: Slopes from 10mm (front) to 40mm (back)
    """
    
    # --- Configuration ---
    num_channels = 7
    channel_width = 30.0  # mm
    wall_thickness = 2.0  # mm
    
    ramp_length = 100.0   # Length of the sloped part
    tray_length = 60.0    # Length of the flat top area
    
    front_height = 5.0    # Height of floor at exit
    back_height = 45.0    # Height of floor at tray
    wall_height = 12.0    # Height of walls above the floor
    
    # Calculate totals
    total_width = (num_channels * channel_width) + ((num_channels + 1) * wall_thickness)
    total_depth = ramp_length + tray_length
    
    triangles = []

    # --- Helper Functions ---
    def add_triangle(v1, v2, v3):
        # Normal calculation (simplified, assumes CCW winding)
        # For a valid STL, we usually need normals, but slicers often re-calc them.
        # We'll just write 0,0,0 for normal as many simple generators do.
        triangles.append((v1, v2, v3))

    def add_quad(p1, p2, p3, p4):
        """Adds two triangles for a quad (CCW order: p1, p2, p3, p4)"""
        add_triangle(p1, p2, p3)
        add_triangle(p1, p3, p4)

    def add_block(x, y, z, w, d, h):
        """Adds a simple rectangular block (cuboid)"""
        # Vertices
        v0 = (x, y, z)
        v1 = (x+w, y, z)
        v2 = (x+w, y+d, z)
        v3 = (x, y+d, z)
        v4 = (x, y, z+h)
        v5 = (x+w, y, z+h)
        v6 = (x+w, y+d, z+h)
        v7 = (x, y+d, z+h)
        
        # Faces
        add_quad(v0, v3, v2, v1) # Bottom
        add_quad(v4, v5, v6, v7) # Top
        add_quad(v0, v1, v5, v4) # Front
        add_quad(v1, v2, v6, v5) # Right
        add_quad(v2, v3, v7, v6) # Back
        add_quad(v3, v0, v4, v7) # Left

    # --- Geometry Generation ---

    # 1. The Main Wedge "Floor" (The solid base)
    # We build this as a solid polyhedron
    # Vertices for the floor surface
    # Front (y=0)
    f_bl = (0, 0, 0)
    f_br = (total_width, 0, 0)
    f_tl = (0, 0, front_height)
    f_tr = (total_width, 0, front_height)
    
    # Back of Ramp / Start of Tray (y=ramp_length)
    m_bl = (0, ramp_length, 0)
    m_br = (total_width, ramp_length, 0)
    m_tl = (0, ramp_length, back_height)
    m_tr = (total_width, ramp_length, back_height)
    
    # Back of Tray (y=total_depth)
    b_bl = (0, total_depth, 0)
    b_br = (total_width, total_depth, 0)
    b_tl = (0, total_depth, back_height)
    b_tr = (total_width, total_depth, back_height)

    # Add Floor Sections
    # Ramp Section
    add_quad(f_bl, m_bl, m_br, f_br) # Bottom
    add_quad(f_tl, f_tr, m_tr, m_tl) # Top Surface (Slope)
    add_quad(f_bl, f_br, f_tr, f_tl) # Front Face
    add_quad(f_bl, f_tl, m_tl, m_bl) # Left Side (base)
    add_quad(f_br, m_br, m_tr, f_tr) # Right Side (base)
    
    # Tray Section (Flat)
    add_quad(m_bl, b_bl, b_br, m_br) # Bottom
    add_quad(m_tl, m_tr, b_tr, b_tl) # Top Surface (Flat)
    add_quad(b_bl, b_tl, b_tr, b_br) # Back Face
    add_quad(m_bl, m_tl, b_tl, b_bl) # Left Side
    add_quad(m_br, b_br, b_tr, m_tr) # Right Side

    # 2. Walls and Dividers
    # We will simply place blocks on top of the floor surface.
    # To handle the slope, we'll intersect or just place them carefully.
    # Actually, for the ramp dividers, they need to be wedges too.
    
    def add_ramp_wall(x_start, thickness):
        """Adds a wall that follows the ramp profile"""
        # Wall Coords
        x1 = x_start
        x2 = x_start + thickness
        
        # Front (y=0) z is front_height
        # Mid (y=ramp_length) z is back_height
        
        # Vertices
        # Bottoms (sits on the floor)
        w_f_bl = (x1, 0, front_height)
        w_f_br = (x2, 0, front_height)
        w_m_bl = (x1, ramp_length, back_height)
        w_m_br = (x2, ramp_length, back_height)
        
        # Tops (floor + wall_height)
        w_f_tl = (x1, 0, front_height + wall_height)
        w_f_tr = (x2, 0, front_height + wall_height)
        w_m_tl = (x1, ramp_length, back_height + wall_height)
        w_m_tr = (x2, ramp_length, back_height + wall_height)
        
        # Build the wedge-shaped wall
        add_quad(w_f_bl, w_f_br, w_m_br, w_m_bl) # Bottom (hidden)
        add_quad(w_f_tl, w_m_tl, w_m_tr, w_f_tr) # Top
        add_quad(w_f_bl, w_f_tl, w_f_tr, w_f_br) # Front
        add_quad(w_m_bl, w_m_br, w_m_tr, w_m_tl) # Back (internal face)
        add_quad(w_f_bl, w_m_bl, w_m_tl, w_f_tl) # Left
        add_quad(w_f_br, w_f_tr, w_m_tr, w_m_br) # Right

    def add_tray_wall(x_start, thickness, length):
        """Adds a rectangular wall for the tray area"""
        # Simple block
        add_block(x_start, ramp_length, back_height, thickness, length, wall_height)

    # Generate Walls
    # Outer Left Wall
    add_ramp_wall(0, wall_thickness)
    add_tray_wall(0, wall_thickness, tray_length)
    
    # Outer Right Wall
    add_ramp_wall(total_width - wall_thickness, wall_thickness)
    add_tray_wall(total_width - wall_thickness, wall_thickness, tray_length)
    
    # Internal Dividers (Only on the ramp section!)
    for i in range(1, num_channels):
        x_pos = (wall_thickness * i) + (channel_width * i)
        add_ramp_wall(x_pos, wall_thickness)
        # Note: We do NOT add tray walls for dividers, creating the open "sorting area"
        
    # Back Wall (closes the tray)
    add_block(0, total_depth, back_height, total_width, wall_thickness, wall_height)


    # --- Write Binary STL ---
    print(f"Generating STL: {len(triangles)} triangles...")
    with open(filename, 'wb') as f:
        # Header (80 bytes)
        f.write(b'Weekly Pill Ramp - Generated by Python'.ljust(80, b'\0'))
        # Triangle count (4 bytes unsigned int)
        f.write(struct.pack('<I', len(triangles)))
        
        # Triangles
        for t in triangles:
            # Normal (3 floats) - 0.0 for now
            f.write(struct.pack('<3f', 0.0, 0.0, 0.0))
            # Vertex 1, 2, 3
            for v in t:
                f.write(struct.pack('<3f', *v))
            # Attribute byte count (2 bytes)
            f.write(struct.pack('<H', 0))
            
    print(f"Done! Saved to {filename}")

if __name__ == "__main__":
    generate_pill_ramp_stl()