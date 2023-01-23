// Tessellation vertex shader.
// Doesn't do much, could manipulate the control points
// Pass forward data, strip out some values not required for example.



struct InputType
{
    float3 position : POSITION;
    float2 tex : TEXCOORD0;
};

struct OutputType
{
    float3 position : POSITION;
    float2 tex : TEXCOORD0;
    float4 t : SV_Position;
    
};

OutputType main(InputType input)
{
    OutputType output;

	// Pass the vertex position into the hull shader.
    output.position = input.position;
    
    // Pass the input color into the hull shader.
    output.tex = input.tex;
    output.t = float4(0, 0, 0, 0);
    
    return output;
}
