#!/usr/bin/env python3
"""
创建真正的游戏素材
仙侠风格像素艺术
"""

from PIL import Image, ImageDraw, ImageFont
import os

# 输出目录
BASE_DIR = os.path.dirname(os.path.dirname(__file__))
SPRITES_DIR = os.path.join(BASE_DIR, "assets", "sprites")
ICONS_DIR = os.path.join(BASE_DIR, "assets", "icons")
AUDIO_DIR = os.path.join(BASE_DIR, "assets", "audio")

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def create_player_sprites():
    """创建玩家精灵 - 仙侠剑修"""
    ensure_dir(os.path.join(SPRITES_DIR, "characters"))
    
    # 精灵表：4方向 x 4帧 = 16帧
    # 每帧 32x48 像素
    sprite_sheet = Image.new("RGBA", (128, 192), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sprite_sheet)
    
    # 颜色定义
    body_color = (45, 85, 150)  # 深蓝道袍
    robe_highlight = (60, 110, 180)  # 道袍高光
    skin_color = (240, 200, 170)  # 肤色
    hair_color = (30, 25, 20)  # 黑发
    belt_color = (180, 150, 50)  # 金色腰带
    sword_color = (200, 200, 220)  # 银色剑
    
    for direction in range(4):  # 下、左、右、上
        for frame in range(4):
            x = frame * 32
            y = direction * 48
            
            # 身体（道袍）
            if direction == 0:  # 下
                # 身体
                draw.rectangle([x+10, y+16, x+22, y+40], fill=body_color)
                # 道袍下摆
                draw.rectangle([x+8, y+32, x+24, y+44], fill=robe_highlight)
                # 头
                draw.ellipse([x+11, y+4, x+21, y+16], fill=skin_color)
                # 头发
                draw.rectangle([x+11, y+2, x+21, y+8], fill=hair_color)
                # 发髻
                draw.rectangle([x+14, y+0, x+18, y+6], fill=hair_color)
                # 眼睛
                draw.rectangle([x+13, y+10, x+15, y+12], fill=(20, 20, 20))
                draw.rectangle([x+17, y+10, x+19, y+12], fill=(20, 20, 20))
                # 腰带
                draw.rectangle([x+10, y+28, x+22, y+30], fill=belt_color)
                # 剑（背在身后）
                if frame % 2 == 0:
                    draw.rectangle([x+23, y+12, x+25, y+36], fill=sword_color)
                    draw.rectangle([x+22, y+10, x+26, y+14], fill=(150, 120, 40))
                # 腿（走路动画）
                if frame == 0:
                    draw.rectangle([x+12, y+40, x+15, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+17, y+40, x+20, y+46], fill=(40, 40, 60))
                elif frame == 1:
                    draw.rectangle([x+10, y+40, x+13, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+19, y+40, x+22, y+46], fill=(40, 40, 60))
                elif frame == 2:
                    draw.rectangle([x+12, y+40, x+15, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+17, y+40, x+20, y+46], fill=(40, 40, 60))
                elif frame == 3:
                    draw.rectangle([x+14, y+40, x+17, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+15, y+40, x+18, y+46], fill=(40, 40, 60))
            
            elif direction == 1:  # 左
                # 身体
                draw.rectangle([x+10, y+16, x+22, y+40], fill=body_color)
                # 头
                draw.ellipse([x+10, y+4, x+20, y+16], fill=skin_color)
                # 头发
                draw.rectangle([x+10, y+2, x+20, y+8], fill=hair_color)
                # 发髻
                draw.rectangle([x+10, y+0, x+14, y+6], fill=hair_color)
                # 眼睛
                draw.rectangle([x+12, y+10, x+14, y+12], fill=(20, 20, 20))
                # 剑
                draw.rectangle([x+8, y+14, x+10, y+38], fill=sword_color)
                # 腿
                if frame == 0:
                    draw.rectangle([x+12, y+40, x+15, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+17, y+40, x+20, y+46], fill=(40, 40, 60))
                elif frame == 1:
                    draw.rectangle([x+10, y+40, x+13, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+19, y+40, x+22, y+46], fill=(40, 40, 60))
                elif frame == 2:
                    draw.rectangle([x+12, y+40, x+15, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+17, y+40, x+20, y+46], fill=(40, 40, 60))
                elif frame == 3:
                    draw.rectangle([x+14, y+40, x+17, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+15, y+40, x+18, y+46], fill=(40, 40, 60))
            
            elif direction == 2:  # 右
                # 身体
                draw.rectangle([x+10, y+16, x+22, y+40], fill=body_color)
                # 头
                draw.ellipse([x+12, y+4, x+22, y+16], fill=skin_color)
                # 头发
                draw.rectangle([x+12, y+2, x+22, y+8], fill=hair_color)
                # 发髻
                draw.rectangle([x+18, y+0, x+22, y+6], fill=hair_color)
                # 眼睛
                draw.rectangle([x+18, y+10, x+20, y+12], fill=(20, 20, 20))
                # 剑
                draw.rectangle([x+22, y+14, x+24, y+38], fill=sword_color)
                # 腿
                if frame == 0:
                    draw.rectangle([x+12, y+40, x+15, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+17, y+40, x+20, y+46], fill=(40, 40, 60))
                elif frame == 1:
                    draw.rectangle([x+10, y+40, x+13, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+19, y+40, x+22, y+46], fill=(40, 40, 60))
                elif frame == 2:
                    draw.rectangle([x+12, y+40, x+15, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+17, y+40, x+20, y+46], fill=(40, 40, 60))
                elif frame == 3:
                    draw.rectangle([x+14, y+40, x+17, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+15, y+40, x+18, y+46], fill=(40, 40, 60))
            
            elif direction == 3:  # 上
                # 身体
                draw.rectangle([x+10, y+16, x+22, y+40], fill=body_color)
                # 头
                draw.ellipse([x+11, y+4, x+21, y+16], fill=skin_color)
                # 头发（背面）
                draw.rectangle([x+11, y+2, x+21, y+14], fill=hair_color)
                # 发髻
                draw.rectangle([x+14, y+0, x+18, y+8], fill=hair_color)
                # 剑
                draw.rectangle([x+23, y+12, x+25, y+36], fill=sword_color)
                # 腿
                if frame == 0:
                    draw.rectangle([x+12, y+40, x+15, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+17, y+40, x+20, y+46], fill=(40, 40, 60))
                elif frame == 1:
                    draw.rectangle([x+10, y+40, x+13, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+19, y+40, x+22, y+46], fill=(40, 40, 60))
                elif frame == 2:
                    draw.rectangle([x+12, y+40, x+15, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+17, y+40, x+20, y+46], fill=(40, 40, 60))
                elif frame == 3:
                    draw.rectangle([x+14, y+40, x+17, y+46], fill=(40, 40, 60))
                    draw.rectangle([x+15, y+40, x+18, y+46], fill=(40, 40, 60))
    
    sprite_sheet.save(os.path.join(SPRITES_DIR, "characters", "player.png"))
    print("✓ 创建玩家精灵")

