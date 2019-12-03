import pygame
import math

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 800

BOARD_SIZE = 700
SLOT_CIRCLE_RADIUS = 300
SLOT_RADIUS = 10

pygame.init()
screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
done = False

def slot_index_to_angle(index):
    return math.pi/2 + index * 2 *math.pi / 64

def draw_tac_board(surface):
    pygame.draw.rect(
        surface, (0, 200, 0),pygame.Rect(
            (WINDOW_WIDTH - BOARD_SIZE)/2,
            (WINDOW_HEIGHT - BOARD_SIZE)/2, BOARD_SIZE, BOARD_SIZE
        )
    )

    for i in range(64):
        angle = 2*math.pi/64
        pygame.draw.circle(surface, (255, 255, 255),
        (int(WINDOW_WIDTH / 2 + SLOT_CIRCLE_RADIUS * math.cos(i * angle)), int(WINDOW_HEIGHT / 2 + SLOT_CIRCLE_RADIUS * math.sin(i * angle))), int(SLOT_RADIUS))

def draw_ball(surface, slot, color):
    if slot.type = "normal":
        draw

def draw_at
while not done:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            done = True
    draw_tac_board(screen)
    pygame.display.flip()
