/*
# Parametric DIP IC test clip.

Print 2 copies to make a single test clip.

You will also require;

* Metal pins to act as the clip contacts - I used 'Gold Brass Flat Headpins 50mm x 0.7mm Jewellery Making' from ebay.
* A hinge pin. I used 2mm silver steel that I had in my scrap box.
* Springs (1 or 2 depending on the length of the test clip). I made my own using 0.8mm 'music wire' and a lathe.

I need to print with 0.1mm layer height to have enough accuracy for the clip pins to clear the holes.

Andy Anderson 2020

*/

// preview[view:south, tilt:top diagonal]

// The width in mm of the IC - this determines the hinge height.
ic_width = 8; // min: 4

// The total number of IC pins (e.g. 16 would give 8 pins per side).
ic_pin_count = 16; // min: 8

// The pitch of the IC pins in mm.
pin_pitch = 2.54; // min: 1.5

// The diameter of the clip pins in mm - make sure to add some clearance.
pin_dia = 0.95; // max: 2

// The diameter of the clip hinge pin in mm - make sure to add some clearance.
hinge_pin_dia = 2.15; // max: 6

/* [Hidden] */

// Pin count per clip side.
pin_count = ic_pin_count / 2;

// Length of clip pin relief slot.
pin_slot_length = 10;

// Max width of clip pin relief slot.
pin_slot_dia = pin_pitch*1.0;

// How tall the clip is.
base_length = 40;

// The calculated length of the clip.
base_width = (pin_count * pin_pitch) + pin_pitch;

// The amount of chamfer of the clip tip to allow socket clearance.
tip_chamfer_length = 1.5;

// The thickness of each clip half (it is wedge shaped).
base_height_t = 4.5; // top thickness
base_height_b = 3;  // bottom thickness

// Hinge dimensions - per hinge block (2 blocks per clip side).
hinge_clearance = 0.075;
hinge_width = (base_width/4)-hinge_clearance; // width of a single hinge block
hinge_thickness = 9;
hinge_pin_offset = hinge_pin_dia * 1.5;
hinge_height = (ic_width/2) + (hinge_pin_offset);

// Spring dimensions
spring_seat_height = 2;
spring_seat_wall = 1;
spring_id = 5;
spring_od = 12;


// A pyramid like shape to cut relief for a single pin.
module pin_slot()
{
    hull()
    {
        sphere(d=pin_dia);
    
        translate([-pin_slot_dia/2.2, pin_slot_length, pin_slot_dia])
            sphere(d=pin_dia);
    
        translate([pin_slot_dia/2.2, pin_slot_length, pin_slot_dia])
            sphere(d=pin_dia);

        translate([pin_dia/2.5, pin_slot_length, -pin_slot_dia])
            sphere(d=pin_dia);

        translate([-pin_dia/2.5, pin_slot_length, -pin_slot_dia])
            sphere(d=pin_dia);
    }
}

// A cutting tool to cut relief for all pins.
module pin_slots_tool()
{
    slot_y = base_length-pin_slot_length;
    slot_z = (base_height_t/2);
    
    first_pin = pin_pitch;
    
    for(pin= [0 : 1 : pin_count-1])
    {
        slot_x = first_pin+(pin*pin_pitch);

        translate([slot_x, slot_y, slot_z])
            pin_slot();
    }
}

// A tool for cutting a single pin hole the full length of the clip.
module pin_hole()
{
    rotate([-90, 0, 0])
        cylinder($fn=36, h=base_length+2, d=pin_dia, centre=true);
}

// A tool for cutting all pin holes.
module pin_holes_tool()
{
    pin_y = -1;
    pin_z = base_height_t/2;
    
    first_pin = pin_pitch;
    
    for(pin= [0 : 1 : pin_count-1])
    {
        pin_x = first_pin+(pin*pin_pitch);

        translate([pin_x, pin_y, pin_z])
            pin_hole();
    }
}

