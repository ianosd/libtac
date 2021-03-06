:- use_module(library(lists)).

sample_state(
    game_state(
	all_balls([
	    [ball(s(0), nothot), ball(r(0), nothot), ball(r(0), nothot), ball(r(0), nothot)],
	    [ball(r(1), nothot), ball(r(1), nothot), ball(r(1), nothot), ball(r(1), nothot)],
	    [ball(r(2), nothot), ball(r(2), nothot), ball(r(2), nothot), ball(r(2), nothot)],
	    [ball(h(0, 3), ishot), ball(r(3), nothot), ball(r(3), nothot), ball(r(3), nothot)]
	]),
	all_cards([
	    [7, 5],
	    [1, 7],
	    [5, 2],
	    [3, 4]
	]),
	current_player_index(0),
	turn_state(before_card)
    )
).

test(LastState):- sample_state(InitialState), player_action(play_card(7), 0, InitialState, LastState).

compute_turn_state_after_played_card(Card, InitialState, TurnState, PlayerIndex):-
    game_state(all_balls(AllBalls), all_cards(AllCards), current_player_index(PlayerIndex), turn_state(before_card)) = InitialState,
    basic_c(Card, TurnState),
    card_to_movement_type(Card, MovementType),
    move(AllBalls, _, PlayerIndex, Card, MovementType), !.

compute_turn_state_after_played_card(_, InitialState, before_card, NextPlayerIndex):-
    game_state(_, _, current_player_index(PlayerIndex), _) = InitialState,
    NextPlayerIndex is (PlayerIndex + 1) mod 4. 

basic_c(7, after_7(7)).
basic_c(X, after_card(X)):- member(X, [1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 13]).

card_to_movement_type(7, distributed).
card_to_movement_type(4, backward).
card_to_movement_type(X, forward):- member(X, [1, 2, 3, 5, 6, 8, 9, 10, 12, 13]).

player_action(play_card(Card), PlayerIndex, InitialState, NextState):-
    game_state(all_balls(AllBalls), all_cards(AllCards), current_player_index(PlayerIndex), turn_state(before_card)) = InitialState,
    nth0(PlayerIndex, AllCards, PlayerCards),
    select(Card, PlayerCards, UpdatedPlayerCards),
    put(AllCards, UpdatedAllCards, PlayerIndex, UpdatedPlayerCards),
    compute_turn_state_after_played_card(Card, InitialState, TurnState, NextPlayerIndex),
    NextState = game_state(all_balls(AllBalls), all_cards(UpdatedAllCards), current_player_index(NextPlayerIndex), turn_state(TurnState)).

check_can_move(PlayerIndex, PlayerIndex, _).
check_can_move(PlayerIndex, PairPlayer, AllBalls):-
    player_pair(PlayerIndex, PairPlayer),
    nth0(PlayerIndex, AllBalls, PlayerBalls),
    all_balls_are_home(PlayerBalls, PlayerIndex).

player_action(move(BallCollectionPlayerIndex, BallIndex, NewPosition), PlayerIndex, InitialState, NextState):-
    game_state(all_balls(AllBalls), AllCardsTerm, current_player_index(PlayerIndex), turn_state(TurnState)) = InitialState,
    check_can_move(PlayerIndex, BallCollectionPlayerIndex, AllBalls),
    get_move_ball_constraints(MaxDistance, Mode, TurnState),
    range(BallCollectionPlayerIndex, 0, 4), range(BallIndex, 0, 4),
    nth0(BallCollectionPlayerIndex, AllBalls, PlayerBalls), nth0(BallIndex, PlayerBalls, Ball),
    ball(Slot, IsHot) = Ball,
    is_distance_ok(MaxDistance, Distance, Mode),
    distance(Slot, NewPosition, Distance, IsHot, Mode, BallCollectionPlayerIndex),
    move_ball_in_steps(AllBalls, NewAllBalls, BallCollectionPlayerIndex, BallIndex, Distance, Mode),
    nth0(BallCollectionPlayerIndex, NewAllBalls, NewPlayerBalls), nth0(BallIndex, NewPlayerBalls, ball(NewPosition, _)),
    build_new_state_after_move(PlayerIndex, TurnState, NewAllBalls, AllCardsTerm, Distance, NextState).

