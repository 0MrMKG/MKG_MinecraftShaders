#version 120

varying vec4 texcoord;

void main() {
    // Ϊ��һ���Ĳü��ռ����긳ֵ
    gl_Position = ftransform();
    // �õ���ǰ������0������(������ͼ��)�ϵ�����
    texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;
}
