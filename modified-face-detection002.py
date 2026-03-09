import os
import dlib
import cv2
import numpy as np
from glob import glob
import copy

# 定义输入和输出文件夹
input_folders = ["photo1t36", "photo37t68"]
output_folder = "marked_faces0306"

# 创建输出文件夹（如果不存在）
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# 加载人脸检测器和关键点预测器
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")

# 定义面部区域的索引范围
# 眉毛+眼睛: 点17-47 (包括眉毛17-26和左右眼36-47)
# 鼻子: 点27-35
# 嘴巴: 点48-67
eyes_brows_indices = list(range(17, 27)) + list(range(36, 48))  # 眉毛和眼睛
nose_indices = list(range(27, 36))
mouth_indices = list(range(48, 68))

# 可调整参数（默认值）
eye_vertical_expansion = 10  # 眼部框的向下扩展像素值
nose_width_expansion = 10    # 鼻子梯形底部加宽像素值
mouth_width_expansion = 10   # 嘴巴方框左右加宽像素值

# 创建一个空白的复合图像（白色背景）
# 使用与输入图像相同的尺寸：350x500
image_width = 350
image_height = 500
# 图像中心线
image_center_x = image_width // 2

composite_img = np.ones((image_height, image_width, 3), dtype=np.uint8) * 255
composite_with_boxes_img = np.ones((image_height, image_width, 3), dtype=np.uint8) * 255
composite_with_expanded_boxes_img = np.ones((image_height, image_width, 3), dtype=np.uint8) * 255

# 记录处理的人脸总数
total_faces = 0

# 记录最后处理的人脸图像
last_face_image = None

# 从图像中提取面部特征点
def extract_landmarks(image_path):
    global total_faces, last_face_image
    
    # 读取图像
    img = cv2.imread(image_path)
    
    if img is None:
        print(f"无法读取图像: {image_path}")
        return []
    
    # 记录最后处理的图像
    last_face_image = img.copy()
    
    # 转换为灰度图（用于检测）
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # 检测人脸
    faces = detector(gray, 1)
    
    landmarks_list = []
    
    # 遍历每个检测到的人脸
    for face in faces:
        # 预测68个关键点
        landmarks = predictor(gray, face)
        
        # 提取关键点坐标
        points = []
        for i in range(68):
            x = landmarks.part(i).x
            y = landmarks.part(i).y
            points.append((i, x, y))
        
        landmarks_list.append(points)
        total_faces += 1
    
    return landmarks_list

# 创建围绕图像中心线对称的边框函数
def create_image_centered_symmetric_box(points, shape_type="box", 
                                       vertical_expansion_down=0, 
                                       vertical_expansion_up=0, 
                                       horizontal_expansion=0, 
                                       trapezoid_top_ratio=0.8,
                                       is_nose=False,
                                       is_mouth=False,
                                       nose_width_expansion=0,
                                       mouth_width_expansion=0):
    """创建一个围绕图像中心线对称的框
    
    参数:
        points: 包含点信息的列表
        shape_type: "box"为矩形框, "trapezoid"为上部为梯形的框
        vertical_expansion_down: 框的向下扩展像素值
        vertical_expansion_up: 框的向上扩展像素值
        horizontal_expansion: 框的左右扩展像素值
        trapezoid_top_ratio: 梯形上边宽度与下边宽度的比例 (0.8表示上边是下边的80%)
        is_nose: 是否为鼻子框
        is_mouth: 是否为嘴巴框
        nose_width_expansion: 鼻子梯形底部额外加宽像素值
        mouth_width_expansion: 嘴巴方框左右额外加宽像素值
    """
    if not points:
        return None
    
    # 提取所有x和y坐标
    x_coords = [p[1] for p in points]
    y_coords = [p[2] for p in points]
    
    # 找到最小和最大的y坐标
    min_y = min(y_coords) - vertical_expansion_up  # 上边界扩展
    max_y = max(y_coords) + vertical_expansion_down  # 下边界扩展
    
    # 计算到图像中心线的最大距离
    max_dist = max([abs(x - image_center_x) for x in x_coords] + [max(abs(min(x_coords) - image_center_x), abs(max(x_coords) - image_center_x))])
    
    # 创建对称框的坐标，加上水平扩展值
    additional_width = 0
    if is_nose:
        additional_width = nose_width_expansion  # 为鼻子梯形底部额外加宽
    elif is_mouth:
        additional_width = mouth_width_expansion  # 为嘴巴框左右额外加宽
    
    left_x = image_center_x - max_dist - horizontal_expansion - additional_width
    right_x = image_center_x + max_dist + horizontal_expansion + additional_width
    
    if shape_type == "trapezoid":
        # 计算中点y坐标（用于分隔梯形和矩形部分）
        mid_y = (min_y + max_y) // 2
        
        # 计算梯形上边的起点和终点
        top_width = max_dist * 2 * trapezoid_top_ratio * 0.1  # 梯形上边的宽度是下边宽度的一定比例
        top_left_x = image_center_x - (top_width / 2)
        top_right_x = image_center_x + (top_width / 2)
        
        # 返回六个点：梯形左上，梯形右上，梯形右下（也是矩形右上），矩形右下，矩形左下，梯形左下（也是矩形左上）
        # 确保所有坐标都是整数
        return [(int(top_left_x), int(min_y)), (int(top_right_x), int(min_y)), 
                (int(right_x), int(mid_y)), (int(right_x), int(max_y)), 
                (int(left_x), int(max_y)), (int(left_x), int(mid_y))]
    else:
        # 默认返回矩形框：左上，右上，右下，左下
        # 确保所有坐标都是整数
        return [(int(left_x), int(min_y)), (int(right_x), int(min_y)), 
                (int(right_x), int(max_y)), (int(left_x), int(max_y))]

