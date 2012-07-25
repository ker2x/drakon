% Autogenerated with DRAKON Editor 1.10

-module(erltest).
-export([mult/2, run/0, switch/1]).

assert(Expected, Actual) ->
    % item 20
    if Expected == Actual -> 
        % item 19
        void
    ; true ->
        % item 42
        io:format("expected: ~w~n", [Expected]),
        io:format("actual: ~w~n", [Actual]),
        % item 23
        throw("assert failed")
    end
.

mult(Left, Right) ->
    % item 12
    Left * Right
.

nested_if(X, Y, Z) ->
    % item 31
    if X == 10 -> 
        % item 30
        x
    ; true ->
        % item 33
        if Y == 10 -> 
            % item 37
            y
        ; true ->
            % item 35
            if Z == 10 -> 
                % item 38
                z
            ; true ->
                % item 40
                none
            end
        end
    end
.

run() ->
    % item 6
    assert(15, mult(5, 3)),
    % item 41
    assert(x, nested_if(10, 20, 30)),
    assert(y, nested_if(20, 10, 30)),
    assert(z, nested_if(30, 20, 10)),
    assert(none, nested_if(40, 20, 30)),
    assert(x, nested_if(10, 10, 10)),
    % item 76
    assert({10, 100, 20}, sil_if(10, 10, 20)),
    assert({10, 200, 20}, sil_if(10, -10, 20)),
    % item 93
    assert(one, switch(1)),
    assert(two, switch(2)),
    assert(three, switch(3)),
    % item 24
    success
.

sil_if(X, Y, Z) ->
    % item 57
    if X > 0 -> 
        % item 58
        X2 = X,
        % item 65
        if Y > 0 -> 
            % item 66
            Y2 = 100,
            Z2 = Z
        ; true ->
            % item 67
            Y2 = 200,
            Z2 = Z
        end
    ; true ->
        % item 59
        X2 = -X,
        % item 70
        if Z > 0 -> 
            % item 71
            Z2 = 1000,
            Y2 = Y
        ; true ->
            % item 72
            Z2 = 3000,
            Y2 = Y
        end
    end,
    % item 75
    {X2, Y2, Z2}
.

switch(X) ->
    % item 800001
    if X == 1 -> 
        % item 90
        one
    ; true ->
        % item 800002
        if X == 2 -> 
            % item 91
            two
        ; true ->
            % item 800003
            if X == 3 -> 
                []
            ; true ->
                % item 800004
                throw("Unexpected switch value")
            end,
            % item 92
            three
        end
    end
.

