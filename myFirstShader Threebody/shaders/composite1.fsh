#version 120

const bool gdepthMipmapEnabled = true;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

uniform float viewWidth;
uniform float viewHeight;

varying vec4 texcoord;

vec4 getScale(sampler2D src, vec2 pos, vec2 anchor, int fact) {
    vec2 newCoord = (pos - anchor) * pow(2, fact);
    float padding = 0.02 * pow(2, fact);
    if(newCoord.x<0-padding || newCoord.x>1+padding || newCoord.y<0-padding || newCoord.y>1+padding) {
        return vec4(0, 0, 0, 1);
    }
    vec4 sum = texture2D(src, newCoord);
    int radius = 3;
    float weightSum = 0;
    for(int i=0; i<radius; i++) {
        for(int j=0; j<radius; j++) {
            // 计算权重
            float weight = 1.0f - length(vec2(i, j)) / 3.5;
            weightSum += weight * 4;
            // 计算偏移
            vec2 offset = vec2(float(i)/viewWidth, float(j)/viewHeight) * pow(2, fact);
            // 左上左下右上右下采样4次
            sum.rgb += texture2D(src, newCoord+offset).rgb * weight;
            offset = vec2(-float(i)/viewWidth, float(j)/viewHeight) * pow(2, fact);
            sum.rgb += texture2D(src, newCoord+offset).rgb * weight;
            offset = vec2(float(i)/viewWidth, -float(j)/viewHeight) * pow(2, fact);
            sum.rgb += texture2D(src, newCoord+offset).rgb * weight;
            offset = vec2(-float(i)/viewWidth, -float(j)/viewHeight) * pow(2, fact);
            sum.rgb += texture2D(src, newCoord+offset).rgb * weight;
        }
    }
    sum.rgb /= weightSum;
    return sum; 
}

/* DRAWBUFFERS: 01 */
void main() {
    // 传递基色
    vec4 color = texture2D(colortex0, texcoord.st);
    gl_FragData[0] = color;

    // 计算不同分辨率的亮色纹理
    vec4 bloom = vec4(vec3(0), 1);
    bloom.rgb += getScale(colortex1, texcoord.st, vec2(0.0, 0.2), 2).rgb;
    bloom.rgb += getScale(colortex1, texcoord.st, vec2(0.3, 0.2), 3).rgb;
    bloom.rgb += getScale(colortex1, texcoord.st, vec2(0.5, 0.2), 4).rgb;
    bloom.rgb += getScale(colortex1, texcoord.st, vec2(0.6, 0.2), 5).rgb;
    bloom.rgb += getScale(colortex1, texcoord.st, vec2(0.7, 0.2), 6).rgb;
    bloom.rgb += getScale(colortex1, texcoord.st, vec2(0.8, 0.2), 7).rgb;
    bloom.rgb += getScale(colortex1, texcoord.st, vec2(0.9, 0.2), 8).rgb;

    gl_FragData[1] = bloom;

}