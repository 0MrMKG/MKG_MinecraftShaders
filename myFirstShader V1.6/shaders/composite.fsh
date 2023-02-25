#version 120

const int shadowMapResolution = 1024*4;   // 阴影分辨率 默认 1024
const float	sunPathRotation	= -40.0;    // 太阳偏移角 默认 0
const int noiseTextureResolution = 128;     // 噪声图分辨率

uniform sampler2D texture;
uniform sampler2D depthtex0;
uniform sampler2D shadow;
uniform sampler2D gdepth;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D noisetex;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 cameraPosition;	

uniform int worldTime;

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

varying float isNight;

varying vec3 mySkyColor;
varying vec3 mySunColor;
varying vec3 mySunColor_2;
varying vec3 mySunColor_3;

varying vec4 texcoord;

//000 时间转换器
int GetTime()
{
    int Time;
    if(0<worldTime && worldTime<12000) {
        Time = 1;    // 白天
    }
    else if(12000<=worldTime && worldTime<=14000) {
        Time = 2;    // 傍晚
    }
    else if(14000<=worldTime && worldTime<=23000) {
        Time = 3;    // 晚上
    }
    else if(23000<worldTime) {
        Time = 4;   // 拂晓
    }
    return Time;
}


//001 鱼眼坐标变换函数 NDC->鱼眼处理的NDC
vec2 getFishEyeCoord(vec2 positionInNdcCoord) {
    return positionInNdcCoord / (0.15 + 0.85*length(positionInNdcCoord.xy));
}

