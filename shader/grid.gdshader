shader_type spatial;

// Uniforms for customization
uniform float grid_size = 1.0; // Size of each grid cell
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Grid line color, default black
uniform vec4 background_color : source_color = vec4(1.0, 1.0, 1.0, 0.0); // Background color, default transparent
uniform float line_width = 0.02; // Adjust line thickness
uniform vec2 mouse_pos = vec2(0.5, 0.5); // Mouse position (normalized screen space)
uniform float radius = 0.03; // Radius of the circle around the mouse where the grid is shown

void fragment() {
    // Calculate distance from current fragment to mouse position
    float distance_from_mouse = distance(UV, mouse_pos);

    // Only show the grid within the specified radius around the mouse
    if (distance_from_mouse < radius) {
        vec2 grid_position = mod(UV * grid_size, 1.0);

        // Determine the color based on grid position and line width
        if (grid_position.x < line_width || grid_position.y < line_width) {
            ALBEDO = line_color.rgb;
            ALPHA = line_color.a;
        } else {
            ALBEDO = background_color.rgb;
            ALPHA = background_color.a;
        }
    } else {
        // Outside the radius, render background color (invisible or transparent)
        ALBEDO = background_color.rgb;
        ALPHA = background_color.a;
    }
}
