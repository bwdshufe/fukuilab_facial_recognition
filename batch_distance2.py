#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量计算参与者与陌生人、友人之间的潜在空间距离
根据论文方法在 W+ 空间计算欧几里得距离
"""

import numpy as np
import pandas as pd
import torch
import os
import sys
from pathlib import Path


def load_latent_vector(file_path):
    """
    加载潜在向量文件 (.pt 或 .npy)，并转换为 NumPy 数组
    """
    if file_path.endswith('.pt'):
        try:
            tensor_data = torch.load(file_path, map_location='cpu')
            
            if isinstance(tensor_data, dict):
                keys = list(tensor_data.keys())
                if keys:
                    data = tensor_data[keys[0]]
                else:
                    raise ValueError("空的字典文件，无法提取张量")
            elif isinstance(tensor_data, list):
                data = tensor_data[0]
            elif torch.is_tensor(tensor_data):
                data = tensor_data
            else:
                data = tensor_data
                
            if torch.is_tensor(data):
                return data.detach().cpu().numpy()
            else:
                return np.array(data)
                
        except Exception as e:
            print(f"❌ 读取 .pt 文件失败: {file_path}, 错误: {e}")
            raise
            
    elif file_path.endswith('.npy'):
        return np.load(file_path)
    else:
        raise ValueError(f"不支持的文件格式: {os.path.basename(file_path)}")


def preprocess_vector(w):
    """
    处理潜在向量，统一为 W+ 空间 (18, 512)
    """
    # 如果是 (1, 18, 512)，去掉第一维
    if len(w.shape) == 3 and w.shape[0] == 1:
        w = w.squeeze(0)  # (1, 18, 512) -> (18, 512)
    
    # 如果是 (512,)，扩展到 W+ 空间
    elif len(w.shape) == 1 and w.shape[0] == 512:
        w = np.tile(w, (18, 1))  # (512,) -> (18, 512)
    
    # 确保最终是 (18, 512)
    if w.shape != (18, 512):
        raise ValueError(f"无法处理的形状: {w.shape}")
    
    return w


def calculate_euclidean_distance(w1, w2):
    """
    计算两个潜在向量之间的欧几里得距离
    论文方法: 在 W+ 空间展平后计算
    """
    # 展平后计算距离
    w1_flat = w1.flatten()  # (18, 512) -> (9216,)
    w2_flat = w2.flatten()
    distance = np.linalg.norm(w2_flat - w1_flat)
    
    return distance


def main():
    """
    主函数：批量处理所有参与者的距离计算
    """
    print("=" * 70)
    print("批量计算参与者与陌生人、友人之间的潜在空间距离")
    print("=" * 70)
    
    # 检查必要文件是否存在
    if not os.path.exists('source.xlsx'):
        print("❌ 错误: 找不到 source.xlsx 文件")
        sys.exit(1)
    
    if not os.path.exists('ptraw'):
        print("❌ 错误: 找不到 ptraw 文件夹")
        sys.exit(1)
    
    # 检查陌生人文件
    stranger_files = {
        'fu1': 'fu1_01_latent.pt',
        'fu2': 'fu2_01_latent.pt',
        'mu1': 'mu1_01_latent.pt',
        'mu2': 'mu2_01_latent.pt'
    }
    
    for key, filename in stranger_files.items():
        if not os.path.exists(filename):
            print(f"❌ 错误: 找不到 {filename} 文件")
            sys.exit(1)
    
    print("\n✓ 所有必要文件已找到")
    
    # 读取 source.xlsx
    print("\n正在读取 source.xlsx...")
    df = pd.read_excel('source.xlsx')
    print(f"✓ 读取成功，共 {len(df)} 条记录")
    print(f"列名: {list(df.columns)}")
    
    # 检查是否有 fname 列
    if 'fname' not in df.columns:
        print("⚠️  警告: 未找到 'fname' 列，将跳过友人距离计算")
        has_fname = False
    else:
        print("✓ 找到 'fname' 列，将计算友人距离")
        has_fname = True
    
    # 预加载陌生人的潜在向量
    print("\n正在加载陌生人的潜在向量...")
    stranger_vectors = {}
    for key, filename in stranger_files.items():
        try:
            w = load_latent_vector(filename)
            w = preprocess_vector(w)
            stranger_vectors[key] = w
            print(f"✓ {filename}: shape {w.shape}")
        except Exception as e:
            print(f"❌ 加载 {filename} 失败: {e}")
            sys.exit(1)
    
    # 创建新列存储距离
    df['u1distance'] = np.nan
    df['u2distance'] = np.nan
    if has_fname:
        df['fdistance'] = np.nan
    
    # 批量计算距离
    print("\n" + "=" * 70)
    print("开始批量计算距离...")
    print("=" * 70)
    
    success_count = 0
    fail_count = 0
    friend_success = 0
    friend_fail = 0
    
    for idx, row in df.iterrows():
        name = row['name']
        sex = row['sex']
        
        # 构建参与者文件路径
        participant_file = f"ptraw/{name}_01_latent.pt"
        
        if not os.path.exists(participant_file):
            print(f"⚠️  [{idx+1}/{len(df)}] {name}: 文件不存在 - {participant_file}")
            fail_count += 1
            continue
        
        try:
            # 加载参与者的潜在向量
            participant_w = load_latent_vector(participant_file)
            participant_w = preprocess_vector(participant_w)
            
            # 根据性别选择对应的陌生人
            if sex.lower() == 'f':
                u1_key = 'fu1'
                u2_key = 'fu2'
            elif sex.lower() == 'm':
                u1_key = 'mu1'
                u2_key = 'mu2'
            else:
                print(f"⚠️  [{idx+1}/{len(df)}] {name}: 性别值无效 - {sex}")
                fail_count += 1
                continue
            
            # 计算与两个陌生人的距离
            u1_distance = calculate_euclidean_distance(
                participant_w, stranger_vectors[u1_key]
            )
            u2_distance = calculate_euclidean_distance(
                participant_w, stranger_vectors[u2_key]
            )
            
            # 保存结果
            df.at[idx, 'u1distance'] = u1_distance
            df.at[idx, 'u2distance'] = u2_distance
            
            # 计算与友人的距离
            friend_dist_str = ""
            if has_fname:
                fname = row['fname']
                if pd.notna(fname) and fname != '':
                    friend_file = f"ptraw/{fname}_01_latent.pt"
                    if os.path.exists(friend_file):
                        try:
                            friend_w = load_latent_vector(friend_file)
                            friend_w = preprocess_vector(friend_w)
                            f_distance = calculate_euclidean_distance(
                                participant_w, friend_w
                            )
                            df.at[idx, 'fdistance'] = f_distance
                            friend_dist_str = f", f={f_distance:.4f}"
                            friend_success += 1
                        except Exception as e:
                            print(f"  ⚠️  无法加载友人 {fname}: {e}")
                            friend_fail += 1
                    else:
                        print(f"  ⚠️  友人文件不存在: {friend_file}")
                        friend_fail += 1
            
            print(f"✓ [{idx+1}/{len(df)}] {name} ({sex}): "
                  f"u1={u1_distance:.4f}, u2={u2_distance:.4f}{friend_dist_str}")
            success_count += 1
            
        except Exception as e:
            print(f"❌ [{idx+1}/{len(df)}] {name}: 计算失败 - {e}")
            fail_count += 1
    
    # 保存结果
    output_file = 'source_with_distances.xlsx'
    print("\n" + "=" * 70)
    print(f"正在保存结果到 {output_file}...")
    
    try:
        df.to_excel(output_file, index=False)
        print(f"✓ 保存成功！")
    except Exception as e:
        print(f"❌ 保存失败: {e}")
        sys.exit(1)
    
    # 统计信息
    print("\n" + "=" * 70)
    print("处理完成！")
    print("=" * 70)
    print(f"总记录数: {len(df)}")
    print(f"成功计算陌生人距离: {success_count}")
    print(f"失败记录: {fail_count}")
    if has_fname:
        print(f"成功计算友人距离: {friend_success}")
        print(f"友人距离计算失败: {friend_fail}")
    print(f"\n输出文件: {output_file}")
    
    # 显示统计摘要
    if success_count > 0:
        print("\n距离统计:")
        print(f"u1distance: mean={df['u1distance'].mean():.4f}, "
              f"std={df['u1distance'].std():.4f}, "
              f"min={df['u1distance'].min():.4f}, "
              f"max={df['u1distance'].max():.4f}")
        print(f"u2distance: mean={df['u2distance'].mean():.4f}, "
              f"std={df['u2distance'].std():.4f}, "
              f"min={df['u2distance'].min():.4f}, "
              f"max={df['u2distance'].max():.4f}")
        
        if has_fname and friend_success > 0:
            print(f"fdistance: mean={df['fdistance'].mean():.4f}, "
                  f"std={df['fdistance'].std():.4f}, "
                  f"min={df['fdistance'].min():.4f}, "
                  f"max={df['fdistance'].max():.4f}")
        
        # 按性别统计
        print("\n按性别分组统计:")
        for sex in df['sex'].unique():
            if pd.isna(sex):
                continue
            sex_data = df[df['sex'] == sex]
            print(f"\n性别 {sex}:")
            print(f"  样本数: {len(sex_data)}")
            print(f"  u1distance: mean={sex_data['u1distance'].mean():.4f}, "
                  f"std={sex_data['u1distance'].std():.4f}")
            print(f"  u2distance: mean={sex_data['u2distance'].mean():.4f}, "
                  f"std={sex_data['u2distance'].std():.4f}")
            if has_fname:
                valid_friend = sex_data['fdistance'].notna().sum()
                if valid_friend > 0:
                    print(f"  fdistance: mean={sex_data['fdistance'].mean():.4f}, "
                          f"std={sex_data['fdistance'].std():.4f} (n={valid_friend})")


if __name__ == "__main__":
    # 检查 torch 和 pandas 是否可用
    try:
        import torch
        import pandas as pd
        import numpy as np
    except ImportError as e:
        print(f"❌ 错误: 缺少必要的库: {e}")
        print("请安装必要的库:")
        print("  pip install torch pandas numpy openpyxl")
        sys.exit(1)
    
    main()
