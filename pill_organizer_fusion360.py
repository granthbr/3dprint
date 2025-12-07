# Fusion 360 Python Script
# 7-Day Pill Organizer with Slide-Channel Loading
#
# To run: In Fusion 360, go to Tools → Scripts and Add-Ins → Add-Ins tab
# Click the green + next to "My Scripts", select this file, then Run

import adsk.core, adsk.fusion, traceback
import math

def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface
        design = app.activeProduct
        rootComp = design.rootComponent

        # === PARAMETERS (adjust these to customize) ===

        # Number of days (columns)
        days = 7

        # Number of pill types (rows/channels)
        pill_types = 10

        # Pill slot dimensions (for small pills up to 10mm)
        pill_slot_width = 1.2      # cm (12mm)
        pill_slot_depth = 1.2      # cm (12mm)

        # Daily compartment dimensions (in cm for Fusion)
        compartment_width = 2.5    # cm (25mm)
        compartment_depth = 4.0    # cm (40mm)
        compartment_height = 2.5   # cm (25mm)

        # Wall thickness
        wall = 0.2                 # cm (2mm)

        # Loading section height
        loading_height = 1.5       # cm (15mm)

        # Ramp length
        ramp_length = 1.5          # cm (15mm)

        # Finger grip radius
        grip_radius = 0.8          # cm (8mm)

        # Calculated dimensions
        total_width = days * (compartment_width + wall) + wall
        channel_section_depth = pill_types * (pill_slot_depth + wall) + wall
        total_depth = compartment_depth + wall * 2 + channel_section_depth

        # Create a new component for the pill organizer
        occurrence = rootComp.occurrences.addNewComponent(adsk.core.Matrix3D.create())
        pillOrgComp = occurrence.component
        pillOrgComp.name = "Pill Organizer"

        # Get the sketches and features collections
        sketches = pillOrgComp.sketches
        features = pillOrgComp.features
        extrudes = features.extrudeFeatures

        # Get XY plane
        xyPlane = pillOrgComp.xYConstructionPlane

        # ========================================
        # STORAGE SECTION (Bottom compartments)
        # ========================================

        # Create base sketch for storage section outer shell
        storageSketch = sketches.add(xyPlane)
        storageLines = storageSketch.sketchCurves.sketchLines

        # Draw outer rectangle for storage section
        storageLines.addTwoPointRectangle(
            adsk.core.Point3D.create(0, 0, 0),
            adsk.core.Point3D.create(total_width, compartment_depth + wall * 2, 0)
        )

        # Get the profile and extrude
        storageProfile = storageSketch.profiles.item(0)
        storageExtInput = extrudes.createInput(storageProfile, adsk.fusion.FeatureOperations.NewBodyFeatureOperation)
        storageExtInput.setDistanceExtent(False, adsk.core.ValueInput.createByReal(compartment_height + wall))
        storageExt = extrudes.add(storageExtInput)
        storageBody = storageExt.bodies.item(0)
        storageBody.name = "Storage Section"

        # Cut out compartments for each day
        for i in range(days):
            # Create sketch on top of storage section
            topFace = None
            for face in storageBody.faces:
                # Find the top face
                normal = face.geometry.normal if hasattr(face.geometry, 'normal') else None
                if normal and abs(normal.z - 1.0) < 0.01:
                    bbox = face.boundingBox
                    if abs(bbox.maxPoint.z - (compartment_height + wall)) < 0.01:
                        topFace = face
                        break

            if topFace:
                cutSketch = sketches.add(topFace)
                cutLines = cutSketch.sketchCurves.sketchLines

                x_start = wall + i * (compartment_width + wall)
                y_start = wall

                cutLines.addTwoPointRectangle(
                    adsk.core.Point3D.create(x_start, y_start, 0),
                    adsk.core.Point3D.create(x_start + compartment_width, y_start + compartment_depth, 0)
                )

                cutProfile = cutSketch.profiles.item(0)
                cutExtInput = extrudes.createInput(cutProfile, adsk.fusion.FeatureOperations.CutFeatureOperation)
                cutExtInput.setDistanceExtent(False, adsk.core.ValueInput.createByReal(compartment_height))
                extrudes.add(cutExtInput)

        # ========================================
        # LOADING SECTION (Pill channels)
        # ========================================

        # Create offset plane for loading section
        planes = pillOrgComp.constructionPlanes
        planeInput = planes.createInput()
        offsetValue = adsk.core.ValueInput.createByReal(0)
        planeInput.setByOffset(xyPlane, offsetValue)

        # Create sketch for loading section
        loadingSketch = sketches.add(xyPlane)
        loadingLines = loadingSketch.sketchCurves.sketchLines

        # Draw outer rectangle for loading section (offset in Y)
        y_offset = compartment_depth + wall * 2
        loadingLines.addTwoPointRectangle(
            adsk.core.Point3D.create(0, y_offset, 0),
            adsk.core.Point3D.create(total_width, y_offset + channel_section_depth, 0)
        )

        # Extrude loading section base
        loadingProfile = loadingSketch.profiles.item(0)
        loadingExtInput = extrudes.createInput(loadingProfile, adsk.fusion.FeatureOperations.JoinFeatureOperation)
        loadingExtInput.setDistanceExtent(False, adsk.core.ValueInput.createByReal(loading_height))
        loadingExt = extrudes.add(loadingExtInput)

        # Cut pill slot channels
        for row in range(pill_types):
            for col in range(days):
                # Find top face of loading section
                topZ = loading_height

                slotSketch = sketches.add(xyPlane)
                slotLines = slotSketch.sketchCurves.sketchLines

                x_start = wall + col * (compartment_width + wall) + (compartment_width - pill_slot_width) / 2
                y_start = y_offset + wall + row * (pill_slot_depth + wall)

                slotLines.addTwoPointRectangle(
                    adsk.core.Point3D.create(x_start, y_start, 0),
                    adsk.core.Point3D.create(x_start + pill_slot_width, y_start + pill_slot_depth, 0)
                )

                slotProfile = slotSketch.profiles.item(0)
                slotExtInput = extrudes.createInput(slotProfile, adsk.fusion.FeatureOperations.CutFeatureOperation)
                slotExtInput.setDistanceExtent(False, adsk.core.ValueInput.createByReal(loading_height - wall))

                # Start from top
                startFrom = adsk.fusion.FromEntityStartDefinition.create(xyPlane, adsk.core.ValueInput.createByReal(loading_height))
                slotExtInput.startExtent = startFrom

                extrudes.add(slotExtInput)

        # ========================================
        # RAMP SECTION (Connects loading to storage)
        # ========================================

        # Create sketch for ramp base
        rampSketch = sketches.add(xyPlane)
        rampLines = rampSketch.sketchCurves.sketchLines

        ramp_y_start = compartment_depth + wall * 2 - ramp_length
        rampLines.addTwoPointRectangle(
            adsk.core.Point3D.create(0, ramp_y_start, 0),
            adsk.core.Point3D.create(total_width, ramp_y_start + ramp_length, 0)
        )

        # Extrude ramp section from top of storage
        rampProfile = rampSketch.profiles.item(0)
        rampExtInput = extrudes.createInput(rampProfile, adsk.fusion.FeatureOperations.JoinFeatureOperation)

        # Start from top of storage section
        startFrom = adsk.fusion.FromEntityStartDefinition.create(xyPlane, adsk.core.ValueInput.createByReal(compartment_height + wall))
        rampExtInput.startExtent = startFrom
        rampExtInput.setDistanceExtent(False, adsk.core.ValueInput.createByReal(loading_height))
        extrudes.add(rampExtInput)

        # ========================================
        # FINGER GRIPS (Front cutouts)
        # ========================================

        # Create finger grip cutouts on front face
        for i in range(days):
            # Create a sketch on XZ plane for circular cutout
            xzPlane = pillOrgComp.xZConstructionPlane
            gripSketch = sketches.add(xzPlane)
            circles = gripSketch.sketchCurves.sketchCircles

            center_x = wall + i * (compartment_width + wall) + compartment_width / 2
            center_z = compartment_height + wall - grip_radius + 0.2

            circles.addByCenterRadius(
                adsk.core.Point3D.create(center_x, center_z, 0),
                grip_radius
            )

            gripProfile = gripSketch.profiles.item(0)
            gripExtInput = extrudes.createInput(gripProfile, adsk.fusion.FeatureOperations.CutFeatureOperation)
            gripExtInput.setDistanceExtent(False, adsk.core.ValueInput.createByReal(wall + 0.1))
            extrudes.add(gripExtInput)

        # ========================================
        # DONE
        # ========================================

        ui.messageBox(f'Pill Organizer created successfully!\n\n' +
                      f'Dimensions:\n' +
                      f'Width: {total_width * 10:.1f}mm\n' +
                      f'Depth: {total_depth * 10:.1f}mm\n' +
                      f'Height: {(compartment_height + wall + loading_height) * 10:.1f}mm\n\n' +
                      f'Note: Text labels need to be added manually using Fusion 360\'s Text tool.')

    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))

def stop(context):
    pass
