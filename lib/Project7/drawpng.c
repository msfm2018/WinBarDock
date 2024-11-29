#include <stdio.h>
#include <stdlib.h>
#include <png.h>
#include <cairo.h>
#include <math.h>
#include <wchar.h>  // Ϊ���ַ�֧�����ͷ�ļ�
#define M_PI 3.14159265358979323846

#define IMAGE_WIDTH 125
#define IMAGE_HEIGHT 125
#define SCALE_FACTOR 3  // ��߷ֱ��ʵı���
#define MAX_FONT_SIZE 30  // ������������С
#define MIN_FONT_SIZE 10   // ������С�����С

// �����ʺϵ������С
double calculate_font_size(cairo_t* cr, const char* text, int image_width, int image_height) {
    double font_size = MAX_FONT_SIZE;

    // ����֧�����ĵ�����
    cairo_select_font_face(cr, "Microsoft YaHei", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);

    while (font_size >= MIN_FONT_SIZE) {
        cairo_set_font_size(cr, font_size);
        cairo_text_extents_t extents;
        cairo_text_extents(cr, text, &extents);

        // ����ı���Ⱥ͸߶�С��ͼ��ĳߴ磬˵��������Ӧ
        if (extents.width < image_width - 40 && extents.height < image_height - 40) {
            break;
        }

        font_size -= 2;  // ��С�����С
    }

    return font_size;
}

__declspec(dllexport) void write_png_with_text(const char* filename, const char* text) {
    int high_res_width = IMAGE_WIDTH * SCALE_FACTOR;
    int high_res_height = IMAGE_HEIGHT * SCALE_FACTOR;

    cairo_surface_t* surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, high_res_width, high_res_height);
    cairo_t* cr = cairo_create(surface);

    // ���ÿ����
    cairo_set_antialias(cr, CAIRO_ANTIALIAS_SUBPIXEL);

    // ����͸������
    cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0); // ����͸��
    cairo_paint(cr); // ��䱳��

    //// ����Բ������Ľ��䱳��
    //cairo_pattern_t* gradient = cairo_pattern_create_radial(
    //    high_res_width / 2, high_res_height / 2, 0,  // ��Բ�ģ��뾶Ϊ0
    //    high_res_width / 2, high_res_height / 2, high_res_width / 2  // ��Բ���뾶Ϊͼ��İ뾶
    //);

    //// ���ý������ɫ������ԲΪ��ɫ����ԲΪ��ɫ
    //cairo_pattern_add_color_stop_rgb(gradient, 0, 0.2, 0.4, 0.8);  // ��Բ��ɫ����ɫ��
    //cairo_pattern_add_color_stop_rgb(gradient, 1, 0.5, 0.2, 0.7);  // ��Բ��ɫ����ɫ��

    //// ������Ӧ�õ�Բ�α�������
    //cairo_set_source(cr, gradient);
    //cairo_arc(cr, high_res_width / 2, high_res_height / 2, high_res_width / 2, 0, 2 * M_PI); // Բ��·��
    //cairo_fill(cr); // ���Բ��

        // ����߷ֱ�����Բ�εİ뾶
    double circle_radius = (high_res_width < high_res_height ? high_res_width : high_res_height) / 2 - 2; // ��2px�߾������

    // ��������ɫ����ɫ�ľ��򽥱䱳��
    cairo_pattern_t* gradient = cairo_pattern_create_radial(
        high_res_width / 2, high_res_height / 2, 0,
        high_res_width / 2, high_res_height / 2, circle_radius
    );

    // ���ý�����ɫ
    cairo_pattern_add_color_stop_rgb(gradient, 0, 0.2, 0.4, 0.8); // ��Բ����ɫ��
    cairo_pattern_add_color_stop_rgb(gradient, 1, 0.5, 0.2, 0.7); // ��Բ����ɫ��

    // Ӧ�ý��䲢����Բ��
    cairo_set_source(cr, gradient);
    cairo_arc(cr, high_res_width / 2, high_res_height / 2, circle_radius, 0, 2 * M_PI);
    cairo_fill(cr);


    // �����ʺϵ������С
    double font_size = calculate_font_size(cr, text, IMAGE_WIDTH, IMAGE_HEIGHT);

    // ����֧�����ĵ�����
    cairo_select_font_face(cr, "Microsoft YaHei", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
    cairo_set_font_size(cr, font_size * SCALE_FACTOR);  // �Ŵ���������Ӧ�߷ֱ���

    // �������ֵĳߴ�
    cairo_text_extents_t extents;
    cairo_text_extents(cr, text, &extents);

    // �����ı�����λ��
    double x = (high_res_width - extents.width) / 2 - extents.x_bearing;
    double y = (high_res_height - extents.height) / 2 - extents.y_bearing;

    // ����������ɫΪ��ɫ���뽥�䱳���Աȣ�
    cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);

    // ��������
    cairo_move_to(cr, x, y);
    cairo_show_text(cr, text);

    // ����Ϊ PNG �ļ�
    cairo_surface_write_to_png(surface, filename);

    // ����
    cairo_destroy(cr);
    cairo_surface_destroy(surface);
}

