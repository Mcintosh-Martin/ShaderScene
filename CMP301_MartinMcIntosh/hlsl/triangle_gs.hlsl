// triangle_gs
// Geometry shader that generates a triangle for every vertex.

Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
};

cbuffer grassMoveBuffer : register(b1)
{
    float3 camPos;
    float time;
    float speed;
    float limit;
    float lHight;
    float uHeight;
    float3 padding;
};

struct InputType
{
	float4 position : POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
};

struct OutputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
};

int rand(float n)
{
    // <<, ^ and & require GL_EXT_gpu_shader4.
    //n = (n << 13.f) ^ n;
    return (n * (n * n * 15731 + 789221) + 1376312589);
}

float rand3(float2 co)
{
    return 0.5 + (frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453)) * 0.5;
}

float3 rotate(float3 pos, float angl)
{
    // This is the 3D position that we want to rotate:
    float3 p = pos;

// Specify the axis to rotate about:
    float x = 0.0;
    float y = 1.0;
    float z = 0.0;

// Specify the angle in radians:
    
    float angle = /*sin(*/rand(angl) /**time)*/ * 3.14 / 180.0; // 90 degrees, CCW
     //add source
    float3 q;
    q.x = p.x * (x * x * (1.0 - cos(angle)) + cos(angle))
    + p.y * (x * y * (1.0 - cos(angle)) + z * sin(angle))
    + p.z * (x * z * (1.0 - cos(angle)) - y * sin(angle));

    q.y = p.x * (y * x * (1.0 - cos(angle)) - z * sin(angle))
    + p.y * (y * y * (1.0 - cos(angle)) + cos(angle))
    + p.z * (y * z * (1.0 - cos(angle)) + x * sin(angle));

    q.z = p.x * (z * x * (1.0 - cos(angle)) + y * sin(angle))
    + p.y * (z * y * (1.0 - cos(angle)) - x * sin(angle))
    + p.z * (z * z * (1.0 - cos(angle)) + cos(angle));

    return q;
}


[maxvertexcount(8)]
void main(point InputType input[1], inout TriangleStream<OutputType> quadStream)
{
    float t = float((input[0].position.x / 8 + input[0].position.y / 4 + input[0].position.z / 2) * 191);
    float sit = cos(time * speed * rand3(t)) / limit;
    float sitx = sin(time * speed * rand3(t * 34)) / 9;
    
    float height = 0.2;
    float hHeight = height / 2;
    float bWidth = 0.04;
    float m1Width = 0.03;
    float m2Width = 0.02;
    float tWidth =  0.01;
    float hWidth = bWidth / 2;
    
    float3 look = camPos - input[0].position.w;
    look.y = 0.0f; // y-axis aligned, so project to xz-plane
    look = normalize(look);
    
    float4 colour = texture0.SampleLevel(sampler0, input[0].tex, 0);
	
    float start = colour.y * 8;
    
    input[0].position.x /= 4;
    input[0].position.z /= 4;
    
    float3 g_positions[8] = 
    {
        float3(-bWidth / 2, start, 0),
        float3(bWidth / 2, start, 0),
        float3(-m1Width / 2 + sitx / 3, start + height / 3, cos(time * speed) / (limit * 6)),
        float3(m1Width / 2 + sitx / 3, start + height / 3, cos(time * speed) / (limit * 6)),
        float3(-m2Width / 2 + sitx / 2, start + height / 2, cos(time * speed) / (limit * 3)),
        float3(m2Width / 2 + sitx / 2, start + height / 2, cos(time * speed) / (limit * 3)),
        float3(-tWidth / 2 + sitx, start + height, cos(time * speed) / (limit * 1)),
        float3(tWidth / 2 + sitx, start + height, cos(time * speed) / (limit * 1))
    };
    
    float2 g_tex[8] =
    {
        float2(0, 0),
        float2(1, 0),
        float2(0, 0.333),
        float2(1, 0.333),
        float2(0, 0.666),
        float2(1, 0.666),
        float2(0, 1),
        float2(1, 1)

    };
    
	OutputType output;
    
    
    if(start > lHight && start < uHeight)
    {
        matrix WVP = mul(worldMatrix, viewMatrix);
        WVP = mul(WVP, projectionMatrix);
    
        float t = float((input[0].position.x + input[0].position.y + input[0].position.z) / 215);
        
        for (int i = 0; i < 8; i++)
        {
            float4 vposition = float4(rotate(g_positions[i].xyz, t), 1.0f) + input[0].position;
            output.position = mul(vposition, WVP);
            output.tex = g_tex[i];
            output.normal = look;
            quadStream.Append(output);
        }
    }
        quadStream.RestartStrip();
}