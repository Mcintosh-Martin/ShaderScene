// Tessellation domain shader
// After tessellation the domain shader processes the all the vertices
Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
    matrix lightViewMatrix;
    matrix lightProjectionMatrix;
    matrix sLightViewMatrix;
    matrix sLightProjectionMatrix;
    matrix tLightViewMatrix;
    matrix tLightProjectionMatrix;
};

struct ConstantOutputType
{
    float edges[4] : SV_TessFactor;
    float inside[2] : SV_InsideTessFactor;
};

struct InputType
{
    float2 tex : TEXCOORD4;
    float3 position : POSITION;
};

struct OutputType
{
    float2 tex : TEXCOORD4;
    float3 normal : NORMAL;
    float3 worldPosition : TEXCOORD3;
    float4 tLightViewPos : TEXCOORD2;
    float4 sLightViewPos : TEXCOORD1;
    float4 lightViewPos : TEXCOORD0;
    float4 position : SV_POSITION;
};

float3 calculateNormals(OutputType output)
{
    float cellSpcae = 1.f / 100.f;

    //Calculate vetex postions
    float orgin = ((texture0.SampleLevel(sampler0, output.tex, 0.f))).r;
    float up = ((texture0.SampleLevel(sampler0, output.tex + float2(0.f, -cellSpcae), 0.f)));
    float down = ((texture0.SampleLevel(sampler0, output.tex + float2(0.f, cellSpcae), 0.f)));
    float left = ((texture0.SampleLevel(sampler0, output.tex + float2(-cellSpcae, 0.f), 0.f)));
    float right = ((texture0.SampleLevel(sampler0, output.tex + float2(cellSpcae, 0.f), 0.f)));
	
    //Get tangeent and bitangents
    float3 tangent = normalize(float3(2 * cellSpcae, (right - left) * 3, 0.f));
    float3 bitangent = normalize(float3(0.f, (down - up) * 3, (-2.f) * cellSpcae));
        
    //Get the cross product
    float3 temp = cross(tangent, bitangent);
    //Times by worldmatrix and return
    temp = mul(temp, (float3x3) worldMatrix);
    return normalize(temp);
}

//Calculate light view
float4 calculateLightView(float3 VertexPosition, matrix LightView, matrix LightProjection)
{
    float4 temp = mul(float4(VertexPosition, 1.0f), worldMatrix);
    temp = mul(temp, LightView);
    temp = mul(temp, LightProjection);
    
    return temp;
}

[domain("quad")]
OutputType main(ConstantOutputType input, float2 uvwCoord : SV_DomainLocation, const OutputPatch<InputType, 4> patch)
{
    float3 vertexPosition;
    OutputType output;
    
   // InputType input;
    
    // Determine the position of the new vertex.
	// Invert the y and Z components of uvwCoord as these coords are generated in UV space and therefore y is positive downward.
	// Alternatively you can set the output topology of the hull shader to cw instead of ccw (or vice versa).
    float3 v1 = lerp(patch[0].position, patch[1].position, uvwCoord.y);
    float3 v2 = lerp(patch[3].position, patch[2].position, uvwCoord.y);
    vertexPosition = lerp(v1, v2, uvwCoord.x);
	
    //calculate the texture position on tesselated surface
    float2 t1 = lerp(patch[0].tex, patch[1].tex, uvwCoord.y);
    float2 t2 = lerp(patch[3].tex, patch[2].tex, uvwCoord.y);
    output.tex = lerp(t1, t2, uvwCoord.x);
   
    //Sets vertex y position based on the textures colour value
    vertexPosition.y = texture0.SampleLevel(sampler0, output.tex, 0) * 4;

    output.normal = calculateNormals(output);
    
    // Calculate the position of the new vertex against the world, view, and projection matrices.
    output.position = mul(float4(vertexPosition, 1.0f), worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
   
    //Calulate light view position of each light
    output.lightViewPos = calculateLightView(vertexPosition, lightViewMatrix, lightProjectionMatrix);
    output.sLightViewPos = calculateLightView(vertexPosition, sLightViewMatrix, sLightProjectionMatrix);
    output.tLightViewPos = calculateLightView(vertexPosition, tLightViewMatrix, tLightProjectionMatrix);

    output.worldPosition = mul(vertexPosition, (float3x3)worldMatrix).xyz;
    return output;
}

