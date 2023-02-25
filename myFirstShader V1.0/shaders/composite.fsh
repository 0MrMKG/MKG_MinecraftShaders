#version 120

const int shadowMapResolution = 1024*4;   // 阴影分辨率 默认 1024
const float	sunPathRotation	= -33.0;    // 太阳偏移角 默认 0

uniform sampler2D texture;
uniform sampler2D depthtex0;
uniform sampler2D shadow;

uniform float far;
uniform float viewWidth;
uniform float viewHeight;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

varying vec4 texcoord;

vec4 GetBloomColor(vec4 color)
{
    if (color.r*0.5 + color.g*0.5 + color.b*0.5 <=0.7)
    {
       color.rgb = vec3(0);
    }
    return color;
}

vec2 getFishEyeCoord(vec2 positionInNdcCoord) {
    return positionInNdcCoord / (0.15 + 0.85*length(positionInNdcCoord.xy));
}

vec4 getShadow(vec4 color, vec4 positionInWorldCoord) {
    // 我的世界坐标 转 太阳的眼坐标
    vec4 positionInSunViewCoord = shadowModelView * positionInWorldCoord;
    // 太阳的眼坐标 转 太阳的裁剪坐标
    vec4 positionInSunClipCoord = shadowProjection * positionInSunViewCoord;
    // 太阳的裁剪坐标 转 太阳的ndc坐标
    vec4 positionInSunNdcCoord = vec4(positionInSunClipCoord.xyz/positionInSunClipCoord.w, 1.0);
    //  从太阳的ndc坐标 转 鱼眼坐标
    positionInSunNdcCoord.xy = getFishEyeCoord(positionInSunNdcCoord.xy);
    // 鱼眼下的太阳的ndc坐标 转 太阳的屏幕坐标
    vec4 positionInSunScreenCoord = positionInSunNdcCoord * 0.5 + 0.5;

    float currentDepth = positionInSunScreenCoord.z;    // 当前点的深度
    float dis = length(positionInWorldCoord.xyz) / far; 
    int radius = 2;
    float sum = pow(radius*2+1, 2);
    float shadowStrength = 0.3 * (1-dis);

    for(int x=-radius; x<=radius; x++) {
        for(int y=-radius; y<=radius; y++) {
            // 采样偏移
            vec2 offset = vec2(x,y) / shadowMapResolution;
            // 光照图中最近的点的深度
            float closest = texture2D(shadow, positionInSunScreenCoord.xy + offset).x;   
            // 如果当前点深度大于光照图中最近的点的深度 说明当前点在阴影中
            if(closest+0.001 <= currentDepth && dis<0.2) {
                sum -= 2; // 涂黑
            }           
        }
    }
    sum /= pow(radius*2+1, 2);
    color.rgb *= sum*shadowStrength + 1 - shadowStrength;  
    return color;
}


/* DRAWBUFFERS: 01 */
void main() {
    vec4 color = texture2D(texture, texcoord.st);

    float depth = texture2D(depthtex0, texcoord.st).x;
    
    vec4 positionInNdcCoord = vec4(texcoord.st*2-1, depth*2-1, 1);                          //坐标
    vec4 positionInClipCoord = gbufferProjectionInverse * positionInNdcCoord;               //剪切坐标
    vec4 positionInViewCoord = vec4(positionInClipCoord.xyz/positionInClipCoord.w, 1.0);    //NDC坐标
    vec4 positionInWorldCoord = gbufferModelViewInverse * positionInViewCoord;              //世界坐标
//    color = GetBloomColor(color);
    color = getShadow(color, positionInWorldCoord);
    gl_FragData[0] = color;
    gl_FragData[1] = GetBloomColor(color);

}
