#version 120

varying vec4 texcoord;

uniform sampler2D process_blur_1;
uniform sampler2D process_blur_2;

uniform float viewWidth;
uniform float viewHeight;

/* DRAWBUFFERS: 01 */
void main() {

    //pass all the original color to 0
    vec4 color = texture2D(process_blur_1, texcoord.st);
    gl_FragData[0] = color;

    //process the highlight part(blur)
    int radius = 2;
    vec3 sum = texture2D(process_blur_2, texcoord.st).rgb;
    for (int i=-radius;i<=radius;i++)
    {
        vec2 row = vec2(0, i/viewHeight);
        sum += texture2D(process_blur_2, texcoord.st+row).rgb;
    }
    sum /= radius*2+1;
    gl_FragData[1] = vec4(sum, 1.0);
}