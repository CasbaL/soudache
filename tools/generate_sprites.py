#!/usr/bin/env python3
"""
生成游戏占位符精灵图
用于快速原型开发
"""

from PIL import Image, ImageDraw
import os

# 输出目录
SPRITES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "sprites")
ICONS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "icons")

def ensure_dir(path):
    """确保目录存在"""
    os.makedirs(path, exist_ok=True)

def create_player_sprite():
    """创建玩家精灵（4帧动画）"""
    ensure_dir(os.path.join(SPRITES_DIR, "characters"))
    
    # 创建精灵表：4帧，每帧32x32
    sprite_sheet = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sprite_sheet)
    
    # 颜色
    body_color = (100, 200, 255)  # 蓝色
    outline_color = (50, 100, 200)  # 深蓝
    
    for i in range(4):
        x_offset = i * 32
        
        # 身体（圆形）
        draw.ellipse([x_offset + 8, 4, x_offset + 24, 28], fill=body_color, outline=outline_color)
        
        # 眼睛
        eye_x = x_offset + 12 + (i % 2) * 2
        draw.rectangle([eye_x, 12, eye_x + 4, 16], fill=(255, 255, 255))
        draw.rectangle([eye_x + 8, 12, eye_x + 12, 16], fill=(255, 255, 255))
    
    sprite_sheet.save(os.path.join(SPRITES_DIR, "characters", "player.png"))
    print("Created player sprite")

