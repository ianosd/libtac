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

class Slot:
    def __init__(self, slot_type):
        self.slot_type = slot_type

    @staticmethod
    def create_simple_slot(index):
        simple_slot = Slot("simple")
        simple_slot.index = index
        simple_slot.position = (
            int(WINDOW_WIDTH/2 + SLOT_CIRCLE_RADIUS*cos(slot_angle)),
            int(WINDOW_HEIGHT/2 + SLOT_CIRCLE_RADIUS*sin(slot_angle))
        )


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
        slot = Slot.create_simple_slot(i)
        draw_disk(surface, slot, (255, 255, 255))

def draw_ball_circle(surface, color, position):
    
def draw_disk(surface, slot, color):
    pygame.draw.circle(surface, color, slot.position, int(SLOT_RADIUS))
        

while not done:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            done = True
    draw_tac_board(screen)
    pygame.display.flip()