def create_enemy_sprites():
    """创建敌人精灵 - 竹妖"""
    ensure_dir(os.path.join(SPRITES_DIR, "enemies"))
    
    # 竹妖精灵表
    sprite_sheet = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sprite_sheet)
    
    # 颜色
    body_color = (60, 140, 60)  # 绿色
    body_dark = (40, 100, 40)  # 深绿
    eye_color = (200, 50, 50)  # 红眼
    leaf_color = (80, 180, 80)  # 叶子
    
    for frame in range(4):
        x = frame * 32
        y = 0  # 添加y变量定义
        
        # 身体（竹节）
        draw.rectangle([x+10, y+8, x+22, y+36], fill=body_color)
        # 竹节纹理
        draw.rectangle([x+10, y+16, x+22, y+18], fill=body_dark)
        draw.rectangle([x+10, y+24, x+22, y+26], fill=body_dark)
        draw.rectangle([x+10, y+32, x+22, y+34], fill=body_dark)
        
        # 头部
        draw.ellipse([x+8, y+0, x+24, y+16], fill=body_color)
        
        # 眼睛
        draw.rectangle([x+12, y+6, x+16, y+10], fill=eye_color)
        draw.rectangle([x+18, y+6, x+22, y+10], fill=eye_color)
        # 瞳孔
        draw.rectangle([x+14, y+7, x+16, y+9], fill=(100, 20, 20))
        draw.rectangle([x+20, y+7, x+22, y+9], fill=(100, 20, 20))
        
        # 嘴巴
        draw.rectangle([x+14, y+12, x+18, y+14], fill=(40, 80, 40))
        
        # 叶子（头顶）
        draw.polygon([(x+16, y-4), (x+20, y+4), (x+12, y+4)], fill=leaf_color)
        
        # 手臂
        if frame == 0:
            draw.rectangle([x+6, y+20, x+10, y+32], fill=body_color)
            draw.rectangle([x+22, y+20, x+26, y+32], fill=body_color)
        elif frame == 1:
            draw.rectangle([x+4, y+18, x+8, y+30], fill=body_color)
            draw.rectangle([x+24, y+22, x+28, y+34], fill=body_color)
        elif frame == 2:
            draw.rectangle([x+6, y+22, x+10, y+34], fill=body_color)
            draw.rectangle([x+22, y+18, x+26, y+30], fill=body_color)
        elif frame == 3:
            draw.rectangle([x+8, y+20, x+12, y+32], fill=body_color)
            draw.rectangle([x+20, y+20, x+24, y+32], fill=body_color)
        
        # 腿
        draw.rectangle([x+12, y+36, x+16, y+44], fill=body_dark)
        draw.rectangle([x+18, y+36, x+22, y+44], fill=body_dark)
    
    sprite_sheet.save(os.path.join(SPRITES_DIR, "enemies", "bamboo_spirit.png"))
    print("✓ 创建竹妖精灵")