# 修剪蓝框，使其不超过红框
def trim_blue_box_to_red_box(blue_box, red_box):
    if not blue_box or not red_box:
        return blue_box
    
    # 获取红框的y边界
    red_min_y = min(p[1] for p in red_box)
    red_max_y = max(p[1] for p in red_box)
    
    # 获取红框的x边界
    red_min_x = min(p[0] for p in red_box)
    red_max_x = max(p[0] for p in red_box)
    
    # 修剪蓝框，确保不超过红框的底部
    trimmed_blue_box = []
    for point in blue_box:
        x, y = point
        
        # 确保点不超出红框边界
        y = min(y, red_max_y)
        
        # 对于侧面点，确保不超出红框左右边界
        if y == red_max_y:  # 如果是底部的点
            x = max(min(x, red_max_x), red_min_x)
            
        trimmed_blue_box.append((x, y))
    
    return trimmed_blue_box

# 主函数
def main():
    global composite_img, composite_with_boxes_img, composite_with_expanded_boxes_img, last_face_image
    global eye_vertical_expansion, nose_width_expansion, mouth_width_expansion
    
    # 允许用户输入扩展参数值
    try:
        eye_vertical_expansion = int(input("请输入眼部框的向下扩展像素值（默认10）：") or "10")
        nose_width_expansion = int(input("请输入鼻子梯形底部加宽像素值（默认10）：") or "10")
        mouth_width_expansion = int(input("请输入嘴巴方框左右加宽像素值（默认10）：") or "10")
    except ValueError:
        print("输入无效，使用默认值")
    
    print(f"眼部框向下扩展: {eye_vertical_expansion}像素")
    print(f"鼻子梯形底部加宽: {nose_width_expansion}像素")
    print(f"嘴巴方框左右加宽: {mouth_width_expansion}像素")
    
    print("开始提取人脸特征点...")
    
    all_landmarks = []
    
    # 从所有图像中提取特征点
    for folder in input_folders:
        # 支持常见的图像格式
        for ext in ['*.jpg', '*.jpeg', '*.png']:
            pattern = os.path.join(folder, ext)
            for image_path in glob(pattern):
                landmarks_list = extract_landmarks(image_path)
                all_landmarks.extend(landmarks_list)
    
    print(f"已从 {total_faces} 张人脸中提取特征点")
    
    # 收集各类别的点
    red_points = []    # 眉毛和眼睛
    blue_points = []   # 鼻子
    green_points = []  # 嘴巴
    
    # 在复合图像上绘制所有特征点
    for face_landmarks in all_landmarks:
        for i, x, y in face_landmarks:
            # 根据点的类别选择颜色并绘制点
            if i in eyes_brows_indices:
                color = (0, 0, 255)  # 红色 (BGR)
                cv2.circle(composite_img, (x, y), 1, color, -1)
                cv2.circle(composite_with_boxes_img, (x, y), 1, color, -1)
                cv2.circle(composite_with_expanded_boxes_img, (x, y), 1, color, -1)
                red_points.append((i, x, y))
            elif i in nose_indices:
                color = (255, 0, 0)  # 蓝色
                cv2.circle(composite_img, (x, y), 1, color, -1)
                cv2.circle(composite_with_boxes_img, (x, y), 1, color, -1)
                cv2.circle(composite_with_expanded_boxes_img, (x, y), 1, color, -1)
                blue_points.append((i, x, y))
            elif i in mouth_indices:
                color = (0, 255, 0)  # 绿色
                cv2.circle(composite_img, (x, y), 1, color, -1)
                cv2.circle(composite_with_boxes_img, (x, y), 1, color, -1)
                cv2.circle(composite_with_expanded_boxes_img, (x, y), 1, color, -1)
                green_points.append((i, x, y))
    
    # 创建普通对称框（无扩展）- 使用图像中心线作为对称轴
    red_box_normal = create_image_centered_symmetric_box(red_points)  # 眼睛和眉毛的框（矩形）无扩展
    blue_box_normal = create_image_centered_symmetric_box(blue_points, "trapezoid", is_nose=True)  # 鼻子的框（梯形）无扩展
    green_box_normal = create_image_centered_symmetric_box(green_points, is_mouth=True)  # 嘴巴的框（矩形）无扩展
    
    # 创建扩展后的对称框 - 使用图像中心线作为对称轴
    red_box_expanded = create_image_centered_symmetric_box(
        red_points, 
        vertical_expansion_down=eye_vertical_expansion, 
        vertical_expansion_up=0
    )  # 眼睛和眉毛的框（矩形）只向下扩展
    
    blue_box_expanded = create_image_centered_symmetric_box(
        blue_points, 
        "trapezoid", 
        vertical_expansion_down=0, 
        vertical_expansion_up=0,
        is_nose=True,
        nose_width_expansion=nose_width_expansion
    )  # 鼻子的框（梯形）底部加宽
    
    green_box_expanded = create_image_centered_symmetric_box(
        green_points, 
        vertical_expansion_down=0, 
        vertical_expansion_up=0,
        is_mouth=True,
        mouth_width_expansion=mouth_width_expansion
    )  # 嘴巴的框（矩形）左右加宽
    
    # 修剪蓝框，使其不超过红框
    blue_box_trimmed = trim_blue_box_to_red_box(blue_box_expanded, red_box_expanded)
    
    # 在不带扩展的复合图像上绘制普通框
    if red_box_normal:
        cv2.polylines(composite_with_boxes_img, [np.array(red_box_normal)], True, (0, 0, 255), 2)
    
    if blue_box_normal:
        cv2.polylines(composite_with_boxes_img, [np.array(blue_box_normal)], True, (255, 0, 0), 2)
    
    if green_box_normal:
        cv2.polylines(composite_with_boxes_img, [np.array(green_box_normal)], True, (0, 255, 0), 2)
        
    # 在带扩展的复合图像上绘制扩展框
    if red_box_expanded:
        cv2.polylines(composite_with_expanded_boxes_img, [np.array(red_box_expanded)], True, (0, 0, 255), 2)
    
    if blue_box_trimmed:  # 使用修剪后的蓝框
        cv2.polylines(composite_with_expanded_boxes_img, [np.array(blue_box_trimmed)], True, (255, 0, 0), 2)
    
    if green_box_expanded:
        cv2.polylines(composite_with_expanded_boxes_img, [np.array(green_box_expanded)], True, (0, 255, 0), 2)
    
    # 保存复合图像
    output_path1 = os.path.join(output_folder, "all_landmarks.jpg")
    cv2.imwrite(output_path1, composite_img)
    print(f"已保存所有特征点的复合图像到: {output_path1}")
    
    # 保存带普通对称框的复合图像
    output_path2 = os.path.join(output_folder, "all_landmarks_with_boxes.jpg")
    cv2.imwrite(output_path2, composite_with_boxes_img)
    print(f"已保存带普通对称框的复合图像到: {output_path2}")
    
    # 保存带扩展对称框的复合图像
    output_path3 = os.path.join(output_folder, f"all_landmarks_with_boxes_eye{eye_vertical_expansion}_nose{nose_width_expansion}_mouth{mouth_width_expansion}.jpg")
    cv2.imwrite(output_path3, composite_with_expanded_boxes_img)
    print(f"已保存带扩展框的复合图像到: {output_path3}")
    
    # 创建一个新文件夹用于保存每张人脸照片的示意图
    faces_with_boxes_folder = os.path.join(output_folder, "faces_with_boxes")
    if not os.path.exists(faces_with_boxes_folder):
        os.makedirs(faces_with_boxes_folder)
    
    print(f"开始为每张人脸照片创建带方框的示意图...")
    
    # 记录所有处理过的图像路径，避免重复处理
    processed_image_paths = set()
    face_count = 0
    
    # 为每张人脸照片创建示意图
    for folder in input_folders:
        for ext in ['*.jpg', '*.jpeg', '*.png']:
            pattern = os.path.join(folder, ext)
            for image_path in glob(pattern):
                if image_path in processed_image_paths:
                    continue
                
                processed_image_paths.add(image_path)
                
                # 读取原始图像
                original_img = cv2.imread(image_path)
                if original_img is None:
                    print(f"无法读取图像: {image_path}")
                    continue
                
                # 确保图像尺寸一致
                face_img = cv2.resize(original_img, (image_width, image_height))
                face_with_boxes_img = face_img.copy()
                
                # 在人脸照片上绘制扩展后的框
                if red_box_expanded:
                    cv2.polylines(face_with_boxes_img, [np.array(red_box_expanded)], True, (0, 0, 255), 2)
                
                if blue_box_trimmed:  # 使用修剪后的蓝框
                    cv2.polylines(face_with_boxes_img, [np.array(blue_box_trimmed)], True, (255, 0, 0), 2)
                
                if green_box_expanded:
                    cv2.polylines(face_with_boxes_img, [np.array(green_box_expanded)], True, (0, 255, 0), 2)
                
                # 获取原始文件名（不带路径和扩展名）
                file_name = os.path.splitext(os.path.basename(image_path))[0]
                
                # 保存带人脸背景的框图像
                output_path = os.path.join(faces_with_boxes_folder, f"{file_name}_with_boxes.jpg")
                cv2.imwrite(output_path, face_with_boxes_img)
                face_count += 1
    
    print(f"已为 {face_count} 张人脸照片创建带方框的示意图，保存到: {faces_with_boxes_folder}")
    print(f"使用的参数：眼部下扩展={eye_vertical_expansion}, 鼻子底部加宽={nose_width_expansion}, 嘴巴左右加宽={mouth_width_expansion}")
    
    # 输出各框的坐标数据
    print("\n框坐标数据（以左上角为原点(0,0)，向下和向右为正轴，单位：像素）：")
    print("\n红框（眼睛和眉毛）坐标点：")
    for i, point in enumerate(red_box_expanded):
        print(f"  点{i+1}: ({point[0]}, {point[1]})")
    
    print("\n蓝框（鼻子，已修剪）坐标点：")
    for i, point in enumerate(blue_box_trimmed):
        print(f"  点{i+1}: ({point[0]}, {point[1]})")
    
    print("\n绿框（嘴巴）坐标点：")
    for i, point in enumerate(green_box_expanded):
        print(f"  点{i+1}: ({point[0]}, {point[1]})")
    
    # 将坐标数据写入文本文件
    coord_file_path = os.path.join(output_folder, f"box_coordinates_eye{eye_vertical_expansion}_nose{nose_width_expansion}_mouth{mouth_width_expansion}.txt")
    with open(coord_file_path, 'w', encoding='utf-8') as f:
        f.write("框坐标数据（以左上角为原点(0,0)，向下和向右为正轴，单位：像素）：\n\n")
        
        f.write("红框（眼睛和眉毛）坐标点：\n")
        for i, point in enumerate(red_box_expanded):
            f.write(f"  点{i+1}: ({point[0]}, {point[1]})\n")
        
        f.write("\n蓝框（鼻子，已修剪）坐标点：\n")
        for i, point in enumerate(blue_box_trimmed):
            f.write(f"  点{i+1}: ({point[0]}, {point[1]})\n")
        
        f.write("\n绿框（嘴巴）坐标点：\n")
        for i, point in enumerate(green_box_expanded):
            f.write(f"  点{i+1}: ({point[0]}, {point[1]})\n")
    
    print(f"\n已将坐标数据保存到文件: {coord_file_path}")

if __name__ == "__main__":
    main()
