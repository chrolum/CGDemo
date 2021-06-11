Shader "Saltsuica/SimpleGrass"
{
    Properties
    {
		[Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
		_BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2

		_BladeWidth("Blade Width", Range(0, 1)) = 0.05
		_BladeWidthRandom("Blade Width Random", Range(0, 1)) = 0.02
		_BladeHeight("Blade Height", Range(0, 1)) = 0.5
		_BladeHeightRandom("Blade Height Random", Range(0, 1)) = 0.3

		_TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1

		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
		_WindStrength("Wind Strength", Range(0.01, 2)) = 1
    }

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"
	#include "../CustomTessellation.cginc"

	struct geometryOutput	
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};

	// struct vertexInput
	// {
	// 	float4 vertex : POSITION;
	// 	float3 normal: NORMAL;
	// 	float4 tangent: TANGENT;
	// };

	// struct vertexOutput
	// {
	// 	float4 vertex : SV_POSITION;
	// 	float3 normal : NORMAL;
	// 	float4 tangent : TANGENT;
	// };

	geometryOutput VertexOutput(float3 pos, float2 uv)
	{
		geometryOutput o;
		o.pos = UnityObjectToClipPos(pos);
		o.uv = uv;
		return o; 
	}

	// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
	// Extended discussion on this function can be found at the following link:
	// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	// Construct a rotation matrix that rotates around the provided axis, sourced from:
	// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	float3x3 AngleAxis3x3(float angle, float3 axis)
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}

	float _BendRotationRandom;
	float _BladeWidth;
	float _BladeWidthRandom;
	float _BladeHeight;
	float _BladeHeightRandom;

	sampler2D _WindDistortionMap;
	float4 _WindDistortionMap_ST;
	float2 _WindFrequency;
	float _WindStrength;
	// create a geometry shader
	[maxvertexcount(3)] 
	void geo(triangle vertexOutput IN[3], inout TriangleStream<geometryOutput> triStream)
	{
		geometryOutput o;
		float3 pos = IN[0].vertex;

		float3 vNormal = IN[0].normal; //up (0,0,1)
		float4 vTangent = IN[0].tangent; // RIGHT (1, 0, 0)
		float3 vBinormal = cross(vNormal, vTangent) * vTangent.w; //foward (0, 1, 0)

		float3x3 tangentToLocal = float3x3(
			vTangent.x, vBinormal.x, vNormal.x,
			vTangent.y, vBinormal.y, vNormal.y,
			vTangent.z, vBinormal.z, vNormal.z
			);
		// float3x3 tangentToLocal = float3x3(
		// 	vTangent.x, vNormal.x, vBinormal.x,
		// 	vTangent.y, vNormal.y, vBinormal.y,
		// 	vTangent.z, vNormal.z, vBinormal.z
		// 	); // 把向上方向定义在y轴

		float2 uv = pos.xz * _WindDistortionMap_ST.xy +
			_WindDistortionMap_ST.zw + _WindFrequency * _Time.y;// 根据自身位置和游戏时间生成采样的uv

		//rescale uv range to -1...1
		float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0,0) * 2 - 1)) * _WindStrength;

		float3 windDir = normalize(float3(windSample.x, windSample.y, 0));//实际上是绕风旋转轴
		// 采样角度乘上0.5 防止草被吹到地下
		// 使用旋转实现的风吹效果是不正确的，整片草都会旋转
		// 正确的效果应该是草的根部不动
		float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, windDir);

		float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
		float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(1, 0, 0));

		//草的顶点单独应用风变换
		float3x3 windTrans = mul(tangentToLocal, windRotation);
		float3x3 facingTrans = mul(tangentToLocal, facingRotationMatrix);
		windTrans = mul(windTrans, facingRotationMatrix);
		windTrans = mul(windTrans, bendRotationMatrix);	

		float height =abs((rand(pos.zyx) * 2 - 1)) * _BladeHeightRandom + _BladeHeight;
		float width = abs((rand(pos.xyz) * 2 - 1)) * _BladeWidthRandom + _BladeWidth;

		triStream.Append(VertexOutput(pos + mul(facingTrans, float3(width, 0, 0)), float2(0,0)));
		triStream.Append(VertexOutput(pos + mul(facingTrans, float3(-width, 0, 0)), float2(1, 0)));
		triStream.Append(VertexOutput(pos + mul(windTrans, float3(0, 0, height)), float2(0.5, 1))); // 切线空间中，Z轴才是上方向

		// o.pos = UnityObjectToClipPos(pos + float4(0.5, 0, 0, 1));
		// triStream.Append(o);
		// o.pos = UnityObjectToClipPos(pos + float4(-0.5, 0, 0, 1));
		// triStream.Append(o);
		// o.pos = UnityObjectToClipPos(pos + float4(0, 1, 0, 1));
		// triStream.Append(o);
	}

	



	// vertexOutput vert(vertexInput v)
	// {
	// 	// return UnityObjectToClipPos(vertex);// 这里已经把顶点输出到裁剪空间了
	// 	// return vertex;
	// 	vertexOutput o;
	// 	o.vertex = v.vertex;
	// 	o.normal = v.normal;
	// 	o.tangent = v.tangent;
	// 	return o;
	// }
	ENDCG

    SubShader
    {
		Cull Off
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
		}

        Pass
        {
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "UniversalForward"
			}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma geometry geo
			#pragma target 4.6
			#pragma hull hull
			#pragma domain domain
             
			#include "Lighting.cginc"

			float4 _TopColor;
			float4 _BottomColor;
			float _TranslucentGain;

			float4 frag (geometryOutput i, fixed facing : VFACE) : SV_Target
            {	
				return lerp(_BottomColor, _TopColor, i.uv.y); //定义一个底部颜色和顶部颜色，更具uv的v来线性插值出颜色
            }
            ENDCG
        }
    }
}