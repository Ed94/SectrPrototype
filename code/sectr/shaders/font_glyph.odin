/*
    #version:1# (machine generated, don't edit!)

    Generated by sokol-shdc (https://github.com/floooh/sokol-tools)

    Cmdline:
        sokol-shdc --input C:\projects\SectrPrototype\code\sectr\shaders\font_glyph.shdc.glsl --output C:\projects\SectrPrototype\code\sectr\shaders\font_glyph.odin --slang hlsl5 --format=sokol_odin

    Overview:
    =========
    Shader program: 'font_glyph':
        Get shader desc: font_glyph_shader_desc(sg.query_backend())
        Vertex shader: font_glyph_vs
            Attributes:
                ATTR_font_glyph_vs_vertex => 0
                ATTR_font_glyph_vs_texture_coord => 1
            Uniform block 'font_glyph_vs_params':
                Odin struct: Font_Glyph_Vs_Params
                Bind slot: SLOT_font_glyph_vs_params => 0
        Fragment shader: font_glyph_fs
            Uniform block 'font_glyph_fs_params':
                Odin struct: Font_Glyph_Fs_Params
                Bind slot: SLOT_font_glyph_fs_params => 0
            Image 'glyph_bitmap':
                Image type: ._2D
                Sample type: .FLOAT
                Multisampled: false
                Bind slot: SLOT_glyph_bitmap => 0
            Sampler 'glyph_bitmap_sampler':
                Type: .FILTERING
                Bind slot: SLOT_glyph_bitmap_sampler => 0
            Image Sampler Pair 'glyph_bitmap_glyph_bitmap_sampler':
                Image: glyph_bitmap
                Sampler: glyph_bitmap_sampler
*/
package sectr
import sg "thirdparty:sokol/gfx"

ATTR_font_glyph_vs_vertex        :: 0
ATTR_font_glyph_vs_texture_coord :: 1

SLOT_font_glyph_vs_params :: 0
SLOT_font_glyph_fs_params :: 0
SLOT_glyph_bitmap         :: 0
SLOT_glyph_bitmap_sampler :: 0

