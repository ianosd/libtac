import pygame
import math
from pyswip.prolog import Prolog
from pyswip.easy import Functor, Atom

# Useful game constants
NUMBER_OF_SLOTS = 64

# Drawing dimensions and angles
WINDOW_WIDTH = 900
WINDOW_HEIGHT = 900
BOARD_SIZE = 700
RESERVE_OFFSET = -50
RESERVE_INTERNAL_SIZE = 25
SLOT_CIRCLE_RADIUS = 300
HOME_RADIAL_OFFSET = 100
HOME_SPACING = 30
SLOT_RADIUS = 10
FIRST_SLOT_ANGLE = math.pi/2

def get_slot_angle(index):
    return index * 2 * math.pi / NUMBER_OF_SLOTS + FIRST_SLOT_ANGLE

def get_simple_slot_position(index):
    slot_angle = get_slot_angle(index)
    return (
        int(WINDOW_WIDTH/2 + SLOT_CIRCLE_RADIUS*math.cos(slot_angle)),
        int(WINDOW_HEIGHT/2 + SLOT_CIRCLE_RADIUS*math.sin(slot_angle))
    )

def get_player_ball_color(index):
    return ((255, 0, 0), (0, 255, 0), (0, 0, 255), (127, 0, 127))[index]

def draw_tac_board(surface):
    pygame.draw.rect(
        surface, (0, 200, 0),pygame.Rect(
            (WINDOW_WIDTH - BOARD_SIZE)/2,
            (WINDOW_HEIGHT - BOARD_SIZE)/2, BOARD_SIZE, BOARD_SIZE
        )
    )

    for i in range(NUMBER_OF_SLOTS):
        draw_slot_disk(surface, get_simple_slot_position(i), (255, 255, 255))

    for player_index in range(4):
        for home_ball_index in range(4):
            draw_ball_in_home_slot(surface, home_ball_index, player_index, (255, 255, 255))

def draw_everything(surface, game_state):
    draw_tac_board(surface)

    all_balls = game_state["AllBalls"]
    for player_index, player_balls in enumerate(all_balls):
        draw_player_balls(surface, player_balls, player_index)

def draw_player_balls(surface, player_balls, player_index):
        number_of_reserve_balls = 0
        for ball in player_balls:
            slot = ball.args[0]
            if str(slot.name) == 'r':
                number_of_reserve_balls += 1
            elif str(slot.name) == 's':
                draw_ball_in_simple_slot(surface, ball, player_index)
            elif str(slot.name) == 'h':
                draw_ball_in_home_slot(surface, slot.args[0], player_index)

        draw_reserve_balls(surface, number_of_reserve_balls, player_index)

def draw_ball_in_simple_slot(surface, ball, player_index):
    draw_slot_disk(surface, get_simple_slot_position(ball.args[0].args[0]), get_player_ball_color(player_index))

def draw_ball_in_home_slot(surface, home_ball_index, player_index, color=None):
    if color is None:
        color = get_player_ball_color(player_index)

    home_radius = SLOT_CIRCLE_RADIUS - HOME_RADIAL_OFFSET
    home_slot_positions = tuple((i * HOME_SPACING + HOME_SPACING/2, 0.01*(i * HOME_SPACING + HOME_SPACING/2)**2) for i in range(-2, 2))
    home_slot_transform = (
        (WINDOW_WIDTH/2, WINDOW_HEIGHT/2 + home_radius, 0),
        (WINDOW_WIDTH/2 - home_radius, WINDOW_HEIGHT/2, -1),
        (WINDOW_WIDTH/2, WINDOW_WIDTH/2 - home_radius, -2),
        (WINDOW_WIDTH/2 + home_radius, WINDOW_HEIGHT/2, -3)
    ) [player_index]

    position_untranslated = rotate90(home_slot_positions[home_ball_index], home_slot_transform[2])
    position = (int(position_untranslated[0] + home_slot_transform[0]), int(position_untranslated[1] + home_slot_transform[1]))
    draw_slot_disk(surface, position, color)

def rotate90(coords, turns=1):
    turns = turns % 4
    for turn in range(turns):
        coords = (coords[1], -coords[0])
    return coords

def draw_reserve_balls(surface, number_of_reserve_balls, player_index):
    reserve_center_coordinates = (
        ((WINDOW_WIDTH + BOARD_SIZE) / 2 + RESERVE_OFFSET, (WINDOW_HEIGHT + BOARD_SIZE)/ 2 + RESERVE_OFFSET),
        ((WINDOW_WIDTH - BOARD_SIZE) / 2 - RESERVE_OFFSET, (WINDOW_HEIGHT + BOARD_SIZE) / 2 + RESERVE_OFFSET),
        ((WINDOW_WIDTH - BOARD_SIZE) / 2 - RESERVE_OFFSET, (WINDOW_HEIGHT - BOARD_SIZE) / 2 - RESERVE_OFFSET),
        ((WINDOW_WIDTH + BOARD_SIZE) / 2 + RESERVE_OFFSET, (WINDOW_HEIGHT - BOARD_SIZE)/ 2 - RESERVE_OFFSET)
    )[player_index]

    reserve_ball_offsets = (
        (RESERVE_INTERNAL_SIZE, RESERVE_INTERNAL_SIZE),
        (-RESERVE_INTERNAL_SIZE, RESERVE_INTERNAL_SIZE),
        (-RESERVE_INTERNAL_SIZE, -RESERVE_INTERNAL_SIZE),
        (RESERVE_INTERNAL_SIZE, -RESERVE_INTERNAL_SIZE)
    )

    for i in range(number_of_reserve_balls):
        position = (
            int(reserve_center_coordinates[0] + reserve_ball_offsets[i][0]),
            int(reserve_center_coordinates[1] + reserve_ball_offsets[i][1])
        )
        
        draw_slot_disk(surface, position, get_player_ball_color(player_index))
        
def draw_slot_disk(surface, position, color):
    pygame.draw.circle(surface, color, position, int(SLOT_RADIUS))
        
def compact(term):
    if type(term) is str:
        return term
    if type(term) is list:
        return '['+ ', '.join(map(compact, term)) + ']'
    if type(term) is Functor:
        return term.name.value + '(' + ', '.join(map(compact, term.args)) + ')'
    if type(term) is Atom:
        return term.value
    else:
        return str(term)

        
def compactify(game_state):
    game_state_stringified = {key: compact(val) for key, val in game_state.items()}
    return "game_state(all_balls({AllBalls}), all_cards({AllCards}), current_player_index({CurrentPlayerIndex}), turn_state({TurnState}))".format(**game_state_stringified)

# Actual program
pygame.init()
screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
done = False

Prolog.consult("tac")
game_state = next(Prolog.query("sample_state(game_state(all_balls(AllBalls), all_cards(AllCards), current_player_index(CurrentPlayerIndex), turn_state(TurnState)))"))

while not done:
    print(compactify(game_state))
    draw_everything(screen, game_state)
    pygame.display.flip()
    action = input("Enter action:")
    if (action == "quit"):
        done = True
        continue

    query = "InitialState = {}, player_action({}, {}, InitialState, game_state(all_balls(AllBalls), all_cards(AllCards), current_player_index(CurrentPlayerIndex), turn_state(TurnState)))".format(compactify(game_state), action, game_state["CurrentPlayerIndex"])
    next_state = next(Prolog.query(query), None)
    if next_state is not None:
        game_state = next_state
    else:
        print("Bad command!")

