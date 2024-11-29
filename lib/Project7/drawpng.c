#include <stdio.h>
#include <stdlib.h>
#include <png.h>
#include <cairo.h>
#include <math.h>
#include <wchar.h>  // 为宽字符支持添加头文件
#define M_PI 3.14159265358979323846

#define IMAGE_WIDTH 125
#define IMAGE_HEIGHT 125
#define SCALE_FACTOR 3  // 提高分辨率的倍数
#define MAX_FONT_SIZE 30  // 设置最大字体大小
#define MIN_FONT_SIZE 10   // 设置最小字体大小

// 计算适合的字体大小
double calculate_font_size(cairo_t* cr, const char* text, int image_width, int image_height) {
    double font_size = MAX_FONT_SIZE;

    // 设置支持中文的字体
    cairo_select_font_face(cr, "Microsoft YaHei", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);

    while (font_size >= MIN_FONT_SIZE) {
        cairo_set_font_size(cr, font_size);
        cairo_text_extents_t extents;
        cairo_text_extents(cr, text, &extents);

        // 如果文本宽度和高度小于图像的尺寸，说明可以适应
        if (extents.width < image_width - 40 && extents.height < image_height - 40) {
            break;
        }

        font_size -= 2;  // 缩小字体大小
    }

    return font_size;
}

__declspec(dllexport) void write_png_with_text(const char* filename, const char* text) {
    int high_res_width = IMAGE_WIDTH * SCALE_FACTOR;
    int high_res_height = IMAGE_HEIGHT * SCALE_FACTOR;

    cairo_surface_t* surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, high_res_width, high_res_height);
    cairo_t* cr = cairo_create(surface);

    // 启用抗锯齿
    cairo_set_antialias(cr, CAIRO_ANTIALIAS_SUBPIXEL);

    // 绘制透明背景
    cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0); // 背景透明
    cairo_paint(cr); // 填充背景

    //// 创建圆形区域的渐变背景
    //cairo_pattern_t* gradient = cairo_pattern_create_radial(
    //    high_res_width / 2, high_res_height / 2, 0,  // 内圆心，半径为0
    //    high_res_width / 2, high_res_height / 2, high_res_width / 2  // 外圆，半径为图像的半径
    //);

    //// 设置渐变的颜色：从内圆为蓝色到外圆为紫色
    //cairo_pattern_add_color_stop_rgb(gradient, 0, 0.2, 0.4, 0.8);  // 内圆颜色（蓝色）
    //cairo_pattern_add_color_stop_rgb(gradient, 1, 0.5, 0.2, 0.7);  // 外圆颜色（紫色）

    //// 将渐变应用到圆形背景区域
    //cairo_set_source(cr, gradient);
    //cairo_arc(cr, high_res_width / 2, high_res_height / 2, high_res_width / 2, 0, 2 * M_PI); // 圆形路径
    //cairo_fill(cr); // 填充圆形

        // 计算高分辨率下圆形的半径
    double circle_radius = (high_res_width < high_res_height ? high_res_width : high_res_height) / 2 - 2; // 留2px边距避免锯齿

    // 创建从蓝色到紫色的径向渐变背景
    cairo_pattern_t* gradient = cairo_pattern_create_radial(
        high_res_width / 2, high_res_height / 2, 0,
        high_res_width / 2, high_res_height / 2, circle_radius
    );

    // 设置渐变颜色
    cairo_pattern_add_color_stop_rgb(gradient, 0, 0.2, 0.4, 0.8); // 内圆（蓝色）
    cairo_pattern_add_color_stop_rgb(gradient, 1, 0.5, 0.2, 0.7); // 外圆（紫色）

    // 应用渐变并绘制圆形
    cairo_set_source(cr, gradient);
    cairo_arc(cr, high_res_width / 2, high_res_height / 2, circle_radius, 0, 2 * M_PI);
    cairo_fill(cr);


    // 计算适合的字体大小
    double font_size = calculate_font_size(cr, text, IMAGE_WIDTH, IMAGE_HEIGHT);

    // 设置支持中文的字体
    cairo_select_font_face(cr, "Microsoft YaHei", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
    cairo_set_font_size(cr, font_size * SCALE_FACTOR);  // 放大字体以适应高分辨率

    // 计算文字的尺寸
    cairo_text_extents_t extents;
    cairo_text_extents(cr, text, &extents);

    // 计算文本居中位置
    double x = (high_res_width - extents.width) / 2 - extents.x_bearing;
    double y = (high_res_height - extents.height) / 2 - extents.y_bearing;

    // 设置文字颜色为白色（与渐变背景对比）
    cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);

    // 绘制文字
    cairo_move_to(cr, x, y);
    cairo_show_text(cr, text);

    // 保存为 PNG 文件
    cairo_surface_write_to_png(surface, filename);

    // 清理
    cairo_destroy(cr);
    cairo_surface_destroy(surface);
}