//002 阴影处理函数 着色值,我的世界坐标->着色值
vec4 getShadow(vec4 color, vec4 positionInWorldCoord) {
    vec4 temp = texture2D(colortex4, texcoord.st); 
    vec3 normal = temp.xyz;
    float isWater = temp.w;
    if (isWater)
    {
    return color;
    }

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

//006 编写天空-设定时间阈值
vec3 skyColorArr[24] = {
    vec3(0.1, 0.6, 0.9),        // 0-1000
    vec3(0.1, 0.6, 0.9),        // 1000 - 2000
    vec3(0.1, 0.6, 0.9),        // 2000 - 3000
    vec3(0.1, 0.6, 0.9),        // 3000 - 4000
    vec3(0.1, 0.6, 0.9),        // 4000 - 5000 
    vec3(0.1, 0.6, 0.9),        // 5000 - 6000
    vec3(0.1, 0.6, 0.9),        // 6000 - 7000
    vec3(0.1, 0.6, 0.9),        // 7000 - 8000
    vec3(0.1, 0.6, 0.9),        // 8000 - 9000
    vec3(0.1, 0.6, 0.9),        // 9000 - 10000
    vec3(0.1, 0.6, 0.9),        // 10000 - 11000
    vec3(0.1, 0.6, 0.9),        // 11000 - 12000
    vec3(0.1, 0.6, 0.9),        // 12000 - 13000
    vec3(0.02, 0.2, 0.27),      // 13000 - 14000
    vec3(0.02, 0.2, 0.27),      // 14000 - 15000
    vec3(0.02, 0.2, 0.27),      // 15000 - 16000
    vec3(0.02, 0.2, 0.27),      // 16000 - 17000
    vec3(0.02, 0.2, 0.27),      // 17000 - 18000
    vec3(0.02, 0.2, 0.27),      // 18000 - 19000
    vec3(0.02, 0.2, 0.27),      // 19000 - 20000
    vec3(0.02, 0.2, 0.27),      // 20000 - 21000
    vec3(0.02, 0.2, 0.27),      // 21000 - 22000
    vec3(0.02, 0.2, 0.27),      // 22000 - 23000
    vec3(0.02, 0.2, 0.27)       // 23000 - 24000(0)
};


////006* 随时间更改天空颜色
//vec3 changeSkyColorByTime()
//{
//    float isNight = texture2D(colortex3, texcoord.st).x;
//
//    if (isNight<1&&isNight>0)
//    return vec3(0.1,0.04,0.02);
//    if (isNight==1)
//    return vec3(0,0,0);
//    else
//    return vec3(0,0,0);
//}
//
//vec3 changeSunColorByTime()
//{
//    float isNight = texture2D(colortex3, texcoord.st).x;
//
//    if (isNight<1&&isNight>0)
//    return vec3(10,0,0);
//    else
//    return vec3(1,1,1);
//}


//007 绘制天空函数
vec3 drawSky(vec3 color, vec4 positionInViewCoord, vec4 positionInWorldCoord) {

    float dis = length(positionInWorldCoord.xyz) / far;
    vec3 mySunColor = vec3(10,1,1);
    vec3 mySkyColor = vec3(0.527,0.805,0.918);

    if (GetTime()==1)
    {
    mySunColor = vec3(1,1,1);
    mySkyColor = vec3(0.527,0.805,0.918);
    }
    else if(GetTime()==2)
    {
    mySunColor = vec3(1,0.5,0);
    mySkyColor = vec3(0.5,0.1,0.01);
    }
    else if(GetTime()==3)
    {
    mySunColor = vec3(0,0,0);
    mySkyColor = vec3(0,0,0.01);
    }
    // 眼坐标系中的点到太阳的距离
    float disToSun = 1.0 - dot(normalize(positionInViewCoord.xyz), normalize(sunPosition));     // 太阳
    float disToMoon = 1.0 - dot(normalize(positionInViewCoord.xyz), normalize(moonPosition));    // 月亮
    // 绘制圆形太阳1号
    vec3 drawSun = vec3(0);
    if(disToSun<0.003 && dis>0.99999) {
        drawSun = mySunColor * (1.0-isNight);
    }
    // 绘制圆形月亮
    vec3 drawMoon = vec3(0);
    if(disToMoon<0.001 && dis>0.99999) {
        drawMoon = mySunColor * isNight;
    } 
    // 雾和太阳颜色混合
    float sunMixFactor = clamp(1.0 - disToSun, 0, 1) * (1.0-isNight);
    vec3 finalColor = mix(mySkyColor, mySunColor, pow(sunMixFactor, 4));
//  vec3 finalColor = mix(mySkyColor, mySunColor,10);

    // 雾和月亮颜色混合
    float moonMixFactor = clamp(1.0 - disToMoon, 0, 1) * isNight;
    finalColor = mix(finalColor, mySunColor, pow(moonMixFactor, 4));
//    finalColor = mix(finalColor, mySunColor, 10);

    // 根据距离进行最终颜色的混合
    return mix(color, finalColor, clamp(pow(dis, 3), 0, 1)) + drawSun + drawMoon;
}


// 008 绘制水面反射 
// 008-01 绘制假太阳月亮
vec3 drawFakeSky(vec4 positionInViewCoord) {
    float dis = length(positionInViewCoord.xyz) / far;
    // 眼坐标系中的点到太阳的距离
    float disToSun = 1.0 - dot(normalize(positionInViewCoord.xyz), normalize(sunPosition));     // 太阳
    float disToMoon = 1.0 - dot(normalize(positionInViewCoord.xyz), normalize(moonPosition));    // 月亮
    
    vec3 mySkyColor = vec3(0.0,0.746,0.996);

    // 颜色混合
    float sunMixFactor = clamp(1.0 - disToSun, 0, 1) * (1.0-isNight);
    vec3 finalColor = mix(mySkyColor, mySunColor, pow(sunMixFactor, 4));
    float moonMixFactor = clamp(1.0 - disToMoon, 0, 1) * isNight;
    finalColor = mix(finalColor, mySunColor, pow(moonMixFactor, 4));

    // 根据距离进行最终颜色的混合
    return finalColor;
}

vec3 draw_fake_sun_moon(vec4 positionInViewCoord)
{   
    vec3 mySunColor = vec3(1,1,1);

    float disToSun = 1.0 - dot(normalize(positionInViewCoord.xyz), normalize(sunPosition));     // 太阳
    float disToMoon = 1.0 - dot(normalize(positionInViewCoord.xyz), normalize(moonPosition));    // 月亮
    // 绘制
    vec3 drawSun = vec3(0);
    if(disToSun<0.003) {
        drawSun = mySunColor * 2 * (1.0-isNight);
    }
    vec3 drawMoon = vec3(0);
    if(disToMoon<0.001) {
        drawMoon = mySunColor * 2 * isNight;
    }
    return drawSun+drawMoon;
}



//009波浪处理
// 009-01 波纹颜色
vec3 waterColorArr[24] = {
    vec3(0.801,0.398,0.113),        // 0-1000       日出阶段
    vec3(0.684,0.93,0.93),        // 1000 - 2000  白日
    vec3(0.684,0.93,0.93),        // 2000 - 3000
    vec3(0.684,0.93,0.93),        // 3000 - 4000
    vec3(0.957,0.867,0.699),        // 4000 - 5000 
    vec3(0.957,0.867,0.699),        // 5000 - 6000
    vec3(0.773,0.883,0.996),        // 6000 - 7000  正午
    vec3(0.773,0.883,0.996),        // 7000 - 8000
    vec3(0.773,0.883,0.996),        // 8000 - 9000
    vec3(0.094,0.453,0.801),        // 9000 - 10000
    vec3(0.094,0.453,0.801),        // 10000 - 11000 日落
    vec3(0.996,0.387,0.277),        // 11000 - 12000
    vec3(0.996,0.27,0.0),        // 12000 - 13000
    vec3(0.0,0.0,0.5),      // 13000 - 14000 夜晚
    vec3(0.0,0.0,0.5),      // 14000 - 15000
    vec3(0.0,0.0,0.5),      // 15000 - 16000
    vec3(0.0,0.0,0.5),      // 16000 - 17000
    vec3(0.02, 0.2, 0.27),      // 17000 - 18000
    vec3(0.02, 0.2, 0.27),      // 18000 - 19000 半夜
    vec3(0.02, 0.2, 0.27),      // 19000 - 20000
    vec3(0.02, 0.2, 0.27),      // 20000 - 21000
    vec3(0.02, 0.2, 0.27),      // 21000 - 22000 
    vec3(0.02, 0.2, 0.27),      // 22000 - 23000 太阳出现在地平线
    vec3(0.02, 0.2, 0.27)       // 23000 - 24000(0)
};

// 009-02 波纹函数，已经实现
vec4 get_wave(vec4 positionInViewCoord)
{
        vec4 positionInWorldCoord = gbufferModelViewInverse * positionInViewCoord;  // “我的世界坐标”
        positionInWorldCoord.xyz += cameraPosition;                                 // 加上相机坐标转换为世界坐标

/*        positionInWorldCoord.y += sin(positionInWorldCoord.z * 2) * 0.05;*/           //增加波纹
        positionInWorldCoord.y += sin(float(worldTime * 0.332)+positionInWorldCoord.x * 2) * 0.05;
        positionInWorldCoord.y += cos(float(worldTime * 0.123) + positionInWorldCoord.z * 2) * 0.03;
        positionInWorldCoord.y += sin(float(worldTime * 0.2)+positionInWorldCoord.x * 2) * 0.04;
        positionInWorldCoord.y += cos(float(worldTime * 0.51) + positionInWorldCoord.z * 2) * 0.02;
        
        positionInWorldCoord.xyz -= cameraPosition;                                 // 转回 “我的世界坐标”
        return gbufferModelView * positionInWorldCoord;                             // 转回眼坐标
}
// 009-03 波浪参数(为了下面改法线)
float getWave(vec4 positionInWorldCoord) {

    // 小波浪
    float speed1 = float(worldTime) / (noiseTextureResolution * 15);
    vec3 coord1 = positionInWorldCoord.xyz / noiseTextureResolution;
    coord1.x *= 3;
    coord1.x += speed1;
    coord1.z += speed1 * 0.2;
    float noise1 = texture2D(noisetex, coord1.xz).x;
    return noise1 * 0.4 +0.3;

//    // 混合波浪
//    float speed2 = float(worldTime) / (noiseTextureResolution * 7);
//    vec3 coord2 = positionInWorldCoord.xyz / noiseTextureResolution;
//    coord2.x *= 2;
//    coord2.x -= speed2 * 0.15 + noise1 * 0.1;  // 加入第一个波浪的噪声
//    coord2.z -= speed2 * 0.7 - noise1 * 0.1;
//    float noise2 = texture2D(noisetex, coord2.xz).x;
//
//    return noise2 * 0.4 + 0.3;
}


// 009-04 最终合成波浪颜色
vec3 drawWater(vec3 color, vec4 positionInWorldCoord, vec4 positionInViewCoord, vec3 normal) {
   
   //加入抖动量
    vec3 newnormal = normal;
    newnormal.z +=  0.05 * (((getWave(positionInWorldCoord)-0.4)/0.6) * 2 - 1);;
    newnormal = normalize(newnormal);

    vec3 reflectDirection = reflect(positionInViewCoord.xyz, newnormal);
    int hour = worldTime / 1000; 
    vec3 finalColor =  waterColorArr[hour];

    positionInWorldCoord.xyz += cameraPosition; // 转为世界坐标（绝对坐标）

    //计算透射系数
    float cosine = dot(normalize(positionInViewCoord.xyz), normalize(normal));
    cosine = clamp(abs(cosine), 0, 1);
    float r0 = 0.17 ;
    float factor =r0 + (1-r0)*pow(1.0 - cosine, 4);
    
    //融合
    finalColor = mix(color, finalColor, factor) ;
    finalColor += draw_fake_sun_moon(vec4(reflectDirection, 0));

    return finalColor;
}



/* DRAWBUFFERS: 01 */
void main() {
    //vec4 color = texture2D(shadow, texcoord.st);
    vec4 color = texture2D(texture, texcoord.st);
    vec4 temp = texture2D(colortex4, texcoord.st);      //传递法线
    float depth = texture2D(depthtex0, texcoord.st).x;  //水底深度
    float id = texture2D(colortex2, texcoord.st).x;     //物体id值
    
    // main-01-基础MVP变换
    // 利用深度缓冲建立带深度的ndc坐标
    vec4 positionInNdcCoord = vec4(texcoord.st*2-1, depth*2-1, 1);
    // 逆投影变换 -- ndc坐标转到裁剪坐标
    vec4 positionInClipCoord = gbufferProjectionInverse * positionInNdcCoord;
    // 透视除法 -- 裁剪坐标转到眼坐标
    vec4 positionInViewCoord = vec4(positionInClipCoord.xyz/positionInClipCoord.w, 1.0);
    // 逆"视图模型"变换 -- 眼坐标转 “我的世界坐标” 
    vec4 positionInWorldCoord = gbufferModelViewInverse * positionInViewCoord;

    // main-02-基础水面绘制
    vec3 normal = temp.xyz;
    float isWater = temp.w;
    if(isWater==1) {
        color.rgb = drawWater(color.rgb, positionInWorldCoord, positionInViewCoord, normal);
    }

    // main-03-阴影绘制
    if(id!=10089 && id!=10090) {
        color = getShadow(color, positionInWorldCoord);
    }

    // main-04-绘制天空
    color.rgb = drawSky(color.rgb, positionInViewCoord, positionInWorldCoord);


    gl_FragData[0] = color; // 基色
    gl_FragData[1] = getBloomSource(color); // 传递高光原图
}