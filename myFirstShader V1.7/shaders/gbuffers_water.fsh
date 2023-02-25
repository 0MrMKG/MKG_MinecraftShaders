#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;

uniform vec3 cameraPosition;

uniform int worldTime;

varying float id;

varying vec3 normal;    // 法向量在眼坐标系下

varying vec4 texcoord;
varying vec4 color;
varying vec4 lightMapCoord;

/* DRAWBUFFERS: 04 */
void main() {
    vec4 light = texture2D(lightmap, lightMapCoord.st); // 光照
    if(id!=10092) {
        gl_FragData[0] = color * texture2D(texture, texcoord.st) * light;   // 不是水面则正常绘制纹理
        gl_FragData[1] = vec4(normal,0);   // 法线，但是不是水
    } else {    // 是水面则输出 vec3(0.05, 0.2, 0.3)
        gl_FragData[0] = vec4(vec3(0.25,0.875,0.812), 0.1);   // 基色
        gl_FragData[1] = vec4(normal,1);   // 法线，水
    }
}