player_action(put_ball_in_game(BallPlayerIndex), PlayerIndex, InitialState, NextState):-
    game_state(all_balls(AllBalls), AllCardsTerm, current_player_index(PlayerIndex), turn_state(TurnState)) = InitialState,
    can_put_ball_in_game(TurnState),
    put_ball_in_game(AllBalls, NewAllBalls, BallPlayerIndex),
    NextPlayerIndex is (PlayerIndex + 1) mod 4,
    NextState = game_state(all_balls(NewAllBalls), AllCardsTerm, current_player_index(NextPlayerIndex), turn_state(before_card)).

build_new_state_after_move(PlayerIndex, after_card(_), NewAllBalls, AllCardsTerm, _, NextState):-
    NextPlayerIndex is (PlayerIndex + 1) mod 4,
    NextState = game_state(all_balls(NewAllBalls), AllCardsTerm, current_player_index(NextPlayerIndex), turn_state(before_card)).

build_new_state_after_move(PlayerIndex, after_7(X), NewAllBalls, AllCardsTerm, MovedDistance, NextState):-
    NewAvailableDistance is X - MovedDistance,
    NewAvailableDistance > 0, !,
    NextState = game_state(all_balls(NewAllBalls), AllCardsTerm, current_player_index(PlayerIndex), turn_state(after_7(NewAvailableDistance))).

build_new_state_after_move(PlayerIndex, after_7(_), NewAllBalls, AllCardsTerm, _, NextState):-
    NextPlayerIndex is (PlayerIndex + 1) mod 4,
    NextState = game_state(all_balls(NewAllBalls), AllCardsTerm, current_player_index(NextPlayerIndex), turn_state(before_card)).

apply_motions(AllBalls, AllBalls, []).
apply_motions(AllBalls, NewAllBalls, [M|R]):- apply_motion(AllBalls, Intermediate, M), apply_motions(Intermediate, NewAllBalls, R).

can_put_ball_in_game(after_card(13)).
can_put_ball_in_game(after_card(1)).

get_move_ball_constraints(4, backward, after_card(4)):-!.
get_move_ball_constraints(X, distributed, after_7(X)):-!.
get_move_ball_constraints(X, forward, after_card(X)):-integer(X).

%not ok for 7
is_distance_ok(MaxDistance, WantedDistance, distributed):- Aug is MaxDistance + 1, range(WantedDistance, 1, Aug).
is_distance_ok(X, X, _).

play(InitialState, NextState, PlayedCard):-
    play_no_throwaway(InitialState, NextState, PlayedCard).

play(InitialState, NextState, _):-
    play_no_throwaway(InitialState, NextState, _), !, fail.
    
play(InitialState, NextState, PlayedCard):-
    InitialState = game_state(AllBalls, all_cards(Cards), current_player_index(PlayerIndex)),
    nth0(PlayerIndex, Cards, PlayerCards),
    select(PlayedCard, PlayerCards, UpdatedPlayerCards),
    put(Cards, UpdatedCards, PlayerIndex, UpdatedPlayerCards),
    NextPlayerIndex is (PlayerIndex + 1) mod 4,
    NextState = game_state(AllBalls, all_cards(UpdatedCards), current_player_index(NextPlayerIndex)).

play_no_throwaway(InitialState, NextState, PlayedCard):-
    InitialState = game_state(all_balls(Balls), all_cards(Cards), current_player_index(PlayerIndex)),
    nth0(PlayerIndex, Cards, PlayerCards),
    select(PlayedCard, PlayerCards, UpdatedPlayerCards),
    play_card(Balls, NewBalls, PlayerIndex, PlayedCard),
    put(Cards, UpdatedCards, PlayerIndex, UpdatedPlayerCards),
    NextPlayerIndex is (PlayerIndex + 1) mod 4,
    NextState = game_state(all_balls(NewBalls), all_cards(UpdatedCards), current_player_index(NextPlayerIndex)).

play_card(AllBalls, NewBalls, PlayerIndex, 1) :- put_ball_in_game(AllBalls, NewBalls, PlayerIndex).
play_card(AllBalls, NewBalls, PlayerIndex, 13):- put_ball_in_game(AllBalls, NewBalls, PlayerIndex).
play_card(AllBalls, NewBalls, PlayerIndex, 7) :- move(AllBalls, NewBalls, PlayerIndex, 7, distributed).
play_card(_, _, _, 7) :- !, fail.
play_card(AllBalls, NewBalls, PlayerIndex, 4) :- move(AllBalls, NewBalls, PlayerIndex, 4, backward).
play_card(_, _, _, 4) :- !, fail.
play_card(AllBalls, NewBalls, PlayerIndex, X) :- number(X), move(AllBalls, NewBalls, PlayerIndex, X, forward).