Font_Glyph_Vs_Params :: struct #align(16) {
    using _: struct #packed {
        projection: [16]f32,
    },
}
Font_Glyph_Fs_Params :: struct #align(16) {
    using _: struct #packed {
        glyph_color: [3]f32,
        _: [4]u8,
    },
}
/*
    cbuffer font_glyph_vs_params : register(b0)
    {
        row_major float4x4 _19_projection : packoffset(c0);
    };


    static float4 gl_Position;
    static float2 vertex;
    static float2 uv;
    static float2 texture_coord;

    struct SPIRV_Cross_Input
    {
        float2 vertex : TEXCOORD0;
        float2 texture_coord : TEXCOORD1;
    };

    struct SPIRV_Cross_Output
    {
        float2 uv : TEXCOORD0;
        float4 gl_Position : SV_Position;
    };

    void vert_main()
    {
        gl_Position = mul(float4(vertex, 0.0f, 1.0f), _19_projection);
        uv = texture_coord;
    }

    SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
    {
        vertex = stage_input.vertex;
        texture_coord = stage_input.texture_coord;
        vert_main();
        SPIRV_Cross_Output stage_output;
        stage_output.gl_Position = gl_Position;
        stage_output.uv = uv;
        return stage_output;
    }
*/
@(private)
font_glyph_vs_source_hlsl5 := [803]u8 {
    0x63,0x62,0x75,0x66,0x66,0x65,0x72,0x20,0x66,0x6f,0x6e,0x74,0x5f,0x67,0x6c,0x79,
    0x70,0x68,0x5f,0x76,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x20,0x3a,0x20,0x72,
    0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x62,0x30,0x29,0x0a,0x7b,0x0a,0x20,0x20,
    0x20,0x20,0x72,0x6f,0x77,0x5f,0x6d,0x61,0x6a,0x6f,0x72,0x20,0x66,0x6c,0x6f,0x61,
    0x74,0x34,0x78,0x34,0x20,0x5f,0x31,0x39,0x5f,0x70,0x72,0x6f,0x6a,0x65,0x63,0x74,
    0x69,0x6f,0x6e,0x20,0x3a,0x20,0x70,0x61,0x63,0x6b,0x6f,0x66,0x66,0x73,0x65,0x74,
    0x28,0x63,0x30,0x29,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x0a,0x73,0x74,0x61,0x74,0x69,
    0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,
    0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,
    0x61,0x74,0x32,0x20,0x76,0x65,0x72,0x74,0x65,0x78,0x3b,0x0a,0x73,0x74,0x61,0x74,
    0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x3b,0x0a,0x73,0x74,
    0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x74,0x65,0x78,0x74,
    0x75,0x72,0x65,0x5f,0x63,0x6f,0x6f,0x72,0x64,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,
    0x63,0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,
    0x6e,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,
    0x32,0x20,0x76,0x65,0x72,0x74,0x65,0x78,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,0x4f,
    0x4f,0x52,0x44,0x30,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,
    0x20,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x5f,0x63,0x6f,0x6f,0x72,0x64,0x20,0x3a,
    0x20,0x54,0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x31,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,
    0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,
    0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,
    0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,
    0x4f,0x4f,0x52,0x44,0x30,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,
    0x34,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3a,0x20,
    0x53,0x56,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x7d,0x3b,0x0a,
    0x0a,0x76,0x6f,0x69,0x64,0x20,0x76,0x65,0x72,0x74,0x5f,0x6d,0x61,0x69,0x6e,0x28,
    0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,
    0x69,0x6f,0x6e,0x20,0x3d,0x20,0x6d,0x75,0x6c,0x28,0x66,0x6c,0x6f,0x61,0x74,0x34,
    0x28,0x76,0x65,0x72,0x74,0x65,0x78,0x2c,0x20,0x30,0x2e,0x30,0x66,0x2c,0x20,0x31,
    0x2e,0x30,0x66,0x29,0x2c,0x20,0x5f,0x31,0x39,0x5f,0x70,0x72,0x6f,0x6a,0x65,0x63,
    0x74,0x69,0x6f,0x6e,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x75,0x76,0x20,0x3d,0x20,
    0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x5f,0x63,0x6f,0x6f,0x72,0x64,0x3b,0x0a,0x7d,
    0x0a,0x0a,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,
    0x74,0x70,0x75,0x74,0x20,0x6d,0x61,0x69,0x6e,0x28,0x53,0x50,0x49,0x52,0x56,0x5f,
    0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x20,0x73,0x74,0x61,0x67,
    0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x76,
    0x65,0x72,0x74,0x65,0x78,0x20,0x3d,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,
    0x70,0x75,0x74,0x2e,0x76,0x65,0x72,0x74,0x65,0x78,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x5f,0x63,0x6f,0x6f,0x72,0x64,0x20,0x3d,0x20,
    0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,0x74,0x65,0x78,0x74,
    0x75,0x72,0x65,0x5f,0x63,0x6f,0x6f,0x72,0x64,0x3b,0x0a,0x20,0x20,0x20,0x20,0x76,
    0x65,0x72,0x74,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,
    0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,
    0x74,0x2e,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,
    0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x2e,0x75,0x76,
    0x20,0x3d,0x20,0x75,0x76,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,0x65,0x74,0x75,0x72,
    0x6e,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,0x0a,
    0x7d,0x0a,0x00,
}
/*
    cbuffer font_glyph_fs_params : register(b0)
    {
        float3 _33_glyph_color : packoffset(c0);
    };

    Texture2D<float4> glyph_bitmap : register(t0);
    SamplerState glyph_bitmap_sampler : register(s0);

    static float2 uv;
    static float4 color;

    struct SPIRV_Cross_Input
    {
        float2 uv : TEXCOORD0;
    };

    struct SPIRV_Cross_Output
    {
        float4 color : SV_Target0;
    };

    void frag_main()
    {
        color = float4(_33_glyph_color, glyph_bitmap.Sample(glyph_bitmap_sampler, uv).x);
    }

    SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
    {
        uv = stage_input.uv;
        frag_main();
        SPIRV_Cross_Output stage_output;
        stage_output.color = color;
        return stage_output;
    }
*/
@(private)
font_glyph_fs_source_hlsl5 := [658]u8 {
    0x63,0x62,0x75,0x66,0x66,0x65,0x72,0x20,0x66,0x6f,0x6e,0x74,0x5f,0x67,0x6c,0x79,
    0x70,0x68,0x5f,0x66,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x20,0x3a,0x20,0x72,
    0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x62,0x30,0x29,0x0a,0x7b,0x0a,0x20,0x20,
    0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x33,0x20,0x5f,0x33,0x33,0x5f,0x67,0x6c,0x79,
    0x70,0x68,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3a,0x20,0x70,0x61,0x63,0x6b,0x6f,
    0x66,0x66,0x73,0x65,0x74,0x28,0x63,0x30,0x29,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x54,
    0x65,0x78,0x74,0x75,0x72,0x65,0x32,0x44,0x3c,0x66,0x6c,0x6f,0x61,0x74,0x34,0x3e,
    0x20,0x67,0x6c,0x79,0x70,0x68,0x5f,0x62,0x69,0x74,0x6d,0x61,0x70,0x20,0x3a,0x20,
    0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x74,0x30,0x29,0x3b,0x0a,0x53,0x61,
    0x6d,0x70,0x6c,0x65,0x72,0x53,0x74,0x61,0x74,0x65,0x20,0x67,0x6c,0x79,0x70,0x68,
    0x5f,0x62,0x69,0x74,0x6d,0x61,0x70,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x20,
    0x3a,0x20,0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x73,0x30,0x29,0x3b,0x0a,
    0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,
    0x76,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,
    0x20,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,
    0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,
    0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,
    0x76,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x30,0x3b,0x0a,0x7d,
    0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,
    0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,
    0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x20,
    0x3a,0x20,0x53,0x56,0x5f,0x54,0x61,0x72,0x67,0x65,0x74,0x30,0x3b,0x0a,0x7d,0x3b,
    0x0a,0x0a,0x76,0x6f,0x69,0x64,0x20,0x66,0x72,0x61,0x67,0x5f,0x6d,0x61,0x69,0x6e,
    0x28,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3d,
    0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x28,0x5f,0x33,0x33,0x5f,0x67,0x6c,0x79,0x70,
    0x68,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x2c,0x20,0x67,0x6c,0x79,0x70,0x68,0x5f,0x62,
    0x69,0x74,0x6d,0x61,0x70,0x2e,0x53,0x61,0x6d,0x70,0x6c,0x65,0x28,0x67,0x6c,0x79,
    0x70,0x68,0x5f,0x62,0x69,0x74,0x6d,0x61,0x70,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,
    0x72,0x2c,0x20,0x75,0x76,0x29,0x2e,0x78,0x29,0x3b,0x0a,0x7d,0x0a,0x0a,0x53,0x50,
    0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,
    0x20,0x6d,0x61,0x69,0x6e,0x28,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,
    0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,
    0x70,0x75,0x74,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x75,0x76,0x20,0x3d,0x20,
    0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,0x75,0x76,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x66,0x72,0x61,0x67,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,
    0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,
    0x74,0x70,0x75,0x74,0x3b,0x0a,0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,
    0x6f,0x75,0x74,0x70,0x75,0x74,0x2e,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x63,
    0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,0x65,0x74,0x75,0x72,0x6e,
    0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,0x0a,0x7d,
    0x0a,0x00,
}
font_glyph_shader_desc :: proc (backend: sg.Backend) -> sg.Shader_Desc {
    desc: sg.Shader_Desc
    desc.label = "font_glyph_shader"
    #partial switch backend {
    case .D3D11:
        desc.attrs[0].sem_name = "TEXCOORD"
        desc.attrs[0].sem_index = 0
        desc.attrs[1].sem_name = "TEXCOORD"
        desc.attrs[1].sem_index = 1

        desc.vs.source                   = transmute(cstring)&font_glyph_vs_source_hlsl5
        desc.vs.d3d11_target             = "vs_5_0"
        desc.vs.entry                    = "main"
        desc.vs.uniform_blocks[0].size   = 64
        desc.vs.uniform_blocks[0].layout = .STD140

        desc.fs.source                   = transmute(cstring)&font_glyph_fs_source_hlsl5
        desc.fs.d3d11_target             = "ps_5_0"
        desc.fs.entry                    = "main"

        desc.fs.uniform_blocks[0].size   = 16
        desc.fs.uniform_blocks[0].layout = .STD140

        desc.fs.images[0].used         = true
        desc.fs.images[0].multisampled = false
        desc.fs.images[0].image_type   = ._2D
        desc.fs.images[0].sample_type  = .FLOAT

        desc.fs.samplers[0].used         = true
        desc.fs.samplers[0].sampler_type = .FILTERING

        desc.fs.image_sampler_pairs[0].used         = true
        desc.fs.image_sampler_pairs[0].image_slot   = 0
        desc.fs.image_sampler_pairs[0].sampler_slot = 0
    }
    return desc
}
