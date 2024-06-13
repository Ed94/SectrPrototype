package sectr
import sg "thirdparty:sokol/gfx"
/*
    #version:1# (machine generated, don't edit!)

    Generated by sokol-shdc (https://github.com/floooh/sokol-tools)

    Cmdline:
        sokol-shdc --input C:\projects\SectrPrototype\code\sectr\shaders\ve_draw_text.shdc.glsl --output C:\projects\SectrPrototype\code\sectr\shaders\ve_draw_text.odin --slang glsl410:hlsl5 --format=sokol_odin --module =vefc_draw_text

    Overview:
    =========
    Shader program: 've_draw_text':
        Get shader desc: ve_draw_text_shader_desc(sg.query_backend())
        Vertex shader: ve_draw_text_vs
            Attributes:
                ATTR_ve_draw_text_vs_v_position => 0
                ATTR_ve_draw_text_vs_v_texture => 1
        Fragment shader: ve_draw_text_fs
            Uniform block 've_draw_text_fs_params':
                Odin struct: Ve_Draw_Text_Fs_Params
                Bind slot: SLOT_ve_draw_text_fs_params => 0
            Image 've_draw_text_src_texture':
                Image type: ._2D
                Sample type: .FLOAT
                Multisampled: false
                Bind slot: SLOT_ve_draw_text_src_texture => 0
            Sampler 've_draw_text_src_sampler':
                Type: .FILTERING
                Bind slot: SLOT_ve_draw_text_src_sampler => 0
            Image Sampler Pair 've_draw_text_src_texture_ve_draw_text_src_sampler':
                Image: ve_draw_text_src_texture
                Sampler: ve_draw_text_src_sampler
*/
ATTR_ve_draw_text_vs_v_position :: 0
ATTR_ve_draw_text_vs_v_texture :: 1
SLOT_ve_draw_text_fs_params :: 0
SLOT_ve_draw_text_src_texture :: 0
SLOT_ve_draw_text_src_sampler :: 0
Ve_Draw_Text_Fs_Params :: struct #align(16) {
    using _: struct #packed {
        down_sample: i32,
        _: [12]u8,
        colour: [4]f32,
    },
}
/*
    #version 410

    layout(location = 0) out vec2 uv;
    layout(location = 1) in vec2 v_texture;
    layout(location = 0) in vec2 v_position;

    void main()
    {
        uv = v_texture;
        gl_Position = vec4((v_position * 2.0) - vec2(1.0), 0.0, 1.0);
    }

*/
@(private)
ve_draw_text_vs_source_glsl410 := [234]u8 {
    0x23,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x20,0x34,0x31,0x30,0x0a,0x0a,0x6c,0x61,
    0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,
    0x30,0x29,0x20,0x6f,0x75,0x74,0x20,0x76,0x65,0x63,0x32,0x20,0x75,0x76,0x3b,0x0a,
    0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,
    0x3d,0x20,0x31,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,0x32,0x20,0x76,0x5f,0x74,
    0x65,0x78,0x74,0x75,0x72,0x65,0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,
    0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x30,0x29,0x20,0x69,0x6e,0x20,
    0x76,0x65,0x63,0x32,0x20,0x76,0x5f,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,
    0x0a,0x0a,0x76,0x6f,0x69,0x64,0x20,0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,
    0x20,0x20,0x20,0x20,0x75,0x76,0x20,0x3d,0x20,0x76,0x5f,0x74,0x65,0x78,0x74,0x75,
    0x72,0x65,0x3b,0x0a,0x20,0x20,0x20,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,
    0x69,0x6f,0x6e,0x20,0x3d,0x20,0x76,0x65,0x63,0x34,0x28,0x28,0x76,0x5f,0x70,0x6f,
    0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x2a,0x20,0x32,0x2e,0x30,0x29,0x20,0x2d,0x20,
    0x76,0x65,0x63,0x32,0x28,0x31,0x2e,0x30,0x29,0x2c,0x20,0x30,0x2e,0x30,0x2c,0x20,
    0x31,0x2e,0x30,0x29,0x3b,0x0a,0x7d,0x0a,0x0a,0x00,
}
/*
    #version 410

    struct ve_draw_text_fs_params
    {
        int down_sample;
        vec4 colour;
    };

    uniform ve_draw_text_fs_params _31;

    uniform sampler2D ve_draw_text_src_texture_ve_draw_text_src_sampler;

    layout(location = 0) in vec2 uv;
    layout(location = 0) out vec4 frag_color;

    void main()
    {
        float alpha = texture(ve_draw_text_src_texture_ve_draw_text_src_sampler, uv).x;
        if (uint(_31.down_sample) == 1u)
        {
            alpha = 0.25 * (((texture(ve_draw_text_src_texture_ve_draw_text_src_sampler, uv + vec2(-0.000244140625, -0.0009765625)).x + texture(ve_draw_text_src_texture_ve_draw_text_src_sampler, uv + vec2(-0.000244140625, 0.0009765625)).x) + texture(ve_draw_text_src_texture_ve_draw_text_src_sampler, uv + vec2(0.000244140625, -0.0009765625)).x) + texture(ve_draw_text_src_texture_ve_draw_text_src_sampler, uv + vec2(0.000244140625, 0.0009765625)).x);
        }
        frag_color = vec4(_31.colour.xyz, _31.colour.w * alpha);
    }

*/
@(private)
ve_draw_text_fs_source_glsl410 := [931]u8 {
    0x23,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x20,0x34,0x31,0x30,0x0a,0x0a,0x73,0x74,
    0x72,0x75,0x63,0x74,0x20,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,
    0x74,0x5f,0x66,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x0a,0x7b,0x0a,0x20,0x20,
    0x20,0x20,0x69,0x6e,0x74,0x20,0x64,0x6f,0x77,0x6e,0x5f,0x73,0x61,0x6d,0x70,0x6c,
    0x65,0x3b,0x0a,0x20,0x20,0x20,0x20,0x76,0x65,0x63,0x34,0x20,0x63,0x6f,0x6c,0x6f,
    0x75,0x72,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x75,0x6e,0x69,0x66,0x6f,0x72,0x6d,0x20,
    0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x66,0x73,0x5f,
    0x70,0x61,0x72,0x61,0x6d,0x73,0x20,0x5f,0x33,0x31,0x3b,0x0a,0x0a,0x75,0x6e,0x69,
    0x66,0x6f,0x72,0x6d,0x20,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x32,0x44,0x20,0x76,
    0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,
    0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x5f,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,
    0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,
    0x3b,0x0a,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,
    0x6f,0x6e,0x20,0x3d,0x20,0x30,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,0x32,0x20,
    0x75,0x76,0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,
    0x69,0x6f,0x6e,0x20,0x3d,0x20,0x30,0x29,0x20,0x6f,0x75,0x74,0x20,0x76,0x65,0x63,
    0x34,0x20,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x0a,0x76,
    0x6f,0x69,0x64,0x20,0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,
    0x20,0x66,0x6c,0x6f,0x61,0x74,0x20,0x61,0x6c,0x70,0x68,0x61,0x20,0x3d,0x20,0x74,
    0x65,0x78,0x74,0x75,0x72,0x65,0x28,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,
    0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x5f,
    0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,
    0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x2c,0x20,0x75,0x76,0x29,0x2e,0x78,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x69,0x66,0x20,0x28,0x75,0x69,0x6e,0x74,0x28,0x5f,0x33,
    0x31,0x2e,0x64,0x6f,0x77,0x6e,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x29,0x20,0x3d,
    0x3d,0x20,0x31,0x75,0x29,0x0a,0x20,0x20,0x20,0x20,0x7b,0x0a,0x20,0x20,0x20,0x20,
    0x20,0x20,0x20,0x20,0x61,0x6c,0x70,0x68,0x61,0x20,0x3d,0x20,0x30,0x2e,0x32,0x35,
    0x20,0x2a,0x20,0x28,0x28,0x28,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x28,0x76,0x65,
    0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x74,
    0x65,0x78,0x74,0x75,0x72,0x65,0x5f,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,
    0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x2c,
    0x20,0x75,0x76,0x20,0x2b,0x20,0x76,0x65,0x63,0x32,0x28,0x2d,0x30,0x2e,0x30,0x30,
    0x30,0x32,0x34,0x34,0x31,0x34,0x30,0x36,0x32,0x35,0x2c,0x20,0x2d,0x30,0x2e,0x30,
    0x30,0x30,0x39,0x37,0x36,0x35,0x36,0x32,0x35,0x29,0x29,0x2e,0x78,0x20,0x2b,0x20,
    0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x28,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,
    0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,
    0x5f,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,
    0x63,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x2c,0x20,0x75,0x76,0x20,0x2b,0x20,
    0x76,0x65,0x63,0x32,0x28,0x2d,0x30,0x2e,0x30,0x30,0x30,0x32,0x34,0x34,0x31,0x34,
    0x30,0x36,0x32,0x35,0x2c,0x20,0x30,0x2e,0x30,0x30,0x30,0x39,0x37,0x36,0x35,0x36,
    0x32,0x35,0x29,0x29,0x2e,0x78,0x29,0x20,0x2b,0x20,0x74,0x65,0x78,0x74,0x75,0x72,
    0x65,0x28,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,
    0x72,0x63,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x5f,0x76,0x65,0x5f,0x64,0x72,
    0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,
    0x6c,0x65,0x72,0x2c,0x20,0x75,0x76,0x20,0x2b,0x20,0x76,0x65,0x63,0x32,0x28,0x30,
    0x2e,0x30,0x30,0x30,0x32,0x34,0x34,0x31,0x34,0x30,0x36,0x32,0x35,0x2c,0x20,0x2d,
    0x30,0x2e,0x30,0x30,0x30,0x39,0x37,0x36,0x35,0x36,0x32,0x35,0x29,0x29,0x2e,0x78,
    0x29,0x20,0x2b,0x20,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x28,0x76,0x65,0x5f,0x64,
    0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,
    0x74,0x75,0x72,0x65,0x5f,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,
    0x74,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x2c,0x20,0x75,
    0x76,0x20,0x2b,0x20,0x76,0x65,0x63,0x32,0x28,0x30,0x2e,0x30,0x30,0x30,0x32,0x34,
    0x34,0x31,0x34,0x30,0x36,0x32,0x35,0x2c,0x20,0x30,0x2e,0x30,0x30,0x30,0x39,0x37,
    0x36,0x35,0x36,0x32,0x35,0x29,0x29,0x2e,0x78,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x7d,0x0a,0x20,0x20,0x20,0x20,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,
    0x20,0x3d,0x20,0x76,0x65,0x63,0x34,0x28,0x5f,0x33,0x31,0x2e,0x63,0x6f,0x6c,0x6f,
    0x75,0x72,0x2e,0x78,0x79,0x7a,0x2c,0x20,0x5f,0x33,0x31,0x2e,0x63,0x6f,0x6c,0x6f,
    0x75,0x72,0x2e,0x77,0x20,0x2a,0x20,0x61,0x6c,0x70,0x68,0x61,0x29,0x3b,0x0a,0x7d,
    0x0a,0x0a,0x00,
}
/*
    static float4 gl_Position;
    static float2 uv;
    static float2 v_texture;
    static float2 v_position;

    struct SPIRV_Cross_Input
    {
        float2 v_position : TEXCOORD0;
        float2 v_texture : TEXCOORD1;
    };

    struct SPIRV_Cross_Output
    {
        float2 uv : TEXCOORD0;
        float4 gl_Position : SV_Position;
    };

    void vert_main()
    {
        uv = v_texture;
        gl_Position = float4((v_position * 2.0f) - 1.0f.xx, 0.0f, 1.0f);
    }

    SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
    {
        v_texture = stage_input.v_texture;
        v_position = stage_input.v_position;
        vert_main();
        SPIRV_Cross_Output stage_output;
        stage_output.gl_Position = gl_Position;
        stage_output.uv = uv;
        return stage_output;
    }
*/
@(private)
ve_draw_text_vs_source_hlsl5 := [694]u8 {
    0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x67,0x6c,
    0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,
    0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x3b,0x0a,0x73,0x74,0x61,
    0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x76,0x5f,0x74,0x65,0x78,
    0x74,0x75,0x72,0x65,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,
    0x61,0x74,0x32,0x20,0x76,0x5f,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,
    0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,
    0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,
    0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x76,0x5f,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,
    0x6e,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x30,0x3b,0x0a,0x20,
    0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x76,0x5f,0x74,0x65,0x78,0x74,
    0x75,0x72,0x65,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x31,0x3b,
    0x0a,0x7d,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,0x52,
    0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x0a,0x7b,
    0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x20,0x3a,
    0x20,0x54,0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x30,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,
    0x6f,0x6e,0x20,0x3a,0x20,0x53,0x56,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,
    0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x76,0x6f,0x69,0x64,0x20,0x76,0x65,0x72,0x74,0x5f,
    0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x75,0x76,0x20,
    0x3d,0x20,0x76,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x34,0x28,0x28,0x76,0x5f,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,
    0x6e,0x20,0x2a,0x20,0x32,0x2e,0x30,0x66,0x29,0x20,0x2d,0x20,0x31,0x2e,0x30,0x66,
    0x2e,0x78,0x78,0x2c,0x20,0x30,0x2e,0x30,0x66,0x2c,0x20,0x31,0x2e,0x30,0x66,0x29,
    0x3b,0x0a,0x7d,0x0a,0x0a,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,
    0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x20,0x6d,0x61,0x69,0x6e,0x28,0x53,0x50,0x49,
    0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x20,0x73,
    0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x29,0x0a,0x7b,0x0a,0x20,0x20,
    0x20,0x20,0x76,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x20,0x3d,0x20,0x73,0x74,
    0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,0x76,0x5f,0x74,0x65,0x78,0x74,
    0x75,0x72,0x65,0x3b,0x0a,0x20,0x20,0x20,0x20,0x76,0x5f,0x70,0x6f,0x73,0x69,0x74,
    0x69,0x6f,0x6e,0x20,0x3d,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,
    0x74,0x2e,0x76,0x5f,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x20,0x20,
    0x20,0x20,0x76,0x65,0x72,0x74,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x3b,0x0a,0x20,
    0x20,0x20,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,
    0x75,0x74,0x70,0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,
    0x75,0x74,0x3b,0x0a,0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,
    0x74,0x70,0x75,0x74,0x2e,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,
    0x20,0x3d,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,
    0x2e,0x75,0x76,0x20,0x3d,0x20,0x75,0x76,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,0x65,
    0x74,0x75,0x72,0x6e,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,
    0x74,0x3b,0x0a,0x7d,0x0a,0x00,
}
/*
    cbuffer ve_draw_text_fs_params : register(b0)
    {
        int _31_down_sample : packoffset(c0);
        float4 _31_colour : packoffset(c1);
    };

    Texture2D<float4> ve_draw_text_src_texture : register(t0);
    SamplerState ve_draw_text_src_sampler : register(s0);

    static float2 uv;
    static float4 frag_color;

    struct SPIRV_Cross_Input
    {
        float2 uv : TEXCOORD0;
    };

    struct SPIRV_Cross_Output
    {
        float4 frag_color : SV_Target0;
    };

    void frag_main()
    {
        float alpha = ve_draw_text_src_texture.Sample(ve_draw_text_src_sampler, uv).x;
        if (uint(_31_down_sample) == 1u)
        {
            alpha = 0.25f * (((ve_draw_text_src_texture.Sample(ve_draw_text_src_sampler, uv + float2(-0.000244140625f, -0.0009765625f)).x + ve_draw_text_src_texture.Sample(ve_draw_text_src_sampler, uv + float2(-0.000244140625f, 0.0009765625f)).x) + ve_draw_text_src_texture.Sample(ve_draw_text_src_sampler, uv + float2(0.000244140625f, -0.0009765625f)).x) + ve_draw_text_src_texture.Sample(ve_draw_text_src_sampler, uv + float2(0.000244140625f, 0.0009765625f)).x);
        }
        frag_color = float4(_31_colour.xyz, _31_colour.w * alpha);
    }

    SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
    {
        uv = stage_input.uv;
        frag_main();
        SPIRV_Cross_Output stage_output;
        stage_output.frag_color = frag_color;
        return stage_output;
    }
*/
@(private)
ve_draw_text_fs_source_hlsl5 := [1303]u8 {
    0x63,0x62,0x75,0x66,0x66,0x65,0x72,0x20,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,
    0x74,0x65,0x78,0x74,0x5f,0x66,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x20,0x3a,
    0x20,0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x62,0x30,0x29,0x0a,0x7b,0x0a,
    0x20,0x20,0x20,0x20,0x69,0x6e,0x74,0x20,0x5f,0x33,0x31,0x5f,0x64,0x6f,0x77,0x6e,
    0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x20,0x3a,0x20,0x70,0x61,0x63,0x6b,0x6f,0x66,
    0x66,0x73,0x65,0x74,0x28,0x63,0x30,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,
    0x6f,0x61,0x74,0x34,0x20,0x5f,0x33,0x31,0x5f,0x63,0x6f,0x6c,0x6f,0x75,0x72,0x20,
    0x3a,0x20,0x70,0x61,0x63,0x6b,0x6f,0x66,0x66,0x73,0x65,0x74,0x28,0x63,0x31,0x29,
    0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x54,0x65,0x78,0x74,0x75,0x72,0x65,0x32,0x44,0x3c,
    0x66,0x6c,0x6f,0x61,0x74,0x34,0x3e,0x20,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,
    0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,
    0x20,0x3a,0x20,0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x74,0x30,0x29,0x3b,
    0x0a,0x53,0x61,0x6d,0x70,0x6c,0x65,0x72,0x53,0x74,0x61,0x74,0x65,0x20,0x76,0x65,
    0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x73,
    0x61,0x6d,0x70,0x6c,0x65,0x72,0x20,0x3a,0x20,0x72,0x65,0x67,0x69,0x73,0x74,0x65,
    0x72,0x28,0x73,0x30,0x29,0x3b,0x0a,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,
    0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,
    0x6f,0x72,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,0x52,
    0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x0a,0x7b,0x0a,
    0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x20,0x3a,0x20,
    0x54,0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x30,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x73,
    0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,
    0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x34,0x20,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,
    0x20,0x3a,0x20,0x53,0x56,0x5f,0x54,0x61,0x72,0x67,0x65,0x74,0x30,0x3b,0x0a,0x7d,
    0x3b,0x0a,0x0a,0x76,0x6f,0x69,0x64,0x20,0x66,0x72,0x61,0x67,0x5f,0x6d,0x61,0x69,
    0x6e,0x28,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x20,
    0x61,0x6c,0x70,0x68,0x61,0x20,0x3d,0x20,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,
    0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,
    0x2e,0x53,0x61,0x6d,0x70,0x6c,0x65,0x28,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,
    0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,
    0x2c,0x20,0x75,0x76,0x29,0x2e,0x78,0x3b,0x0a,0x20,0x20,0x20,0x20,0x69,0x66,0x20,
    0x28,0x75,0x69,0x6e,0x74,0x28,0x5f,0x33,0x31,0x5f,0x64,0x6f,0x77,0x6e,0x5f,0x73,
    0x61,0x6d,0x70,0x6c,0x65,0x29,0x20,0x3d,0x3d,0x20,0x31,0x75,0x29,0x0a,0x20,0x20,
    0x20,0x20,0x7b,0x0a,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x61,0x6c,0x70,0x68,
    0x61,0x20,0x3d,0x20,0x30,0x2e,0x32,0x35,0x66,0x20,0x2a,0x20,0x28,0x28,0x28,0x76,
    0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,
    0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x53,0x61,0x6d,0x70,0x6c,0x65,0x28,0x76,
    0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,
    0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x2c,0x20,0x75,0x76,0x20,0x2b,0x20,0x66,0x6c,
    0x6f,0x61,0x74,0x32,0x28,0x2d,0x30,0x2e,0x30,0x30,0x30,0x32,0x34,0x34,0x31,0x34,
    0x30,0x36,0x32,0x35,0x66,0x2c,0x20,0x2d,0x30,0x2e,0x30,0x30,0x30,0x39,0x37,0x36,
    0x35,0x36,0x32,0x35,0x66,0x29,0x29,0x2e,0x78,0x20,0x2b,0x20,0x76,0x65,0x5f,0x64,
    0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,
    0x74,0x75,0x72,0x65,0x2e,0x53,0x61,0x6d,0x70,0x6c,0x65,0x28,0x76,0x65,0x5f,0x64,
    0x72,0x61,0x77,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,
    0x70,0x6c,0x65,0x72,0x2c,0x20,0x75,0x76,0x20,0x2b,0x20,0x66,0x6c,0x6f,0x61,0x74,
    0x32,0x28,0x2d,0x30,0x2e,0x30,0x30,0x30,0x32,0x34,0x34,0x31,0x34,0x30,0x36,0x32,
    0x35,0x66,0x2c,0x20,0x30,0x2e,0x30,0x30,0x30,0x39,0x37,0x36,0x35,0x36,0x32,0x35,
    0x66,0x29,0x29,0x2e,0x78,0x29,0x20,0x2b,0x20,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,
    0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,
    0x65,0x2e,0x53,0x61,0x6d,0x70,0x6c,0x65,0x28,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,
    0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,
    0x72,0x2c,0x20,0x75,0x76,0x20,0x2b,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x28,0x30,
    0x2e,0x30,0x30,0x30,0x32,0x34,0x34,0x31,0x34,0x30,0x36,0x32,0x35,0x66,0x2c,0x20,
    0x2d,0x30,0x2e,0x30,0x30,0x30,0x39,0x37,0x36,0x35,0x36,0x32,0x35,0x66,0x29,0x29,
    0x2e,0x78,0x29,0x20,0x2b,0x20,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,
    0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x53,
    0x61,0x6d,0x70,0x6c,0x65,0x28,0x76,0x65,0x5f,0x64,0x72,0x61,0x77,0x5f,0x74,0x65,
    0x78,0x74,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x2c,0x20,
    0x75,0x76,0x20,0x2b,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x28,0x30,0x2e,0x30,0x30,
    0x30,0x32,0x34,0x34,0x31,0x34,0x30,0x36,0x32,0x35,0x66,0x2c,0x20,0x30,0x2e,0x30,
    0x30,0x30,0x39,0x37,0x36,0x35,0x36,0x32,0x35,0x66,0x29,0x29,0x2e,0x78,0x29,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x7d,0x0a,0x20,0x20,0x20,0x20,0x66,0x72,0x61,0x67,0x5f,
    0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x28,0x5f,
    0x33,0x31,0x5f,0x63,0x6f,0x6c,0x6f,0x75,0x72,0x2e,0x78,0x79,0x7a,0x2c,0x20,0x5f,
    0x33,0x31,0x5f,0x63,0x6f,0x6c,0x6f,0x75,0x72,0x2e,0x77,0x20,0x2a,0x20,0x61,0x6c,
    0x70,0x68,0x61,0x29,0x3b,0x0a,0x7d,0x0a,0x0a,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,
    0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x20,0x6d,0x61,0x69,0x6e,
    0x28,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,
    0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x29,0x0a,
    0x7b,0x0a,0x20,0x20,0x20,0x20,0x75,0x76,0x20,0x3d,0x20,0x73,0x74,0x61,0x67,0x65,
    0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,0x75,0x76,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x72,0x61,0x67,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,
    0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,
    0x74,0x2e,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x66,
    0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,
    0x65,0x74,0x75,0x72,0x6e,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,
    0x75,0x74,0x3b,0x0a,0x7d,0x0a,0x00,
}
ve_draw_text_shader_desc :: proc (backend: sg.Backend) -> sg.Shader_Desc {
    desc: sg.Shader_Desc
    desc.label = "ve_draw_text_shader"
    #partial switch backend {
    case .GLCORE:
        desc.attrs[0].name = "v_position"
        desc.attrs[1].name = "v_texture"
        desc.vs.source = transmute(cstring)&ve_draw_text_vs_source_glsl410
        desc.vs.entry = "main"
        desc.fs.source = transmute(cstring)&ve_draw_text_fs_source_glsl410
        desc.fs.entry = "main"
        desc.fs.uniform_blocks[0].size = 32
        desc.fs.uniform_blocks[0].layout = .STD140
        desc.fs.uniform_blocks[0].uniforms[0].name = "_31.down_sample"
        desc.fs.uniform_blocks[0].uniforms[0].type = .INT
        // array_count = desc.fs.uniform_blocks[0].uniforms[0]
        desc.fs.uniform_blocks[0].uniforms[1].name = "_31.colour"
        desc.fs.uniform_blocks[0].uniforms[1].type = .FLOAT4
        // array_count = desc.fs.uniform_blocks[0].uniforms[1]
        desc.fs.images[0].used = true
        desc.fs.images[0].multisampled = false
        desc.fs.images[0].image_type = ._2D
        desc.fs.images[0].sample_type = .FLOAT
        desc.fs.samplers[0].used = true
        desc.fs.samplers[0].sampler_type = .FILTERING
        desc.fs.image_sampler_pairs[0].used = true
        desc.fs.image_sampler_pairs[0].image_slot = 0
        desc.fs.image_sampler_pairs[0].sampler_slot = 0
        desc.fs.image_sampler_pairs[0].glsl_name = "ve_draw_text_src_texture_ve_draw_text_src_sampler"
    case .D3D11:
        desc.attrs[0].sem_name = "TEXCOORD"
        desc.attrs[0].sem_index = 0
        desc.attrs[1].sem_name = "TEXCOORD"
        desc.attrs[1].sem_index = 1
        desc.vs.source = transmute(cstring)&ve_draw_text_vs_source_hlsl5
        desc.vs.d3d11_target = "vs_5_0"
        desc.vs.entry = "main"
        desc.fs.source = transmute(cstring)&ve_draw_text_fs_source_hlsl5
        desc.fs.d3d11_target = "ps_5_0"
        desc.fs.entry = "main"
        desc.fs.uniform_blocks[0].size = 32
        desc.fs.uniform_blocks[0].layout = .STD140
        desc.fs.images[0].used = true
        desc.fs.images[0].multisampled = false
        desc.fs.images[0].image_type = ._2D
        desc.fs.images[0].sample_type = .FLOAT
        desc.fs.samplers[0].used = true
        desc.fs.samplers[0].sampler_type = .FILTERING
        desc.fs.image_sampler_pairs[0].used = true
        desc.fs.image_sampler_pairs[0].image_slot = 0
        desc.fs.image_sampler_pairs[0].sampler_slot = 0
    }
    return desc
}