def create_resource_sprites():
    """创建资源精灵"""
    ensure_dir(os.path.join(SPRITES_DIR, "resources"))
    
    # 灵石
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # 菱形宝石
    draw.polygon([(8, 0), (16, 8), (8, 16), (0, 8)], fill=(100, 200, 255))
    draw.polygon([(8, 2), (14, 8), (8, 14), (2, 8)], fill=(150, 230, 255))
    draw.polygon([(8, 4), (12, 8), (8, 12), (4, 8)], fill=(200, 245, 255))
    img.save(os.path.join(SPRITES_DIR, "resources", "spirit_stone.png"))
    
    # 灵草
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # 草叶
    draw.polygon([(8, 0), (12, 8), (8, 16)], fill=(60, 180, 60))
    draw.polygon([(8, 0), (4, 8), (8, 16)], fill=(80, 200, 80))
    draw.polygon([(8, 4), (14, 10), (8, 16)], fill=(100, 220, 100))
    # 茎
    draw.rectangle([7, 8, 9, 16], fill=(40, 120, 40))
    img.save(os.path.join(SPRITES_DIR, "resources", "herb.png"))
    
    # 矿石
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # 石头形状
    draw.polygon([(4, 4), (12, 2), (14, 10), (10, 14), (2, 12)], fill=(120, 120, 130))
    draw.polygon([(6, 4), (10, 3), (12, 8), (8, 10), (4, 8)], fill=(160, 160, 170))
    # 矿石闪光
    draw.rectangle([8, 5, 10, 7], fill=(200, 200, 220))
    img.save(os.path.join(SPRITES_DIR, "resources", "ore.png"))
    
    print("✓ 创建资源精灵")

