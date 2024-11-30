package sectr
import sg "thirdparty:sokol/gfx"
/*
    #version:1# (machine generated, don't edit!)

    Generated by sokol-shdc (https://github.com/floooh/sokol-tools)

    Cmdline:
        sokol-shdc --input C:\projects\SectrPrototype\code\sectr\shaders\ve_blit_atlas.shdc.glsl --output C:\projects\SectrPrototype\code\sectr\shaders\ve_blit_atlas.odin --slang hlsl4 --format=sokol_odin --module =vefc_blit_atlas

    Overview:
    =========
    Shader program: 've_blit_atlas':
        Get shader desc: ve_blit_atlas_shader_desc(sg.query_backend())
        Vertex Shader: ve_blit_atlas_vs
        Fragment Shader: ve_blit_atlas_fs
        Attributes:
            ATTR_ve_blit_atlas_v_position => 0
            ATTR_ve_blit_atlas_v_texture => 1
    Bindings:
        Uniform block 've_blit_atlas_fs_params':
            Odin struct: Ve_Blit_Atlas_Fs_Params
            Bind slot: UB_ve_blit_atlas_fs_params => 0
        Image 've_blit_atlas_src_texture':
            Image type: ._2D
            Sample type: .FLOAT
            Multisampled: false
            Bind slot: IMG_ve_blit_atlas_src_texture => 0
        Sampler 've_blit_atlas_src_sampler':
            Type: .FILTERING
            Bind slot: SMP_ve_blit_atlas_src_sampler => 0
*/
ATTR_ve_blit_atlas_v_position :: 0
ATTR_ve_blit_atlas_v_texture  :: 1
UB_ve_blit_atlas_fs_params    :: 0
IMG_ve_blit_atlas_src_texture :: 0
SMP_ve_blit_atlas_src_sampler :: 0
Ve_Blit_Atlas_Fs_Params :: struct #align(16) {
    using _: struct #packed {
        region: i32,
        _: [12]u8,
    },
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
        uv = float2(v_texture.x, 1.0f - v_texture.y);
        gl_Position = float4(v_position, 0.0f, 1.0f);
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
@(private="file")
ve_blit_atlas_vs_source_hlsl4 := [705]u8 {
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
    0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x28,0x76,0x5f,0x74,0x65,0x78,0x74,0x75,
    0x72,0x65,0x2e,0x78,0x2c,0x20,0x31,0x2e,0x30,0x66,0x20,0x2d,0x20,0x76,0x5f,0x74,
    0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x79,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x67,
    0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x66,0x6c,0x6f,
    0x61,0x74,0x34,0x28,0x76,0x5f,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x2c,0x20,
    0x30,0x2e,0x30,0x66,0x2c,0x20,0x31,0x2e,0x30,0x66,0x29,0x3b,0x0a,0x7d,0x0a,0x0a,
    0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,
    0x75,0x74,0x20,0x6d,0x61,0x69,0x6e,0x28,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,
    0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,
    0x69,0x6e,0x70,0x75,0x74,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x76,0x5f,0x74,
    0x65,0x78,0x74,0x75,0x72,0x65,0x20,0x3d,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,
    0x6e,0x70,0x75,0x74,0x2e,0x76,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x76,0x5f,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,
    0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,0x76,0x5f,0x70,
    0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x20,0x20,0x20,0x20,0x76,0x65,0x72,
    0x74,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x53,0x50,
    0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,
    0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,0x0a,0x20,
    0x20,0x20,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x2e,
    0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x67,0x6c,
    0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x20,0x20,0x20,0x20,0x73,
    0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x2e,0x75,0x76,0x20,0x3d,
    0x20,0x75,0x76,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,0x65,0x74,0x75,0x72,0x6e,0x20,
    0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,0x0a,0x7d,0x0a,
    0x00,
}
/*
    cbuffer ve_blit_atlas_fs_params : register(b0)
    {
        int _88_region : packoffset(c0);
    };

    Texture2D<float4> ve_blit_atlas_src_texture : register(t0);
    SamplerState ve_blit_atlas_src_sampler : register(s0);

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

    float down_sample(float2 uv_1, float2 texture_size)
    {
        return 0.25f * (((ve_blit_atlas_src_texture.Sample(ve_blit_atlas_src_sampler, uv_1).x + ve_blit_atlas_src_texture.Sample(ve_blit_atlas_src_sampler, mad(float2(0.0f, 1.0f), texture_size, uv_1)).x) + ve_blit_atlas_src_texture.Sample(ve_blit_atlas_src_sampler, mad(float2(1.0f, 0.0f), texture_size, uv_1)).x) + ve_blit_atlas_src_texture.Sample(ve_blit_atlas_src_sampler, uv_1 + texture_size).x);
    }

    void frag_main()
    {
        bool _93 = _88_region == 0;
        bool _101;
        if (!_93)
        {
            _101 = _88_region == 1;
        }
        else
        {
            _101 = _93;
        }
        bool _109;
        if (!_101)
        {
            _109 = _88_region == 2;
        }
        else
        {
            _109 = _101;
        }
        if (_109)
        {
            float2 param = uv + float2(-0.00048828125f, -0.0029296875f);
            float2 param_1 = float2(0.00048828125f, 0.001953125f);
            float2 param_2 = uv + float2(0.000244140625f, -0.0029296875f);
            float2 param_3 = float2(0.00048828125f, 0.001953125f);
            float2 param_4 = uv + float2(-0.000732421875f, 0.0009765625f);
            float2 param_5 = float2(0.00048828125f, 0.001953125f);
            float2 param_6 = uv + float2(0.000244140625f, 0.0009765625f);
            float2 param_7 = float2(0.00048828125f, 0.001953125f);
            frag_color = float4(1.0f, 1.0f, 1.0f, 0.25f * (((down_sample(param, param_1) + down_sample(param_2, param_3)) + down_sample(param_4, param_5)) + down_sample(param_6, param_7)));
        }
        else
        {
            frag_color = float4(0.0f, 0.0f, 0.0f, 1.0f);
        }
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
@(private="file")
ve_blit_atlas_fs_source_hlsl4 := [2140]u8 {
    0x63,0x62,0x75,0x66,0x66,0x65,0x72,0x20,0x76,0x65,0x5f,0x62,0x6c,0x69,0x74,0x5f,
    0x61,0x74,0x6c,0x61,0x73,0x5f,0x66,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x20,
    0x3a,0x20,0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x62,0x30,0x29,0x0a,0x7b,
    0x0a,0x20,0x20,0x20,0x20,0x69,0x6e,0x74,0x20,0x5f,0x38,0x38,0x5f,0x72,0x65,0x67,
    0x69,0x6f,0x6e,0x20,0x3a,0x20,0x70,0x61,0x63,0x6b,0x6f,0x66,0x66,0x73,0x65,0x74,
    0x28,0x63,0x30,0x29,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x54,0x65,0x78,0x74,0x75,0x72,
    0x65,0x32,0x44,0x3c,0x66,0x6c,0x6f,0x61,0x74,0x34,0x3e,0x20,0x76,0x65,0x5f,0x62,
    0x6c,0x69,0x74,0x5f,0x61,0x74,0x6c,0x61,0x73,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,
    0x78,0x74,0x75,0x72,0x65,0x20,0x3a,0x20,0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,
    0x28,0x74,0x30,0x29,0x3b,0x0a,0x53,0x61,0x6d,0x70,0x6c,0x65,0x72,0x53,0x74,0x61,
    0x74,0x65,0x20,0x76,0x65,0x5f,0x62,0x6c,0x69,0x74,0x5f,0x61,0x74,0x6c,0x61,0x73,
    0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x20,0x3a,0x20,0x72,
    0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x73,0x30,0x29,0x3b,0x0a,0x0a,0x73,0x74,
    0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x75,0x76,0x3b,0x0a,
    0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x66,0x72,
    0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,
    0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,0x6e,
    0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,
    0x20,0x75,0x76,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x30,0x3b,
    0x0a,0x7d,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,0x52,
    0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x0a,0x7b,
    0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x66,0x72,0x61,0x67,
    0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3a,0x20,0x53,0x56,0x5f,0x54,0x61,0x72,0x67,
    0x65,0x74,0x30,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x66,0x6c,0x6f,0x61,0x74,0x20,0x64,
    0x6f,0x77,0x6e,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x28,0x66,0x6c,0x6f,0x61,0x74,
    0x32,0x20,0x75,0x76,0x5f,0x31,0x2c,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x74,
    0x65,0x78,0x74,0x75,0x72,0x65,0x5f,0x73,0x69,0x7a,0x65,0x29,0x0a,0x7b,0x0a,0x20,
    0x20,0x20,0x20,0x72,0x65,0x74,0x75,0x72,0x6e,0x20,0x30,0x2e,0x32,0x35,0x66,0x20,
    0x2a,0x20,0x28,0x28,0x28,0x76,0x65,0x5f,0x62,0x6c,0x69,0x74,0x5f,0x61,0x74,0x6c,
    0x61,0x73,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x2e,0x53,
    0x61,0x6d,0x70,0x6c,0x65,0x28,0x76,0x65,0x5f,0x62,0x6c,0x69,0x74,0x5f,0x61,0x74,
    0x6c,0x61,0x73,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x2c,
    0x20,0x75,0x76,0x5f,0x31,0x29,0x2e,0x78,0x20,0x2b,0x20,0x76,0x65,0x5f,0x62,0x6c,
    0x69,0x74,0x5f,0x61,0x74,0x6c,0x61,0x73,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,
    0x74,0x75,0x72,0x65,0x2e,0x53,0x61,0x6d,0x70,0x6c,0x65,0x28,0x76,0x65,0x5f,0x62,
    0x6c,0x69,0x74,0x5f,0x61,0x74,0x6c,0x61,0x73,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,
    0x6d,0x70,0x6c,0x65,0x72,0x2c,0x20,0x6d,0x61,0x64,0x28,0x66,0x6c,0x6f,0x61,0x74,
    0x32,0x28,0x30,0x2e,0x30,0x66,0x2c,0x20,0x31,0x2e,0x30,0x66,0x29,0x2c,0x20,0x74,
    0x65,0x78,0x74,0x75,0x72,0x65,0x5f,0x73,0x69,0x7a,0x65,0x2c,0x20,0x75,0x76,0x5f,
    0x31,0x29,0x29,0x2e,0x78,0x29,0x20,0x2b,0x20,0x76,0x65,0x5f,0x62,0x6c,0x69,0x74,
    0x5f,0x61,0x74,0x6c,0x61,0x73,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,0x74,0x75,
    0x72,0x65,0x2e,0x53,0x61,0x6d,0x70,0x6c,0x65,0x28,0x76,0x65,0x5f,0x62,0x6c,0x69,
    0x74,0x5f,0x61,0x74,0x6c,0x61,0x73,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,
    0x6c,0x65,0x72,0x2c,0x20,0x6d,0x61,0x64,0x28,0x66,0x6c,0x6f,0x61,0x74,0x32,0x28,
    0x31,0x2e,0x30,0x66,0x2c,0x20,0x30,0x2e,0x30,0x66,0x29,0x2c,0x20,0x74,0x65,0x78,
    0x74,0x75,0x72,0x65,0x5f,0x73,0x69,0x7a,0x65,0x2c,0x20,0x75,0x76,0x5f,0x31,0x29,
    0x29,0x2e,0x78,0x29,0x20,0x2b,0x20,0x76,0x65,0x5f,0x62,0x6c,0x69,0x74,0x5f,0x61,
    0x74,0x6c,0x61,0x73,0x5f,0x73,0x72,0x63,0x5f,0x74,0x65,0x78,0x74,0x75,0x72,0x65,
    0x2e,0x53,0x61,0x6d,0x70,0x6c,0x65,0x28,0x76,0x65,0x5f,0x62,0x6c,0x69,0x74,0x5f,
    0x61,0x74,0x6c,0x61,0x73,0x5f,0x73,0x72,0x63,0x5f,0x73,0x61,0x6d,0x70,0x6c,0x65,
    0x72,0x2c,0x20,0x75,0x76,0x5f,0x31,0x20,0x2b,0x20,0x74,0x65,0x78,0x74,0x75,0x72,
    0x65,0x5f,0x73,0x69,0x7a,0x65,0x29,0x2e,0x78,0x29,0x3b,0x0a,0x7d,0x0a,0x0a,0x76,
    0x6f,0x69,0x64,0x20,0x66,0x72,0x61,0x67,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,
    0x7b,0x0a,0x20,0x20,0x20,0x20,0x62,0x6f,0x6f,0x6c,0x20,0x5f,0x39,0x33,0x20,0x3d,
    0x20,0x5f,0x38,0x38,0x5f,0x72,0x65,0x67,0x69,0x6f,0x6e,0x20,0x3d,0x3d,0x20,0x30,
    0x3b,0x0a,0x20,0x20,0x20,0x20,0x62,0x6f,0x6f,0x6c,0x20,0x5f,0x31,0x30,0x31,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x69,0x66,0x20,0x28,0x21,0x5f,0x39,0x33,0x29,0x0a,0x20,
    0x20,0x20,0x20,0x7b,0x0a,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x5f,0x31,0x30,
    0x31,0x20,0x3d,0x20,0x5f,0x38,0x38,0x5f,0x72,0x65,0x67,0x69,0x6f,0x6e,0x20,0x3d,
    0x3d,0x20,0x31,0x3b,0x0a,0x20,0x20,0x20,0x20,0x7d,0x0a,0x20,0x20,0x20,0x20,0x65,
    0x6c,0x73,0x65,0x0a,0x20,0x20,0x20,0x20,0x7b,0x0a,0x20,0x20,0x20,0x20,0x20,0x20,
    0x20,0x20,0x5f,0x31,0x30,0x31,0x20,0x3d,0x20,0x5f,0x39,0x33,0x3b,0x0a,0x20,0x20,
    0x20,0x20,0x7d,0x0a,0x20,0x20,0x20,0x20,0x62,0x6f,0x6f,0x6c,0x20,0x5f,0x31,0x30,
    0x39,0x3b,0x0a,0x20,0x20,0x20,0x20,0x69,0x66,0x20,0x28,0x21,0x5f,0x31,0x30,0x31,
    0x29,0x0a,0x20,0x20,0x20,0x20,0x7b,0x0a,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,
    0x5f,0x31,0x30,0x39,0x20,0x3d,0x20,0x5f,0x38,0x38,0x5f,0x72,0x65,0x67,0x69,0x6f,
    0x6e,0x20,0x3d,0x3d,0x20,0x32,0x3b,0x0a,0x20,0x20,0x20,0x20,0x7d,0x0a,0x20,0x20,
    0x20,0x20,0x65,0x6c,0x73,0x65,0x0a,0x20,0x20,0x20,0x20,0x7b,0x0a,0x20,0x20,0x20,
    0x20,0x20,0x20,0x20,0x20,0x5f,0x31,0x30,0x39,0x20,0x3d,0x20,0x5f,0x31,0x30,0x31,
    0x3b,0x0a,0x20,0x20,0x20,0x20,0x7d,0x0a,0x20,0x20,0x20,0x20,0x69,0x66,0x20,0x28,
    0x5f,0x31,0x30,0x39,0x29,0x0a,0x20,0x20,0x20,0x20,0x7b,0x0a,0x20,0x20,0x20,0x20,
    0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x70,0x61,0x72,0x61,0x6d,
    0x20,0x3d,0x20,0x75,0x76,0x20,0x2b,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x28,0x2d,
    0x30,0x2e,0x30,0x30,0x30,0x34,0x38,0x38,0x32,0x38,0x31,0x32,0x35,0x66,0x2c,0x20,
    0x2d,0x30,0x2e,0x30,0x30,0x32,0x39,0x32,0x39,0x36,0x38,0x37,0x35,0x66,0x29,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,
    0x70,0x61,0x72,0x61,0x6d,0x5f,0x31,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,
    0x28,0x30,0x2e,0x30,0x30,0x30,0x34,0x38,0x38,0x32,0x38,0x31,0x32,0x35,0x66,0x2c,
    0x20,0x30,0x2e,0x30,0x30,0x31,0x39,0x35,0x33,0x31,0x32,0x35,0x66,0x29,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x70,
    0x61,0x72,0x61,0x6d,0x5f,0x32,0x20,0x3d,0x20,0x75,0x76,0x20,0x2b,0x20,0x66,0x6c,
    0x6f,0x61,0x74,0x32,0x28,0x30,0x2e,0x30,0x30,0x30,0x32,0x34,0x34,0x31,0x34,0x30,
    0x36,0x32,0x35,0x66,0x2c,0x20,0x2d,0x30,0x2e,0x30,0x30,0x32,0x39,0x32,0x39,0x36,
    0x38,0x37,0x35,0x66,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x32,0x20,0x70,0x61,0x72,0x61,0x6d,0x5f,0x33,0x20,0x3d,0x20,
    0x66,0x6c,0x6f,0x61,0x74,0x32,0x28,0x30,0x2e,0x30,0x30,0x30,0x34,0x38,0x38,0x32,
    0x38,0x31,0x32,0x35,0x66,0x2c,0x20,0x30,0x2e,0x30,0x30,0x31,0x39,0x35,0x33,0x31,
    0x32,0x35,0x66,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x66,0x6c,
    0x6f,0x61,0x74,0x32,0x20,0x70,0x61,0x72,0x61,0x6d,0x5f,0x34,0x20,0x3d,0x20,0x75,
    0x76,0x20,0x2b,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x28,0x2d,0x30,0x2e,0x30,0x30,
    0x30,0x37,0x33,0x32,0x34,0x32,0x31,0x38,0x37,0x35,0x66,0x2c,0x20,0x30,0x2e,0x30,
    0x30,0x30,0x39,0x37,0x36,0x35,0x36,0x32,0x35,0x66,0x29,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x70,0x61,0x72,0x61,
    0x6d,0x5f,0x35,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x28,0x30,0x2e,0x30,
    0x30,0x30,0x34,0x38,0x38,0x32,0x38,0x31,0x32,0x35,0x66,0x2c,0x20,0x30,0x2e,0x30,
    0x30,0x31,0x39,0x35,0x33,0x31,0x32,0x35,0x66,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x70,0x61,0x72,0x61,0x6d,
    0x5f,0x36,0x20,0x3d,0x20,0x75,0x76,0x20,0x2b,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,
    0x28,0x30,0x2e,0x30,0x30,0x30,0x32,0x34,0x34,0x31,0x34,0x30,0x36,0x32,0x35,0x66,
    0x2c,0x20,0x30,0x2e,0x30,0x30,0x30,0x39,0x37,0x36,0x35,0x36,0x32,0x35,0x66,0x29,
    0x3b,0x0a,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,
    0x20,0x70,0x61,0x72,0x61,0x6d,0x5f,0x37,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,
    0x32,0x28,0x30,0x2e,0x30,0x30,0x30,0x34,0x38,0x38,0x32,0x38,0x31,0x32,0x35,0x66,
    0x2c,0x20,0x30,0x2e,0x30,0x30,0x31,0x39,0x35,0x33,0x31,0x32,0x35,0x66,0x29,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,
    0x6c,0x6f,0x72,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x28,0x31,0x2e,0x30,
    0x66,0x2c,0x20,0x31,0x2e,0x30,0x66,0x2c,0x20,0x31,0x2e,0x30,0x66,0x2c,0x20,0x30,
    0x2e,0x32,0x35,0x66,0x20,0x2a,0x20,0x28,0x28,0x28,0x64,0x6f,0x77,0x6e,0x5f,0x73,
    0x61,0x6d,0x70,0x6c,0x65,0x28,0x70,0x61,0x72,0x61,0x6d,0x2c,0x20,0x70,0x61,0x72,
    0x61,0x6d,0x5f,0x31,0x29,0x20,0x2b,0x20,0x64,0x6f,0x77,0x6e,0x5f,0x73,0x61,0x6d,
    0x70,0x6c,0x65,0x28,0x70,0x61,0x72,0x61,0x6d,0x5f,0x32,0x2c,0x20,0x70,0x61,0x72,
    0x61,0x6d,0x5f,0x33,0x29,0x29,0x20,0x2b,0x20,0x64,0x6f,0x77,0x6e,0x5f,0x73,0x61,
    0x6d,0x70,0x6c,0x65,0x28,0x70,0x61,0x72,0x61,0x6d,0x5f,0x34,0x2c,0x20,0x70,0x61,
    0x72,0x61,0x6d,0x5f,0x35,0x29,0x29,0x20,0x2b,0x20,0x64,0x6f,0x77,0x6e,0x5f,0x73,
    0x61,0x6d,0x70,0x6c,0x65,0x28,0x70,0x61,0x72,0x61,0x6d,0x5f,0x36,0x2c,0x20,0x70,
    0x61,0x72,0x61,0x6d,0x5f,0x37,0x29,0x29,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x7d,
    0x0a,0x20,0x20,0x20,0x20,0x65,0x6c,0x73,0x65,0x0a,0x20,0x20,0x20,0x20,0x7b,0x0a,
    0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x20,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,
    0x6f,0x72,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x28,0x30,0x2e,0x30,0x66,
    0x2c,0x20,0x30,0x2e,0x30,0x66,0x2c,0x20,0x30,0x2e,0x30,0x66,0x2c,0x20,0x31,0x2e,
    0x30,0x66,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x7d,0x0a,0x7d,0x0a,0x0a,0x53,0x50,
    0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,
    0x20,0x6d,0x61,0x69,0x6e,0x28,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,
    0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,
    0x70,0x75,0x74,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x75,0x76,0x20,0x3d,0x20,
    0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,0x75,0x76,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x66,0x72,0x61,0x67,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,
    0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,
    0x74,0x70,0x75,0x74,0x3b,0x0a,0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,
    0x6f,0x75,0x74,0x70,0x75,0x74,0x2e,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,
    0x72,0x20,0x3d,0x20,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x72,0x65,0x74,0x75,0x72,0x6e,0x20,0x73,0x74,0x61,0x67,0x65,
    0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,0x0a,0x7d,0x0a,0x00,
}
ve_blit_atlas_shader_desc :: proc (backend: sg.Backend) -> sg.Shader_Desc {
    desc: sg.Shader_Desc
    desc.label = "ve_blit_atlas_shader"
    #partial switch backend {
    case .D3D11:
        desc.vertex_func.source = transmute(cstring)&ve_blit_atlas_vs_source_hlsl4
        desc.vertex_func.d3d11_target = "vs_4_0"
        desc.vertex_func.entry = "main"
        desc.fragment_func.source = transmute(cstring)&ve_blit_atlas_fs_source_hlsl4
        desc.fragment_func.d3d11_target = "ps_4_0"
        desc.fragment_func.entry = "main"
        desc.attrs[0].hlsl_sem_name = "TEXCOORD"
        desc.attrs[0].hlsl_sem_index = 0
        desc.attrs[1].hlsl_sem_name = "TEXCOORD"
        desc.attrs[1].hlsl_sem_index = 1
        desc.uniform_blocks[0].stage = .FRAGMENT
        desc.uniform_blocks[0].layout = .STD140
        desc.uniform_blocks[0].size = 16
        desc.uniform_blocks[0].hlsl_register_b_n = 0
        desc.images[0].stage = .FRAGMENT
        desc.images[0].multisampled = false
        desc.images[0].image_type = ._2D
        desc.images[0].sample_type = .FLOAT
        desc.images[0].hlsl_register_t_n = 0
        desc.samplers[0].stage = .FRAGMENT
        desc.samplers[0].sampler_type = .FILTERING
        desc.samplers[0].hlsl_register_s_n = 0
        desc.image_sampler_pairs[0].stage = .FRAGMENT
        desc.image_sampler_pairs[0].image_slot = 0
        desc.image_sampler_pairs[0].sampler_slot = 0
    }
    return desc
}