range(Low, Low, _).
range(X, Low, High) :- NewLow is Low + 1, NewLow < High, range(X, NewLow, High).

are_neighbors64(N, M):- range(N, 0, 63), M is N + 1.
are_neighbors64(63, 0).

put([_|T], [X|T], 0, X):-!.
put([H|T], [H|NewT], N, X):- Nm is N - 1, put(T, NewT, Nm, X).

player_pair(0, 2).
player_pair(2, 0).
player_pair(1, 3).
player_pair(3, 1).

player_start_slot(0, s(0)).
player_start_slot(1, s(16)).
player_start_slot(2, s(32)).
player_start_slot(3, s(48)).

% enter home
is_next(s(0), h(0, 0), ishot, _, 0).
is_next(s(16), h(0, 1), ishot, _, 1).
is_next(s(32), h(0, 2), ishot, _, 2).
is_next(s(48), h(0, 3), ishot, _, 3).

% move inside home
is_next(h(X, P), h(Y, P), ishot, _, P):- range(X, 0, 3), Y is X + 1.
is_next(h(X, P), h(Y, P), ishot, distributed, P):-  range(X, 0, 3), Y is X + 1.

% move on the board
is_next(s(X), s(Y), _, forward, _):- are_neighbors64(X, Y).
is_next(s(X), s(Y), _, distributed, P):- is_next(s(X), s(Y), _, forward, P).
is_next(s(X), s(Y), _, backward, _):- are_neighbors64(Y, X).

distance3(X, X, Accum, Accum, IsHot, Mode, P).
distance3(X, Y, Distance, Accum, IsHot, Mode, P):-
    Accum < 64,
    is_next(X, A, IsHot, Mode, P),
    Accum2 is Accum + 1,
    distance3(A, Y, Distance, Accum2, IsHot, Mode, P).

distance(X, Y, D, IsHot, Mode, P):-distance3(X, Y, D, 0, IsHot, Mode, P).

all_balls_are_home(PlayerBalls, PlayerIndex):-
    member(ball(h(0, PlayerIndex), _), PlayerBalls),
    member(ball(h(1, PlayerIndex), _), PlayerBalls),
    member(ball(h(2, PlayerIndex), _), PlayerBalls),
    member(ball(h(3, PlayerIndex), _), PlayerBalls).

put_ball_in_game(AllBalls, StateFinal, PlayerIndex):-
    nth0(PlayerIndex, AllBalls, PlayerBalls),
    player_reserve_ball(PlayerBalls, ReserveBallIndex),
    player_start_slot(PlayerIndex, Slot),
    put_ball(AllBalls, StateFinal, PlayerIndex, ReserveBallIndex, ball(Slot, not_hot), can_displace).

player_reserve_ball([ball(r(_), _)|_], 0):-!.
player_reserve_ball([_|Rest], Index):- player_reserve_ball(Rest, IndexRest), Index is IndexRest + 1.

move(X, X, _, 0, _):-!.

move(StateInitial, StateFinal, PlayerIndex, MovementSize, forward):- 
    move_single_ball(StateInitial, StateFinal, PlayerIndex, MovementSize, forward).

move(StateInitial, StateFinal, PlayerIndex, MovementSize, backward):-
    move_single_ball(StateInitial, StateFinal, PlayerIndex, MovementSize, backward).

move(AllBalls, StateFinal, PlayerIndex, MovementSize, distributed):-
    nth0(PlayerIndex, AllBalls, PlayerBalls), range(BallIndex, 0, 4), nth0(BallIndex, PlayerBalls, ball(BallPosition, IsHot)),
    is_next(BallPosition, NextPosition, IsHot, distributed, PlayerIndex), MovementSizeUpdated is MovementSize - 1,
    put_ball(AllBalls, NewAllBalls, PlayerIndex, BallIndex, ball(NextPosition, is_hot), can_displace),
    move(NewAllBalls, StateFinal, PlayerIndex, MovementSizeUpdated, distributed).

move(AllBalls, StateFinal, PlayerIndex, MovementSize, distributed):-
    move_other_player(AllBalls, StateFinal, PlayerIndex, MovementSize, distributed).

