import pygame
import json
import sys
import tkinter as tk
from tkinter import filedialog

# Определение цветов
WHITE = (0, 0, 0)
BLACK = (255, 255, 255)
BLUE = (0, 0, 255)
GREEN = (0, 255, 0)
YELLOW = (255, 255, 0)
LIGHT_GRAY = (0, 0, 0)  # Светло-серый
PURPLE = (128, 0, 128)  # Фиолетовый
RED = (255, 0, 0)  # Красный
ORANGE = (0, 0, 50)  # Оранжевый

# Размеры окна
WIDTH, HEIGHT = 3500, 900  # Увеличенные размеры карты
GRID_SIZE = 5  # Размер ячейки сетки (уменьшен для большей точности)
NUM_CELLS_X = WIDTH // GRID_SIZE
NUM_CELLS_Y = HEIGHT // GRID_SIZE

# Уменьшаем размеры фигур
PLAYER_SIZE = (55, 85)  # Новый размер игрока
PLATFORM_SIZE = (40, 20)  # Новый размер платформы
BONUS_SIZE = (32, 32)  # Новый размер бонуса
ENEMY_SIZE = (32, 32)  # Новый размер врага

class Game:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption("Drag and Drop with Grid")
        self.clock = pygame.time.Clock()
        self.objects = []
        self.selected_object = None
        self.player = None  # Инициализация атрибута player

    def draw_grid(self):
        for x in range(0, WIDTH, GRID_SIZE):
            pygame.draw.line(self.screen, LIGHT_GRAY, (x, 0), (x, HEIGHT))
        for y in range(0, HEIGHT, GRID_SIZE):
            if y % (GRID_SIZE * 10) == 0:  # Более редкие линии для осей Y
                pygame.draw.line(self.screen, LIGHT_GRAY, (0, y), (WIDTH, y))

    def draw_positioning_scales(self):
        # Рисуем шкалы по осям X и Y
        font = pygame.font.SysFont(None, 24)
        for i in range(0, NUM_CELLS_X + 1):
            if i % 10 == 0:  # Периодичность 10 для шкалы X
                text = font.render(str(i * GRID_SIZE), True, BLACK)
                self.screen.blit(text, (i * GRID_SIZE, HEIGHT - 20))
        for j in range(0, NUM_CELLS_Y + 1):
            if j % 10 == 0:  # Периодичность 10 для шкалы Y
                text = font.render(str(j * GRID_SIZE), True, BLACK)
                self.screen.blit(text, (5, j * GRID_SIZE))

    def draw_orange_zone(self):
        orange_zone_height = HEIGHT * 0.4  # Оранжевая зона 40% от высоты
        pygame.draw.rect(self.screen, ORANGE, (0, HEIGHT - orange_zone_height, WIDTH, orange_zone_height))

    def add_player(self, x, y):
        self.player = pygame.Rect(x, y, *PLAYER_SIZE)  # Создаем прямоугольник для игрока
        self.objects.append(('player', self.player))  # Добавляем игрока в список объектов

    def add_platform(self, x, y):
        new_rect = pygame.Rect(x, y, *PLATFORM_SIZE)

        # Проверяем, нужно ли объединять платформы
        merged = False
        for idx, obj in enumerate(self.objects):
            obj_type = obj[0]
            rect = obj[1]

            if obj_type == 'platform':
                if (rect.y == new_rect.y and 
                    rect.height == new_rect.height and 
                    (rect.x + rect.width == new_rect.x or new_rect.x + new_rect.width == rect.x)):
                    # Объединяем платформы
                    new_rect.x = min(rect.x, new_rect.x)
                    new_rect.width += rect.width
                    self.objects[idx] = ('platform', new_rect)  # Обновляем платформу
                    merged = True
                    break

        if not merged:
            self.objects.append(('platform', new_rect))


    def add_bonus_box(self, x, y):
        rect = pygame.Rect(x, y, *BONUS_SIZE)
        self.objects.append(('bonus', rect))

    def add_enemy1(self, x, y):
        rect = pygame.Rect(x, y, *ENEMY_SIZE)
        self.objects.append(('enemy1', rect, {
            "direction": 1,
            "current_walk": 0,
            "walk_area": 200
        }))

    def add_enemy2(self, x, y):
        rect = pygame.Rect(x, y, *ENEMY_SIZE)
        self.objects.append(('enemy2', rect))

    def draw_objects(self):
        for obj in self.objects:
            if obj[0] == 'player':
                pygame.draw.rect(self.screen, BLUE, obj[1])
            elif obj[0] == 'platform':
                pygame.draw.rect(self.screen, GREEN, obj[1])
            elif obj[0] == 'bonus':
                pygame.draw.rect(self.screen, YELLOW, obj[1])
            elif obj[0] == 'enemy1':
                pygame.draw.rect(self.screen, PURPLE, obj[1])
            elif obj[0] == 'enemy2':
                pygame.draw.rect(self.screen, RED, obj[1])

    def draw_instructions(self):
        font = pygame.font.SysFont(None, 24)
        instructions = [
            "Управление:",
            "P - добавить игрока",
            "F - добавить платформу",
            "B - добавить бонус",
            "E - добавить врага типа 1 (фиолетовый)",
            "R - добавить врага типа 2 (красный)",
            "ЛКМ - перетаскивать объекты",
            "ПКМ - удалять объекты",
            "S - сохранить в JSON",
            "L - загрузить из JSON"
        ]
        
        for i, line in enumerate(instructions):
            text = font.render(line, True, BLACK)
            self.screen.blit(text, (WIDTH - 200, 20 + i * 20))

    def save_to_json(self, filename):
        data = {
            "player": {
                "x": self.player.x,
                "y": self.player.y,
                "width": self.player.width,
                "height": self.player.height,
                "dy": 0,
                "onGround": False
            },
            "platforms": [],
            "enemies": [],
            "enemies2": [],
            "bonusBoxes": [],
        }

        # Объединяем платформы в одну
        platforms_dict = {}
        for obj in self.objects:
            if obj[0] == 'platform':
                rect = obj[1]
                key = (rect.y, rect.height)  # Ключ по высоте и y

                if key not in platforms_dict:
                    platforms_dict[key] = []

                platforms_dict[key].append(rect)

        for (y, height), rects in platforms_dict.items():
            # Объединяем платформы с одинаковой высотой и y
            rects.sort(key=lambda r: r.x)  # Сортируем по X
            start_x = rects[0].x
            current_width = rects[0].width

            for rect in rects[1:]:
                if rect.y == y and rect.height == height and (start_x + current_width == rect.x):
                    current_width += rect.width  # Объединяем
                else:
                    data["platforms"].append({
                        "x": start_x,
                        "y": y,
                        "width": current_width,
                        "height": height,
                    })
                    start_x = rect.x
                    current_width = rect.width

            # Добавляем последнюю платформу
            data["platforms"].append({
                "x": start_x,
                "y": y,
                "width": current_width,
                "height": height,
            })

        # Сохраняем бонусы
        for obj in self.objects:
            if obj[0] == 'bonus':
                rect = obj[1]
                data["bonusBoxes"].append({
                    "x": rect.x,
                    "y": rect.y,
                    "width": rect.width,
                    "height": rect.height,
                })

        # Сохраняем врагов первого типа
        for obj in self.objects:
            if obj[0] == 'enemy1':
                rect = obj[1]
                data["enemies"].append({
                    "x": rect.x,
                    "y": rect.y,
                    "width": rect.width,
                    "height": rect.height,
                    "direction": 1,
                    "current_walk": 0,
                    "walk_area": 200,
                })

        # Сохраняем врагов второго типа
        for obj in self.objects:
            if obj[0] == 'enemy2':
                rect = obj[1]
                data["enemies2"].append({
                    "x": rect.x,
                    "y": rect.y,
                    "width": rect.width,
                    "height": rect.height,
                })

        with open(filename, 'w') as f:
            json.dump(data, f, indent=4)
        print(f"Данные сохранены в {filename}")

    def load_from_json(self, filename):
        try:
            with open(filename, 'r') as f:
                data = json.load(f)

            self.objects.clear()  # Очистить текущие объекты

            # Загружаем игрока
            if data.get("player"):
                player_data = data["player"]
                self.add_player(player_data["x"], player_data["y"])

            # Загружаем и разбиваем платформы
            for platform in data.get("platforms", []):
                x = platform["x"]
                y = platform["y"]
                width = platform["width"]
                height = platform["height"]

                # Разбиваем на отрезки по 40 пикселей
                while width > 0:
                    segment_width = min(40, width)  # Длина отрезка
                    segment = pygame.Rect(x, y, segment_width, height)
                    self.objects.append(('platform', segment))
                    x += segment_width
                    width -= segment_width

            # Загружаем бонусы
            for bonus in data.get("bonusBoxes", []):
                self.add_bonus_box(bonus["x"], bonus["y"])

            # Загружаем врагов первого типа
            for enemy in data.get("enemies", []):
                self.add_enemy1(enemy["x"], enemy["y"])

            # Загружаем врагов второго типа
            for enemy in data.get("enemies2", []):
                self.add_enemy2(enemy["x"], enemy["y"])

            print(f"Данные загружены из {filename}")
        except Exception as e:
            print(f"Ошибка при загрузке файла: {e}")

    def main_loop(self):
        dragging = False
        offset_x, offset_y = 0, 0

        while True:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()

                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_p:  # Добавить игрока
                        mouse_x, mouse_y = pygame.mouse.get_pos()
                        self.add_player(mouse_x, mouse_y)
                    elif event.key == pygame.K_f:  # Добавить платформу
                        mouse_x, mouse_y = pygame.mouse.get_pos()
                        self.add_platform(mouse_x, mouse_y)
                    elif event.key == pygame.K_b:  # Добавить бонус
                        mouse_x, mouse_y = pygame.mouse.get_pos()
                        self.add_bonus_box(mouse_x, mouse_y)
                    elif event.key == pygame.K_e:  # Добавить врага типа 1
                        mouse_x, mouse_y = pygame.mouse.get_pos()
                        self.add_enemy1(mouse_x, mouse_y)
                    elif event.key == pygame.K_r:  # Добавить врага типа 2
                        mouse_x, mouse_y = pygame.mouse.get_pos()
                        self.add_enemy2(mouse_x, mouse_y)
                    elif event.key == pygame.K_s:  # Сохранить
                        filename = self.get_save_file()
                        if filename:
                            self.save_to_json(filename)
                    elif event.key == pygame.K_l:  # Загрузить
                        filename = self.get_load_file()
                        if filename:
                            self.load_from_json(filename)

                if event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:  # Левая кнопка мыши
                        mouse_pos = pygame.mouse.get_pos()
                        for obj in self.objects:
                            if obj[1].collidepoint(mouse_pos):
                                self.selected_object = obj
                                dragging = True
                                offset_x = obj[1].x - mouse_pos[0]
                                offset_y = obj[1].y - mouse_pos[1]
                                break
                    elif event.button == 3:  # Правая кнопка мыши
                        mouse_pos = pygame.mouse.get_pos()
                        for obj in self.objects:
                            if obj[1].collidepoint(mouse_pos):
                                self.objects.remove(obj)
                                break

                if event.type == pygame.MOUSEBUTTONUP:
                    if event.button == 1:  # Левая кнопка мыши
                        dragging = False
                        self.selected_object = None

                if event.type == pygame.MOUSEMOTION:
                    if dragging and self.selected_object:
                        mouse_x, mouse_y = pygame.mouse.get_pos()
                        
                        # Привязываем объект к сетке
                        snap_x = round((mouse_x + offset_x) / GRID_SIZE) * GRID_SIZE
                        snap_y = round((mouse_y + offset_y) / GRID_SIZE) * GRID_SIZE
                        
                        self.selected_object[1].x = snap_x
                        self.selected_object[1].y = snap_y

            self.screen.fill(WHITE)
            self.draw_grid()
            self.draw_objects()
            self.draw_instructions()
            self.draw_positioning_scales()
            self.draw_orange_zone()
            pygame.display.flip()
            self.clock.tick(60)


    def get_save_file(self):
        root = tk.Tk()
        root.withdraw()  # Скрыть главное окно
        return filedialog.asksaveasfilename(defaultextension=".json", filetypes=[("JSON files", "*.json")])

    def get_load_file(self):
        root = tk.Tk()
        root.withdraw()  # Скрыть главное окно
        return filedialog.askopenfilename(filetypes=[("JSON files", "*.json")])

if __name__ == "__main__":
    game = Game()
    game.main_loop()
