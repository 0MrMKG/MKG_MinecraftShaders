#version 120

attribute vec2 mc_Entity;//MINECRAFT 方块参数
uniform int worldTime;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;

varying float id;        //方块id的容器

varying vec3 myWaterColor;

varying vec4 texcoord;
varying vec4 color;

varying vec3 normal;	// 在眼坐标系下的法向量
varying vec4 positionInViewCoord;	// 眼坐标

// 01 波纹颜色
vec3 waterColorArr[24] = {
    vec3(0.801,0.398,0.113),        // 0-1000       日出阶段
    vec3(0.957,0.867,0.699),        // 1000 - 2000  白日
    vec3(0.0,0.746,0.996),        // 2000 - 3000
    vec3(0.0,0.746,0.996),        // 3000 - 4000
    vec3(0.0,0.746,0.996),        // 4000 - 5000 
    vec3(0.527,0.805,0.996),        // 5000 - 6000
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


// 02 波纹函数
vec4 get_wave(vec4 positionInViewCoord)
{
        vec4 positionInWorldCoord = gbufferModelViewInverse * positionInViewCoord;  // “我的世界坐标”
        positionInWorldCoord.xyz += cameraPosition;                                 // 加上相机坐标转换为世界坐标

/*        positionInWorldCoord.y += sin(positionInWorldCoord.z * 2) * 0.05;*/           //增加波纹
        positionInWorldCoord.y += sin(float(worldTime * 0.3)+positionInWorldCoord.x * 2) * 0.07;
        positionInWorldCoord.y += sin(float(worldTime * 0.12) + positionInWorldCoord.z * 2) * 0.05;

        positionInWorldCoord.xyz -= cameraPosition;                                 // 转回 “我的世界坐标”
        return gbufferModelView * positionInWorldCoord;                             // 转回眼坐标
}

//vec4 getBump(vec4 positionInViewCoord) {
//    vec4 positionInWorldCoord = gbufferModelViewInverse * positionInViewCoord;  // “我的世界坐标”
//    positionInWorldCoord.xyz += cameraPosition; // 世界坐标（绝对坐标）
//
//    // 计算凹凸
//    positionInWorldCoord.y += sin(positionInWorldCoord.z * 2) * 0.15;
//
//    positionInWorldCoord.xyz -= cameraPosition; // 转回 “我的世界坐标”
//    return gbufferModelView * positionInWorldCoord; // 返回眼坐标
//}


void main() {
    //00 通过拆解MVP变换，获取眼坐标
    positionInViewCoord = gl_ModelViewMatrix * gl_Vertex;   // mv变换计算眼坐

    //01 插入波纹函数改变水面的position
    if (mc_Entity.x == 10092) {  // 如果是水则计算凹凸
        gl_Position = gbufferProjection * get_wave(positionInViewCoord);  // p变换
    }
    else {    // 否则直接传递坐标
        gl_Position = gbufferProjection * positionInViewCoord;  // p变换
    }

   /* gl_Position = gbufferProjection * positionInViewCoord;*/
    color = gl_Color;   // 基色
    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    
    //02 时间传参
    int hour = worldTime / 1000; 
    myWaterColor = waterColorArr[hour];
    //03 方块id传参
    id = mc_Entity.x;
    //04 眼坐标系中的法线计算
    normal = gl_NormalMatrix * gl_Normal;

}
