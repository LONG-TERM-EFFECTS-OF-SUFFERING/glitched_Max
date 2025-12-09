@tool
extends GPUParticles3D

@export var spawn_radius_outer: float = 10.0  # Radio externo
@export var spawn_radius_inner: float = 3.5  # Radio interno (nuevo)
@export var height: float = 16.0
@export var particles_per_second: float = 4.0
@export var line_lifetime: float = 8.0
@export var line_thickness: float = 0.04
@export var color_top: Color = Color(0.4, 0.9, 1.0, 0.132)
@export var color_bottom: Color = Color(0.0, 0.8, 1.0, 0.8)

func _ready() -> void:
	one_shot = false
	emitting = true
	lifetime = line_lifetime
	amount = int(particles_per_second * line_lifetime)
	preprocess = 0.5
	
	visibility_aabb = AABB(Vector3(-spawn_radius_outer, 0, -spawn_radius_outer), Vector3(spawn_radius_outer * 2.0, height * 3.0, spawn_radius_outer * 2.0))

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.UP
	mat.spread = 0.0
	mat.gravity = Vector3.ZERO
	
	# Emisión en anillo (entre radio interno y externo)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_axis = Vector3.UP
	mat.emission_ring_height = 0.0
	mat.emission_ring_radius = spawn_radius_outer
	mat.emission_ring_inner_radius = spawn_radius_inner  # Radio interno
	
	mat.initial_velocity_min = height / line_lifetime
	mat.initial_velocity_max = height / line_lifetime
	mat.orbit_velocity_min = 0.0
	mat.orbit_velocity_max = 0.0
	mat.linear_accel_min = 0.0
	mat.linear_accel_max = 0.0
	mat.radial_accel_min = 0.0
	mat.radial_accel_max = 0.0
	mat.tangential_accel_min = 0.0
	mat.tangential_accel_max = 0.0
	mat.scale_min = line_thickness
	mat.scale_max = line_thickness
	mat.hue_variation_min = -0.02
	mat.hue_variation_max = 0.02
	mat.color_ramp = _make_ramp()

	process_material = mat

	var quad := QuadMesh.new()
	quad.size = Vector2(line_thickness * 3.0, height * 2.5)
	draw_pass_1 = quad

	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = _create_particle_shader()
	material_override = shader_mat

func _create_particle_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform sampler2D color_ramp;
uniform vec3 emission_color : source_color = vec3(0.0, 1.0, 1.0);
uniform float emission_energy = 2.5;

float get_scale_y(float life_percent) {
    if (life_percent < 0.2) {
        return smoothstep(0.0, 0.2, life_percent);
    } else if (life_percent < 0.8) {
        return 1.0;
    } else {
        return smoothstep(1.0, 0.8, life_percent);
    }
}

void vertex() {
    vec3 cam_pos = INV_VIEW_MATRIX[3].xyz;
    vec3 particle_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 to_camera = normalize(cam_pos - particle_pos);
    
    to_camera.y = 0.0;
    to_camera = normalize(to_camera);
    
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, to_camera));
    
    float life = COLOR.a;
    float scale_y = get_scale_y(1.0 - INSTANCE_CUSTOM.y);
    
    vec3 local_pos = VERTEX;
    local_pos.y *= scale_y;
    VERTEX = right * local_pos.x + up * local_pos.y;
    
    UV = UV;
}

void fragment() {
    vec4 base_color = vec4(emission_color, 1.0);
    ALBEDO = base_color.rgb * COLOR.rgb;
    ALPHA = COLOR.a;
    EMISSION = emission_color * emission_energy;
}
"""
	return shader

func _make_ramp() -> GradientTexture1D:
	var g := Gradient.new()
	g.add_point(0.0, Color(color_bottom.r, color_bottom.g, color_bottom.b, 0.0))
	g.add_point(0.15, color_bottom)
	g.add_point(0.5, Color(0.2, 0.95, 1.0, 1.0))
	g.add_point(0.85, color_top)
	g.add_point(1.0, Color(color_top.r, color_top.g, color_top.b, 0.0))
	
	var tex := GradientTexture1D.new()
	tex.gradient = g
	return tex
