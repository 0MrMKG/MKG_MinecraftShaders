#version 120

const int shadowMapResolution = 1024*4;   // 阴影分辨率 默认 1024
const float	sunPathRotation	= -40.0;    // 太阳偏移角 默认 0

uniform sampler2D texture;
uniform sampler2D depthtex0;
uniform sampler2D shadow;
uniform sampler2D gdepth;
uniform sampler2D colortex2;
uniform sampler2D colortex3;

uniform ivec2 eyeBrightnessSmooth;

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

//001 鱼眼坐标变换函数 NDC->鱼眼处理的NDC
vec2 getFishEyeCoord(vec2 positionInNdcCoord) {
    return positionInNdcCoord / (0.15 + 0.85*length(positionInNdcCoord.xy));
}

//002 阴影处理函数 着色值,我的世界坐标->着色值
vec4 getShadow(vec4 color, vec4 positionInWorldCoord) {
    // 我的世界坐标 转 太阳的眼坐标
    vec4 positionInSunViewCoord = shadowModelView * positionInWorldCoord;
    // 太阳的眼坐标 转 太阳的裁剪坐标
    vec4 positionInSunClipCoord = shadowProjection * positionInSunViewCoord;
    // 太阳的裁剪坐标 转 太阳的ndc坐标
    vec4 positionInSunNdcCoord = vec4(positionInSunClipCoord.xyz/positionInSunClipCoord.w, 1.0);
    //鱼眼坐标转换（处理NDC坐标）
    positionInSunNdcCoord.xy = getFishEyeCoord(positionInSunNdcCoord.xy);
    // 太阳的鱼眼坐标 转 太阳的屏幕坐标
    vec4 positionInSunScreenCoord = positionInSunNdcCoord * 0.5 + 0.5;

    float currentDepth = positionInSunScreenCoord.z;    // 当前点的深度
    float dis = length(positionInWorldCoord.xyz) / far; //距离，范围[0,1]

    // 控制夜间阴影强度
    float isNight = texture2D(colortex3, texcoord.st).x; 
    
    int radius = 2;
    float sum = pow(radius*2+1, 2);
    float shadowStrength = 0.6 * (1-dis) * (1-0.6*isNight); //阴影强度 与距离反比 与isNight参数成反比
    for(int x=-radius; x<=radius; x++) {
        for(int y=-radius; y<=radius; y++) {
            // 采样偏移记x，y像素偏移除以分辨率
            vec2 offset = vec2(x,y) / shadowMapResolution;
            // 光照图中最近的点的深度对太阳的屏幕坐标加上偏移值求影子
            float closest = texture2D(shadow, positionInSunScreenCoord.xy + offset).x;   
            // 如果当前点深度大于光照图中最近的点的深度 说明当前点在阴影中
            if(closest+0.001 <= currentDepth && dis<0.2) {
                sum -= 1; // 涂黑
            }
        }
    }
    sum /= pow(radius*2+1, 2); //得到最终的sum值
    color.rgb *= sum*shadowStrength + (1-shadowStrength);  //处理最终得到的色彩值
    return color;
}

//003 获取高光部分 着色->着色（绘制泛光的方法一）
vec4 getBloomOriginColor(vec4 color) {
    float brightness = 0.299*color.r + 0.587*color.g + 0.114*color.b;
    if(brightness < 0.5) {
        color.rgb = vec3(0);
    }
    color.rgb *= (brightness-0.5)*2;
    return color;
}

//004 对于高光部分进行模糊处理（绘制泛光的方法一）
vec3 getBloom() {
    int radius = 15;
    vec3 sum = vec3(0);
    
    for(int i=-radius; i<=radius; i++) {
        for(int j=-radius; j<=radius; j++) {
            vec2 offset = vec2(i/viewWidth, j/viewHeight);
            sum += getBloomOriginColor(texture2D(texture, texcoord.st+offset)).rgb;
        }
    }
    
    sum /= pow(radius+1, 2);
    return sum*0.3;
}

//005 分类讨论绘制高光（绘制方法二）
vec4 getBloomSource(vec4 color) {
    // 绘制泛光
    vec4 bloom = color;
    float id = texture2D(colortex2, texcoord.st).x;
    float brightness = dot(bloom.rgb, vec3(0.2125, 0.7154, 0.0721));

    if(id==10089) {
        bloom.rgb *= 2 * vec3(6, 5, 1); //黄色发光方块
    }
    else if(id==10091) {
        bloom.rgb *= 5 * vec3(1.5, 1.5, 1.5); //蓝白色发光方块
    }
    // 火把 
    else if(id==10090) {
        if(brightness<0.5) {
            bloom.rgb = vec3(0);
        }
        bloom.rgb *= 40 * pow(brightness, 2);
    }
    // 其他方块
    else {
        bloom.rgb *= brightness;
        bloom.rgb = pow(bloom.rgb, vec3(1.0/2.2));
    }
    return bloom;
}

/* DRAWBUFFERS: 01 */
void main() {
    //vec4 color = texture2D(shadow, texcoord.st);
    vec4 color = texture2D(texture, texcoord.st);
    float depth = texture2D(depthtex0, texcoord.st).x;
    
    // 利用深度缓冲建立带深度的ndc坐标
    vec4 positionInNdcCoord = vec4(texcoord.st*2-1, depth*2-1, 1);
    // 逆投影变换 -- ndc坐标转到裁剪坐标
    vec4 positionInClipCoord = gbufferProjectionInverse * positionInNdcCoord;
    // 透视除法 -- 裁剪坐标转到眼坐标
    vec4 positionInViewCoord = vec4(positionInClipCoord.xyz/positionInClipCoord.w, 1.0);
    // 逆"视图模型"变换 -- 眼坐标转 “我的世界坐标” 
    vec4 positionInWorldCoord = gbufferModelViewInverse * positionInViewCoord;

    // 不是发光方块则绘制阴影
    float id = texture2D(colortex2, texcoord.st).x;
    if(id!=10089 && id!=10090) {
        color = getShadow(color, positionInWorldCoord);
    }

    gl_FragData[0] = color; // 基色
    gl_FragData[1] = getBloomSource(color); // 传递高光原图
}