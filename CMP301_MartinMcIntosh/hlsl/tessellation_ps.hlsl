// Tessellation pixel shader
// Output colour passed to stage.

// Texture and sampler registers
Texture2D texture0 : register(t0);
Texture2D depthMap : register(t1);
Texture2D sDepthMap : register(t2);
Texture2D tDepthMap : register(t3);

SamplerState sampler0 : register(s0);
SamplerState shadowSampler : register(s1);

cbuffer lightBuffer : register(b0)
{
    float4 ambient;
    float4 diffuse;
    float4 lPosition;
    
    float4 sDiffuse;
    float4 sLPosition;
    
    float4 tDiffuse;
    float4 tDirection;
    
};

struct InputType
{
    float2 tex : TEXCOORD4;
    float3 normal : NORMAL;
    float3 worldPosition : TEXCOORD3;
    float4 tLightViewPos : TEXCOORD2;
    float4 sLightViewPos : TEXCOORD1;
    float4 lightViewPos : TEXCOORD0;
    float4 position : SV_POSITION;
};

// Calculate lighting intensity based on direction and normal. Combine with light colour.
float4 calculateLightingAten(float3 lightDirection, InputType input, float4 ldiffuse, float3 position)
{
    
    float intensity = saturate(dot(input.normal, lightDirection));
    float4 colour = saturate(ldiffuse * intensity);

    float d = length(position - input.worldPosition);
    float c = 0.5f;
    float l = 0.125f;
    float q = 0.0f;
    float attValue = 1 / ((c + (l * d)) + (q * pow(d, 2)));
    
    colour *= attValue;
    colour = saturate(colour);
    return colour;
}

// Calculate lighting intensity based on direction and normal. Combine with light colour.
float4 calculateLighting(float3 lightDirection, float3 normal, float4 diffuse)
{
    float intensity = saturate(dot(normal, lightDirection));
    float4 colour = saturate(diffuse * intensity);
    return colour;
}

// Is the gemoetry in our shadow map // pauls code
bool hasDepthData(float2 uv)
{
    if (uv.x < 0.f || uv.x > 1.f || uv.y < 0.f || uv.y > 1.f)
    {
        return false;
    }
    return true;
}


//Pauls Code
bool isInShadow(Texture2D sMap, float2 uv, float4 lightViewPosition, float bias)
{
    // Sample the shadow map (get depth of geometry)
    float depthValue = sMap.Sample(shadowSampler, uv).r;
	// Calculate the depth from the light.
    float lightDepthValue = lightViewPosition.z / lightViewPosition.w;
    lightDepthValue -= bias;

	// Compare the depth of the shadow map value and the depth of the light to determine whether to shadow or to light this pixel.
    if (lightDepthValue < depthValue)
    {
        return false;
    }
    return true;
}

//Pauls code
float2 getProjectiveCoords(float4 lightViewPosition)
{
    // Calculate the projected texture coordinates.
    float2 projTex = lightViewPosition.xy / lightViewPosition.w;
    projTex *= float2(0.5, -0.5);
    projTex += float2(0.5f, 0.5f);
    return projTex;
}

float4 main(InputType input) : SV_TARGET
{
    // Sample the texture. Calculate light intensity and colour, return light*texture for final pixel colour.
    float3 lightVector = normalize(lPosition.xyz - input.worldPosition);
    float3 sLightVector = normalize(sLPosition.xyz - input.worldPosition);
    
    float shadowMapBias = 0.020f;
    float4 colour = float4(0.f, 0.f, 0.f, 1.f);
    float4 sColour = float4(0.f, 0.f, 0.f, 1.f);
    float4 tColour = float4(0.f, 0.f, 0.f, 1.f);
    float4 textureColour = texture0.Sample(sampler0, input.tex);

	// Calculate the projected texture coordinates.
    float2 pTexCoord = getProjectiveCoords(input.lightViewPos);
    float2 pSTexCoord = getProjectiveCoords(input.sLightViewPos);
    float2 pTTexCoord = getProjectiveCoords(input.tLightViewPos);
	
    //bool x, y, z;
    //// Shadow test. Is or isn't in shadow
    if (hasDepthData(pTexCoord))
    {
        //// Has depth map data
        if (!isInShadow(depthMap, pTexCoord, input.lightViewPos, shadowMapBias))
        {
            // is NOT in shadow, therefore light
            colour = calculateLightingAten(lightVector, input, diffuse, lPosition.xyz);
        }
    }
     // Shadow test. Is or isn't in shadow
    if (hasDepthData(pSTexCoord))
    {
        //// Has depth map data
        if (!isInShadow(sDepthMap, pSTexCoord, input.sLightViewPos, shadowMapBias))
        {
            sColour = calculateLightingAten(sLightVector, input, sDiffuse, sLPosition.xyz);
        }
    }
    if (hasDepthData(pTTexCoord))
    {
        //// Has depth map data
        if (!isInShadow(sDepthMap, pTTexCoord, input.tLightViewPos, shadowMapBias))
        {
            tColour = calculateLighting(-tDirection.xyz, input.normal, tDiffuse);
        }
    }
    
    //saturate all 3 lights and ambient
    colour = saturate(colour + sColour + tColour + ambient);
    //add texture colour
    return saturate(colour) * textureColour;
    }