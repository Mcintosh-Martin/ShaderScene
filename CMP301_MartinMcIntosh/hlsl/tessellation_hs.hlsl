// Tessellation Hull Shader
// Prepares control points for tessellation

cbuffer testBuffer : register(b0)
{
    float3 camPos;
    float pad;
};

struct InputType
{
    float3 position : POSITION;
    float2 tex : TEXCOORD0;
    float4 t : SV_Position;
};

struct ConstantOutputType
{
    float edges[4] : SV_TessFactor;
    float inside[2] : SV_InsideTessFactor;
};

struct OutputType
{
    float2 tex : TEXCOORD4;
    float3 position : POSITION;
};

ConstantOutputType PatchConstantFunction(InputPatch<InputType, 4> inputPatch, uint patchId : SV_PrimitiveID)
{    
    ConstantOutputType output;

    //take average input
    float3 patchAdv = (float3)0;
    for (int i = 0; i < 4; i++)
    {
        patchAdv += inputPatch[i].position;
    }
    patchAdv /= 4;
    //average the float3 into a float 2
    float2 pos = float2(patchAdv.x, patchAdv.z);
    
    //Find distance from vertex to camera
    float2 distance = (pos - camPos.xz);
    //find distance average
    float distanceAdv = (distance.x + distance.y /*+ distance.z*/) / 2;
    distanceAdv += 1/2;

    //Makes distance positive
    if (distanceAdv < 0)
    {
        distanceAdv *= -1;
    }
    
    //Calculate tesseleation factor so that the smaller the distance the higher the facter and clamp between 1 and 5
    float tessellationFactor = clamp(100 / distanceAdv, 1, 5);

    // Set the tessellation factors for the three edges of the triangle.
    output.edges[0] = tessellationFactor;
    output.edges[1] = tessellationFactor;
    output.edges[2] = tessellationFactor;
    output.edges[3] = tessellationFactor;

    // Set the tessellation factor for tessallating inside the triangle.
    output.inside[0] = tessellationFactor;
    output.inside[1] = tessellationFactor;
    
    return output;
}


[domain("quad")]
[partitioning("integer")]
[outputtopology("triangle_ccw")]
[outputcontrolpoints(4)]
[patchconstantfunc("PatchConstantFunction")]
OutputType main(InputPatch<InputType, 4> patch, uint pointId : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
    OutputType output;

    // Set the position for this control point as the output position.
    output.position = patch[pointId].position;
    output.tex = patch[pointId].tex;

    return output;
}