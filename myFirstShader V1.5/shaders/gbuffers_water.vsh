#version 120

attribute vec2 mc_Entity;//MINECRAFT �������
uniform int worldTime;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;

varying float id;        //����id������

varying vec3 myWaterColor;

varying vec4 texcoord;
varying vec4 color;

varying vec3 normal;	// ��������ϵ�µķ�����
varying vec4 positionInViewCoord;	// ������

// 01 ������ɫ
vec3 waterColorArr[24] = {
    vec3(0.801,0.398,0.113),        // 0-1000       �ճ��׶�
    vec3(0.957,0.867,0.699),        // 1000 - 2000  ����
    vec3(0.0,0.746,0.996),        // 2000 - 3000
    vec3(0.0,0.746,0.996),        // 3000 - 4000
    vec3(0.0,0.746,0.996),        // 4000 - 5000 
    vec3(0.527,0.805,0.996),        // 5000 - 6000
    vec3(0.773,0.883,0.996),        // 6000 - 7000  ����
    vec3(0.773,0.883,0.996),        // 7000 - 8000
    vec3(0.773,0.883,0.996),        // 8000 - 9000
    vec3(0.094,0.453,0.801),        // 9000 - 10000
    vec3(0.094,0.453,0.801),        // 10000 - 11000 ����
    vec3(0.996,0.387,0.277),        // 11000 - 12000
    vec3(0.996,0.27,0.0),        // 12000 - 13000
    vec3(0.0,0.0,0.5),      // 13000 - 14000 ҹ��
    vec3(0.0,0.0,0.5),      // 14000 - 15000
    vec3(0.0,0.0,0.5),      // 15000 - 16000
    vec3(0.0,0.0,0.5),      // 16000 - 17000
    vec3(0.02, 0.2, 0.27),      // 17000 - 18000
    vec3(0.02, 0.2, 0.27),      // 18000 - 19000 ��ҹ
    vec3(0.02, 0.2, 0.27),      // 19000 - 20000
    vec3(0.02, 0.2, 0.27),      // 20000 - 21000
    vec3(0.02, 0.2, 0.27),      // 21000 - 22000 
    vec3(0.02, 0.2, 0.27),      // 22000 - 23000 ̫�������ڵ�ƽ��
    vec3(0.02, 0.2, 0.27)       // 23000 - 24000(0)
};


// 02 ���ƺ���
vec4 get_wave(vec4 positionInViewCoord)
{
        vec4 positionInWorldCoord = gbufferModelViewInverse * positionInViewCoord;  // ���ҵ��������ꡱ
        positionInWorldCoord.xyz += cameraPosition;                                 // �����������ת��Ϊ��������

/*        positionInWorldCoord.y += sin(positionInWorldCoord.z * 2) * 0.05;*/           //���Ӳ���
        positionInWorldCoord.y += sin(float(worldTime * 0.3)+positionInWorldCoord.x * 2) * 0.07;
        positionInWorldCoord.y += sin(float(worldTime * 0.12) + positionInWorldCoord.z * 2) * 0.05;

        positionInWorldCoord.xyz -= cameraPosition;                                 // ת�� ���ҵ��������ꡱ
        return gbufferModelView * positionInWorldCoord;                             // ת��������
}

//vec4 getBump(vec4 positionInViewCoord) {
//    vec4 positionInWorldCoord = gbufferModelViewInverse * positionInViewCoord;  // ���ҵ��������ꡱ
//    positionInWorldCoord.xyz += cameraPosition; // �������꣨�������꣩
//
//    // ���㰼͹
//    positionInWorldCoord.y += sin(positionInWorldCoord.z * 2) * 0.15;
//
//    positionInWorldCoord.xyz -= cameraPosition; // ת�� ���ҵ��������ꡱ
//    return gbufferModelView * positionInWorldCoord; // ����������
//}


void main() {
    //00 ͨ�����MVP�任����ȡ������
    positionInViewCoord = gl_ModelViewMatrix * gl_Vertex;   // mv�任��������

    //01 ���벨�ƺ����ı�ˮ���position
    if (mc_Entity.x == 10092) {  // �����ˮ����㰼͹
        gl_Position = gbufferProjection * get_wave(positionInViewCoord);  // p�任
    }
    else {    // ����ֱ�Ӵ�������
        gl_Position = gbufferProjection * positionInViewCoord;  // p�任
    }

   /* gl_Position = gbufferProjection * positionInViewCoord;*/
    color = gl_Color;   // ��ɫ
    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    
    //02 ʱ�䴫��
    int hour = worldTime / 1000; 
    myWaterColor = waterColorArr[hour];
    //03 ����id����
    id = mc_Entity.x;
    //04 ������ϵ�еķ��߼���
    normal = gl_NormalMatrix * gl_Normal;

}
