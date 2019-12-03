:- use_module(library(lists)).

sample_state([
    [ball(s(0), ishot), ball(s(63), ishot), ball(s(62), ishot), ball(s(61), nothot)],
    [ball(s(0), ishot), ball(s(0), nothot), ball(s(0), nothot), ball(s(0), nothot)],
    [ball(s(0), ishot), ball(s(0), nothot), ball(s(0), nothot), ball(s(0), nothot)],
    [ball(s(0), ishot), ball(s(0), nothot), ball(s(0), nothot), ball(s(0), nothot)]
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

move_direct(AllBalls, StateFinal, PlayerIndex, MovementSize, MovementType):-
    nth0(PlayerIndex, AllBalls, PlayerBalls), range(BallIndex, 0, 4), nth0(BallIndex, PlayerBalls, ball(BallPosition, IsHot)),
    range(MoveSelf, 0, MovementSize), MoveOther is MovementSize - MoveSelf,
    distance(BallPosition, NewPosition, MoveSelf, IsHot, MovementType, PlayerIndex),
    put(PlayerBalls, NewPlayerBalls, BallIndex, ball(NewPosition, 1)),
    put(AllBalls, NewAllBalls, PlayerIndex, NewPlayerBalls),
    move_other_player(NewAllBalls, StateFinal, PlayerIndex, MoveOther, forward).

move(StateInitial, StateFinal, PlayerIndex, MovementSize, forward):- 
    move_direct(StateInitial, StateFinal, PlayerIndex, MovementSize, forward).

move(StateInitial, StateFinal, PlayerIndex, MovementSize, backward):-
    move_direct(StateInitial, StateFinal, PlayerIndex, MovementSize, backward).

move(AllBalls, StateFinal, PlayerIndex, MovementSize, distributed):-
    nth0(PlayerIndex, AllBalls, PlayerBalls), range(BallIndex, 0, 4), nth0(BallIndex, PlayerBalls, ball(BallPosition, IsHot)),
    is_next(BallPosition, NextPosition, IsHot, distributed, PlayerIndex), MovementSizeUpdated is MovementSize - 1,
    put(PlayerBalls, NewPlayerBalls, BallIndex, ball(NextPosition, ishot)),
    put(AllBalls, NewAllBalls, PlayerIndex, NewPlayerBalls),
    move_distributed_continue(NewAllBalls, StateFinal, PlayerIndex, MovementSizeUpdated).

move_distributed_continue(_, _, _, 0):-!.
move_distributed_continue(StateInitial, StateFinal, PlayerIndex, MovementSize):-
    move(StateInitial, StateFinal, PlayerIndex, MovementSize, distributed).

move_distributed_continue(StateInitial, StateFinal, PlayerIndex, MovementSize):-
    move_other_player(StateInitial, StateFinal, PlayerIndex, MovementSize, distributed).