move_other_player(AllBalls, StateFinal, PlayerIndex, MovementSize, MovementType):-
    nth0(PlayerIndex, AllBalls, PlayerBalls), all_balls_are_home(PlayerBalls, PlayerIndex),
    player_pair(PlayerIndex, PairIndex),
    move(AllBalls, StateFinal, PairIndex, MovementSize, MovementType).

move_ball_to_reserve([], _, _):- !, fail.
move_ball_to_reserve([PlayerBalls|R], Position, PlayerIndex, [AlteredPlayerBalls|R]):-
    position_is_occupied_in_player_balls(PlayerBalls, Position, PlayerIndex, AlteredPlayerBalls), !.
move_ball_to_reserve([H| Rest],  Position, PlayerIndex, [H|AlteredRest]):-
    NewPlayerIndex is PlayerIndex + 1,
    move_ball_to_reserve(Rest, Position, NewPlayerIndex, AlteredRest), !.

position_is_occupied_in_player_balls([ball(Position, _)|Rest], Position, PlayerIndex, [ball(r(PlayerIndex), not_hot)|Rest]):-!.
position_is_occupied_in_player_balls([H|Rest], Position, PlayerIndex, [H|AlteredRest]):-
    position_is_occupied_in_player_balls(Rest, Position, PlayerIndex, AlteredRest).

move_player_ball_to_reserve([], _, _, _):- !, fail.
move_player_ball_to_reserve([ball(Slot, _)|Rest], Slot, PlayerIndex, [ball(r(PlayerIndex))|Rest]):-!.
move_player_ball_to_reserve([_, Rest], Slot, PlayerIndex, AlteredRest):- move_player_ball_to_reserve(Rest, Slot, PlayerIndex, AlteredRest), !.


    
move_single_ball(AllBalls, StateFinal, PlayerIndex, MovementSize, MovementType):-
    range(BallIndex, 0, 4),
    move_ball_in_steps(AllBalls, StateFinal, PlayerIndex, BallIndex, MovementSize, MovementType).

move_ball_in_steps(X, X, _, _, 0, _):-!.
move_ball_in_steps(AllBalls, NewAllBalls, PlayerIndex, BallIndex, MovementSize, MovementType):-
    nth0(PlayerIndex, AllBalls, PlayerBalls), nth0(BallIndex, PlayerBalls, ball(BallPosition, IsHot)),
    is_next(BallPosition, NextPosition, IsHot, MovementType, PlayerIndex),
    get_can_displace(MovementSize, MovementType, CanDisplace),
    put_ball(AllBalls, Intermediate, PlayerIndex, BallIndex, ball(NextPosition, is_hot), CanDisplace),
    MovementSizeUpdated is MovementSize - 1,
    move_ball_in_steps(Intermediate, NewAllBalls, PlayerIndex, BallIndex, MovementSizeUpdated, MovementType).

move_ball_in_steps(AllBalls, NewAllBalls, PlayerIndex, _, MovementSize, MovementType):-
    move_other_player(AllBalls, NewAllBalls, PlayerIndex, MovementSize, MovementType). 


put_ball(AllBalls, NewAllBalls, PlayerIndex, BallIndex, NewBall, can_displace):-
    ball(Slot, _) = NewBall,
    move_ball_to_reserve(AllBalls, Slot, 0, AlteredBalls),
    put_ball_no_displace(AlteredBalls, NewAllBalls, PlayerIndex, BallIndex, NewBall), !.

put_ball(AllBalls, _, _, _, ball(Slot, _), can_not_displace):-
    move_ball_to_reserve(AllBalls, Slot, 0, _), !, fail.

put_ball(AllBalls, NewAllBalls, PlayerIndex, BallIndex, NewBall, _):-
    put_ball_no_displace(AllBalls, NewAllBalls, PlayerIndex, BallIndex, NewBall).

put_ball_no_displace(AllBalls, NewAllBalls, PlayerIndex, BallIndex, NewBall):-
    nth0(PlayerIndex, AllBalls, PlayerBalls),
    put(PlayerBalls, NewPlayerBalls, BallIndex, NewBall),
    put(AllBalls, NewAllBalls, PlayerIndex, NewPlayerBalls).

get_can_displace(1, _, can_displace):-!.
get_can_displace(_, distributed, can_displace):-!.
get_can_displace(_, _, can_not_displace):-!.
