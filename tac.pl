:- use_module(library(lists)).

sample_state([
    [ball(s(0), nothot), ball(r(0), nothot), ball(r(0), nothot), ball(r(0), nothot)],
    [ball(s(2), nothot), ball(r(1), nothot), ball(r(1), nothot), ball(r(1), nothot)],
    [ball(r(2), nothot), ball(r(2), nothot), ball(r(2), nothot), ball(r(2), nothot)],
    [ball(h(0, 3), ishot), ball(r(3), nothot), ball(r(3), nothot), ball(r(3), nothot)]
]).
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

distance(X, X, 0, _, _, _):-!.
distance(Start, End, Distance, IsHot, Mode, P):-
    is_next(Start, Intermediate, IsHot, Mode, P),
    Ds is Distance - 1,
    distance(Intermediate, End, Ds, IsHot, Mode, P).

all_balls_are_home(PlayerBalls, PlayerIndex):-
    member(ball(h(0, PlayerIndex)), PlayerBalls),
    member(ball(h(1, PlayerIndex)), PlayerBalls),
    member(ball(h(2, PlayerIndex)), PlayerBalls),
    member(ball(h(3, PlayerIndex)), PlayerBalls).

move_other_player(AllBalls, StateFinal, PlayerIndex, MovementSize, MovementType):-
    nth0(PlayerIndex, AllBalls, PlayerBalls), all_balls_are_home(PlayerBalls, PlayerIndex),
    player_pair(PlayerIndex, PairIndex),
    move(AllBalls, StateFinal, PairIndex, MovementSize, MovementType).

move_direct(AllBalls, NewAllBalls, PlayerIndex, MovementSize, MovementType):-
    nth0(PlayerIndex, AllBalls, PlayerBalls), range(BallIndex, 0, 4), nth0(BallIndex, PlayerBalls, ball(BallPosition, IsHot)),
    distance(BallPosition, NewPosition, MovementSize, IsHot, MovementType, PlayerIndex),
    put(PlayerBalls, NewPlayerBalls, BallIndex, ball(NewPosition, 1)),
    put(AllBalls, NewAllBalls, PlayerIndex, NewPlayerBalls).


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
    move_ball_to_reserve(AllBalls, Slot, 3, _), !, fail.

put_ball(AllBalls, NewAllBalls, PlayerIndex, BallIndex, NewBall, _):-
    put_ball_no_displace(AllBalls, NewAllBalls, PlayerIndex, BallIndex, NewBall).

put_ball_no_displace(AllBalls, NewAllBalls, PlayerIndex, BallIndex, NewBall):-
    nth0(PlayerIndex, AllBalls, PlayerBalls),
    put(PlayerBalls, NewPlayerBalls, BallIndex, NewBall),
    put(AllBalls, NewAllBalls, PlayerIndex, NewPlayerBalls).

get_can_displace(1, _, can_displace):-!.
get_can_displace(_, distributed, can_displace):-!.
get_can_displace(_, _, can_not_displace):-!.
