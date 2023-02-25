#version 120

uniform sampler2D texture;
uniform int worldTime;

varying vec3 myWaterColor;

varying vec4 texcoord;
varying vec4 color;

varying float id;        //����id������

varying vec3 normal;                // �����귨����
varying vec4 positionInViewCoord;   // ������


void main() {
    // 00 �������ߺͷ��߼н�����ֵ���õ�͸��ϵ��
    // *����λ������� �ٹ�һ����0��1�����ڣ��õ������뷨�߼н�
    // *͸��ϵ�����÷��������̵�Fresnel-Schlick���Ʒ�
    float cosine = dot(normalize(positionInViewCoord.xyz), normalize(normal));
    cosine = clamp(abs(cosine), 0, 1);
    float r0 = 0.017 ;
    float factor =r0 + (1-r0)*pow(1.0 - cosine, 4);    // ͸��ϵ��

    // 01 ���ˮ����ɫ
    if(id!=10092) {
        gl_FragData[0] = color * texture2D(texture, texcoord.st);
        return;
    }

   gl_FragData[0] = vec4(mix(myWaterColor*0.3, myWaterColor, factor), 0.4);
//   gl_FragData[0] = vec4(myWaterColor, 0.4);
}
