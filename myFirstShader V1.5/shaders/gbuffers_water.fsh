#version 120

uniform sampler2D texture;
uniform int worldTime;

varying vec3 myWaterColor;

varying vec4 texcoord;
varying vec4 color;

varying float id;        //方块id的容器

varying vec3 normal;                // 眼坐标法向量
varying vec4 positionInViewCoord;   // 眼坐标


void main() {
    // 00 计算视线和法线夹角余弦值并得到透射系数
    // *两单位向量点乘 再归一化到0，1区间内，得到视线与法线夹角
    // *透射系数采用菲涅尔方程的Fresnel-Schlick近似法
    float cosine = dot(normalize(positionInViewCoord.xyz), normalize(normal));
    cosine = clamp(abs(cosine), 0, 1);
    float r0 = 0.017 ;
    float factor =r0 + (1-r0)*pow(1.0 - cosine, 4);    // 透射系数

    // 01 输出水面颜色
    if(id!=10092) {
        gl_FragData[0] = color * texture2D(texture, texcoord.st);
        return;
    }

   gl_FragData[0] = vec4(mix(myWaterColor*0.3, myWaterColor, factor), 0.4);
//   gl_FragData[0] = vec4(myWaterColor, 0.4);
}