def create_extraction_point_sprite():
    """创建撤离点精灵 - 传送门"""
    ensure_dir(os.path.join(SPRITES_DIR, "effects"))
    
    # 传送门动画（4帧）
    sprite_sheet = Image.new("RGBA", (256, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sprite_sheet)
    
    for frame in range(4):
        x = frame * 64
        
        # 外圈
        draw.ellipse([x+4, 4, x+60, 60], fill=(50, 100, 200, 100), outline=(100, 180, 255))
        
        # 内圈
        draw.ellipse([x+12, 12, x+52, 52], fill=(80, 150, 255, 150))
        
        # 中心光点
        offset = frame * 2
        draw.ellipse([x+28-offset, 28-offset, x+36+offset, 36+offset], fill=(200, 230, 255, 200))
        
        # 旋转光点
        angle = frame * 90
        import math
        for i in range(4):
            a = math.radians(angle + i * 90)
            px = x + 32 + int(20 * math.cos(a))
            py = 32 + int(20 * math.sin(a))
            draw.ellipse([px-3, py-3, px+3, py+3], fill=(255, 255, 255, 180))
    
    sprite_sheet.save(os.path.join(SPRITES_DIR, "effects", "extraction_point.png"))
    print("✓ 创建撤离点精灵")

def create_tileset():
    """创建瓦片集"""
    ensure_dir(os.path.join(SPRITES_DIR, "tiles"))
    
    # 地面瓦片
    floor = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(floor)
    
    # 石板地面
    draw.rectangle([0, 0, 31, 31], fill=(80, 75, 65))
    # 石板纹理
    draw.rectangle([0, 0, 15, 15], fill=(85, 80, 70))
    draw.rectangle([16, 16, 31, 31], fill=(85, 80, 70))
    draw.rectangle([0, 16, 15, 31], fill=(75, 70, 60))
    draw.rectangle([16, 0, 31, 15], fill=(75, 70, 60))
    # 石板缝隙
    draw.line([(0, 15), (31, 15)], fill=(60, 55, 45), width=1)
    draw.line([(15, 0), (15, 31)], fill=(60, 55, 45), width=1)
    floor.save(os.path.join(SPRITES_DIR, "tiles", "floor.png"))
    
    # 墙壁瓦片
    wall = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(wall)
    
    # 砖墙
    draw.rectangle([0, 0, 31, 31], fill=(60, 55, 50))
    # 砖块
    for y in range(0, 32, 8):
        for x in range(0, 32, 16):
            offset = 8 if (y // 8) % 2 else 0
            draw.rectangle([x+offset, y, x+offset+14, y+6], fill=(70, 65, 55))
            draw.rectangle([x+offset, y, x+offset+14, y], fill=(80, 75, 65))
    wall.save(os.path.join(SPRITES_DIR, "tiles", "wall.png"))
    
    print("✓ 创建瓦片集")

def create_effects():
    """创建特效精灵"""
    ensure_dir(os.path.join(SPRITES_DIR, "effects"))
    
    # 伤害数字
    img = Image.new("RGBA", (160, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 数字 0-9
    for i in range(10):
        x = i * 16
        draw.rectangle([x, 0, x+14, 14], fill=(255, 255, 255), outline=(0, 0, 0))
        # 简单数字形状
        if i == 0:
            draw.rectangle([x+4, 4, x+10, 10], fill=(255, 0, 0))
        elif i == 1:
            draw.rectangle([x+6, 2, x+8, 12], fill=(255, 0, 0))
        elif i == 2:
            draw.rectangle([x+2, 2, x+12, 4], fill=(255, 0, 0))
            draw.rectangle([x+10, 4, x+12, 8], fill=(255, 0, 0))
            draw.rectangle([x+2, 8, x+12, 10], fill=(255, 0, 0))
            draw.rectangle([x+2, 10, x+12, 12], fill=(255, 0, 0))
    img.save(os.path.join(SPRITES_DIR, "effects", "damage_numbers.png"))
    
    # 剑气特效
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(0, 16), (32, 8), (32, 24)], fill=(200, 220, 255, 200))
    draw.polygon([(0, 16), (24, 10), (24, 22)], fill=(255, 255, 255, 150))
    img.save(os.path.join(SPRITES_DIR, "effects", "sword_slash.png"))
    
    print("✓ 创建特效精灵")

def create_ui_elements():
    """创建UI元素"""
    ensure_dir(os.path.join(SPRITES_DIR, "ui"))
    
    # 血量条背景
    img = Image.new("RGBA", (200, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, 199, 19], fill=(40, 40, 40), outline=(100, 100, 100))
    img.save(os.path.join(SPRITES_DIR, "ui", "health_bar_bg.png"))
    
    # 血量条
    img = Image.new("RGBA", (196, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, 195, 15], fill=(200, 50, 50))
    draw.rectangle([0, 0, 195, 5], fill=(255, 80, 80))
    img.save(os.path.join(SPRITES_DIR, "ui", "health_bar.png"))
    
    # 技能按钮背景
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, 47, 47], fill=(60, 60, 70), outline=(120, 120, 140))
    draw.rectangle([2, 2, 45, 45], fill=(50, 50, 60))
    img.save(os.path.join(SPRITES_DIR, "ui", "skill_button.png"))
    
    print("✓ 创建UI元素")

if __name__ == "__main__":
    print("=== 创建仙侠游戏素材 ===\n")
    
    create_player_sprites()
    create_enemy_sprites()
    create_resource_sprites()
    create_extraction_point_sprite()
    create_tileset()
    create_effects()
    create_ui_elements()
    
    print("\n=== 素材创建完成 ===")
