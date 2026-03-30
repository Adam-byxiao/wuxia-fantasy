# Terrain Noise Shader
# 用于程序化地形着色的 shader

shader_type canvas_item;

uniform float time : hint_range(0.0, 10.0) = 0.0;
uniform float noise_scale : hint_range(0.001, 0.1) = 0.02;
uniform vec3 terrain_color_base : source_color = vec3(0.3, 0.5, 0.2);
uniform vec3 terrain_color_high : source_color = vec3(0.5, 0.7, 0.3);
uniform vec3 terrain_color_low : source_color = vec3(0.15, 0.25, 0.1);
uniform float height_scale : hint_range(0.0, 1.0) = 0.5;
uniform int noise_octaves : hint_range(1, 8) = 4;
uniform float noise_persistence : hint_range(0.0, 1.0) = 0.5;
uniform float noise_lacunarity : hint_range(1.0, 4.0) = 2.0;

// 简化的 Simplex 噪声近似
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 分形布朗运动 (FBM)
float fbm(vec2 p, int octaves, float persistence, float lacunarity) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float max_value = 0.0;

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        max_value += amplitude;
        amplitude *= persistence;
        frequency *= lacunarity;
    }

    return value / max_value;
}

void fragment() {
    vec2 uv = UV * noise_scale * 100.0;

    // 使用 FBM 生成噪声
    float n = fbm(uv + TIME * 0.01, noise_octaves, noise_persistence, noise_lacunarity);

    // 根据噪声值混合颜色
    vec3 color;
    if (n > height_scale) {
        color = mix(terrain_color_base, terrain_color_high, (n - height_scale) / (1.0 - height_scale));
    } else {
        color = mix(terrain_color_low, terrain_color_base, n / height_scale);
    }

    // 添加轻微的时间动画（水面、波纹等）
    color += vec3(sin(uv.x * 0.5 + TIME) * 0.02, cos(uv.y * 0.5 + TIME) * 0.02, 0.0);

    COLOR = vec4(color, 1.0);
}