// A single hinge block.
module hinge()
{   
    // Notmalise position
    translate([hinge_width, 0, hinge_height])
    rotate([-90, 0, 90])
    {
        difference()
        {
            hull()
            {
                // Rounded end
                difference()
                {
                    translate([hinge_thickness/2, hinge_thickness/2, 0])
                      cylinder($fn=36, h=hinge_width, d=hinge_thickness);
                    
                    translate([0, hinge_thickness/2, 0])
                        cube([hinge_thickness, hinge_thickness/2, hinge_width]);
                }
                
                // main block
                translate([0, hinge_height, 0])
                    cube([hinge_thickness, 1, hinge_width]);
            }

            // make hole for hinge pin
            translate([hinge_thickness/2, hinge_pin_offset, 0])
                cylinder($fn=36, h=hinge_width+2, d=hinge_pin_dia);
        }
    }
}

// Positions the 2 hinge blocks.
module hinges()
{
    // position hinges mid-way with respect to clip height
    ypos = (base_length/2) - (hinge_thickness/2);
    
    // zpos needs to take account of the base wedge shape
    diff = base_height_t - base_height_b;
    zpos = base_height_t - (diff/2);
    
    translate([0, ypos, zpos])
    {
        hinge();
        
        translate([(hinge_width + hinge_clearance)*2, 0, 0])
            hinge();
    }
}

// A single feature to hold a spring.
module spring_seat()
{
    // normalise position
    rad = (spring_od + spring_seat_wall) / 2;
    translate([rad, rad, -2])
    {
        union()
        {
            difference()
            {
                cylinder($fn=36, h=spring_seat_height+2, d=spring_od + spring_seat_wall);
                cylinder($fn=36, h=spring_seat_height+2, d=spring_od - spring_seat_wall);
            }
            
            cylinder($fn=36, h=spring_seat_height+2, d=spring_id);
        }
    }
}


// Creates and positions the springs seats on the clip base.
module spring_seats()
{
    spring_seat_size = (spring_od + spring_seat_wall);
    
    // One seat for shorter clips, otherwise two,
    if(base_width > (spring_seat_size * 2.5))
    {
        xpos = (base_width/4)-(spring_seat_size/2);
        ypos = 1; // TODO - check for enough space
        zpos = base_height_t;
        
        translate([xpos, ypos, zpos])
            spring_seat();
        
        xpos2 = ((base_width/4)*3)-(spring_seat_size/2);
        
        translate([xpos2, ypos, zpos])
            spring_seat();
    }
    else
    {
        xpos = (base_width/2)-(spring_seat_size/2);
        ypos = 1; // TODO - check for enough space
        zpos = base_height_t;
        
        translate([xpos, ypos, zpos])
            spring_seat();
    }
}

// A tool to cut the size text into the clip base.
module size_text()
{
    text_size = 10;
    
    linear_extrude(height = 0.5)
        translate([(base_width/2)-(text_size/1.5), (base_length/2), 0])
            rotate([0, 180, 180])
                text(str(ic_pin_count), size=text_size);
}

// The basic clip shape (wedge-like).
module base()
{
    difference()
    {
        // Wedge shape
        hull()
        {
            cube([base_width, 1, base_height_t]);
            translate([0, base_length-1, 0])
                cube([base_width, 1, base_height_b]);
        }
        
        // Chamfer the bottom edge to allow clearance at the IC socket
        hull()
        {
        translate([0, base_length, 0])
            cube([base_width, 0.1, 0.1]);
        
        translate([0, base_length, base_height_b])
            cube([base_width, 0.1, 0.1]);
     
         translate([0, base_length-tip_chamfer_length, 0])
            cube([base_width, 0.1, 0.1]);   
        }
    }
}

// Combines the pin hole and pin slot tools into a single cutting tool.
module pin_space()
{
    union()
    {
        pin_holes_tool();
        pin_slots_tool();
    }
}

module clip()
{
    difference()
    {
        // Create the solids
        union()
        {
            base();
            hinges();
            spring_seats();
        }
        
        // Make the cuts
        union()
        {
            pin_space();
            size_text();
        }
    }
}

clip();