def create_enemy_sprite():
    """创建敌人精灵"""
    ensure_dir(os.path.join(SPRITES_DIR, "enemies"))
    
    # 竹妖（绿色）
    sprite_sheet = Image.new("RGBA", (128, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sprite_sheet)
    
    body_color = (100, 200, 100)  # 绿色
    outline_color = (50, 150, 50)
    
    for i in range(4):
        x_offset = i * 32
        # 身体
        draw.ellipse([x_offset + 6, 2, x_offset + 26, 30], fill=body_color, outline=outline_color)
        # 眼睛（红色）
        draw.rectangle([x_offset + 10, 10, x_offset + 14, 14], fill=(255, 0, 0))
        draw.rectangle([x_offset + 18, 10, x_offset + 22, 14], fill=(255, 0, 0))
    
    sprite_sheet.save(os.path.join(SPRITES_DIR, "enemies", "bamboo_spirit.png"))
    print("Created bamboo_spirit sprite")

def create_resource_sprites():
    """创建资源精灵"""
    ensure_dir(os.path.join(SPRITES_DIR, "resources"))
    
    resources = [
        ("spirit_stone", (200, 200, 100)),  # 灵石（黄色）
        ("herb", (100, 255, 100)),  # 灵草（绿色）
        ("ore", (150, 150, 150)),  # 矿石（灰色）
    ]
    
    for name, color in resources:
        img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 画一个菱形
        draw.polygon([(8, 0), (16, 8), (8, 16), (0, 8)], fill=color, outline=(0, 0, 0))
        
        img.save(os.path.join(SPRITES_DIR, "resources", f"{name}.png"))
        print(f"Created {name} sprite")

def create_extraction_point_sprite():
    """创建撤离点精灵"""
    ensure_dir(os.path.join(SPRITES_DIR, "effects"))
    
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 画一个发光的传送门
    draw.ellipse([2, 2, 30, 30], fill=(100, 200, 255, 128), outline=(200, 230, 255))
    draw.ellipse([6, 6, 26, 26], fill=(150, 220, 255, 200))
    
    img.save(os.path.join(SPRITES_DIR, "effects", "extraction_point.png"))
    print("Created extraction_point sprite")

def create_tileset():
    """创建瓦片集"""
    ensure_dir(os.path.join(SPRITES_DIR, "tiles"))
    
    # 地面瓦片（棕色）
    floor = Image.new("RGBA", (32, 32), (80, 60, 40))
    draw = ImageDraw.Draw(floor)
    # 添加纹理
    for i in range(0, 32, 8):
        draw.line([(i, 0), (i, 32)], fill=(70, 50, 30), width=1)
        draw.line([(0, i), (32, i)], fill=(70, 50, 30), width=1)
    floor.save(os.path.join(SPRITES_DIR, "tiles", "floor.png"))
    
    # 墙壁瓦片（深灰）
    wall = Image.new("RGBA", (32, 32), (60, 60, 70))
    draw = ImageDraw.Draw(wall)
    # 添加砖块纹理
    for y in range(0, 32, 16):
        for x in range(0, 32, 16):
            offset = 8 if (y // 16) % 2 else 0
            draw.rectangle([x + offset, y, x + offset + 14, y + 14], outline=(80, 80, 90))
    wall.save(os.path.join(SPRITES_DIR, "tiles", "wall.png"))
    
    print("Created tileset")

def create_icon():
    """创建应用图标"""
    img = Image.new("RGBA", (128, 128), (26, 26, 46))
    draw = ImageDraw.Draw(img)
    
    # 画一个仙字风格的图标
    draw.ellipse([20, 20, 108, 108], fill=(233, 69, 96), outline=(200, 50, 80))
    draw.ellipse([30, 30, 98, 98], fill=(26, 26, 46))
    
    # 简化的"仙"字
    draw.rectangle([50, 40, 58, 90], fill=(233, 69, 96))
    draw.rectangle([70, 40, 78, 90], fill=(233, 69, 96))
    draw.rectangle([40, 55, 88, 63], fill=(233, 69, 96))
    
    img.save(os.path.join(ICONS_DIR, "icon.png"))
    
    # SVG 图标
    svg_content = '''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect width="128" height="128" fill="#1A1A2E"/>
  <circle cx="64" cy="64" r="44" fill="#E94560"/>
  <circle cx="64" cy="64" r="34" fill="#1A1A2E"/>
  <rect x="50" y="40" width="8" height="50" fill="#E94560"/>
  <rect x="70" y="40" width="8" height="50" fill="#E94560"/>
  <rect x="40" y="55" width="48" height="8" fill="#E94560"/>
</svg>'''
    
    with open(os.path.join(os.path.dirname(os.path.dirname(__file__)), "icon.svg"), "w") as f:
        f.write(svg_content)
    
    print("Created icon")

def create_damage_number():
    """创建伤害数字精灵"""
    ensure_dir(os.path.join(SPRITES_DIR, "ui"))
    
    # 创建数字 0-9 的精灵表
    img = Image.new("RGBA", (160, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 简单的数字表示
    for i in range(10):
        x = i * 16
        draw.rectangle([x, 0, x + 14, 14], fill=(255, 255, 255), outline=(0, 0, 0))
        # 用像素点表示数字
        if i in [0, 2, 3, 5, 6, 7, 8, 9]:
            draw.rectangle([x + 2, 2, x + 12, 4], fill=(255, 0, 0))
        if i in [0, 1, 2, 3, 4, 7, 8, 9]:
            draw.rectangle([x + 10, 2, x + 12, 12], fill=(255, 0, 0))
        if i in [0, 2, 6, 8]:
            draw.rectangle([x + 2, 10, x + 12, 12], fill=(255, 0, 0))
        if i in [0, 4, 5, 6, 8, 9]:
            draw.rectangle([x + 2, 2, x + 4, 12], fill=(255, 0, 0))
        if i in [2, 3, 4, 5, 6, 8, 9]:
            draw.rectangle([x + 2, 6, x + 12, 8], fill=(255, 0, 0))
    
    img.save(os.path.join(SPRITES_DIR, "ui", "damage_numbers.png"))
    print("Created damage numbers sprite")

if __name__ == "__main__":
    print("Generating sprites...")
    create_player_sprite()
    create_enemy_sprite()
    create_resource_sprites()
    create_extraction_point_sprite()
    create_tileset()
    create_icon()
    create_damage_number()
    print("Done!")
