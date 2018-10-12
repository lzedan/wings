%%%-------------------------------------------------------------------
%%% @author Dan Gudmundsson <dgud@erlang.org>
%%% @copyright (C) 2016, Dan Gudmundsson
%%% @doc
%%%
%%% @end
%%% Created : 20 May 2016 by Dan Gudmundsson <dgud@erlang.org>
%%%-------------------------------------------------------------------
-module(int_test).

-compile(export_all).

-define(VS, {{ 0.5,  1.0, -0.5},  %1
             { 0.5,  0.0, -0.5},  %2
             {-0.5,  0.0, -0.5},
             {-0.5,  1.0, -0.5},  %4
             {-0.5,  1.0,  0.5},
             { 0.5,  1.0,  0.5},  %6
             { 0.5,  0.0,  0.5},
             {-0.5,  0.0,  0.5}}).%8

-define(FS, [[0,1,2,3],
	     [2,7,4,3],
	     [0,5,6,1],
	     [5,4,7,6],
	     [5,0,3,4],
	     [6,7,2,1]]).


go() ->  start().

start() ->
    Ref = make_model(ref_cube, {0.0, 0.0, 0.0}),
    test(Ref, {0.0, 1.5, 0.0}),
    test(Ref, {0.25, 0.9, 0.25}),
    io:format("Test triangles~n",[]),
    [_] = R0 = test_tri(Ref, [{0.0, 0.6, 0.0}, {1.0, 0.6, 0.0}, {1.0, 0.6, 0.25}]),
    io:format("Tri: ~p ~p~n", [?LINE-1, R0]),
    [_,_] = R1 = test_tri(Ref, [{0.0, 0.5, 0.1}, {1.0, 0.5, 0.1}, {1.0, 0.5, -0.25}]),
    io:format("Tri: ~p ~p~n", [?LINE-1, R1]),

    %% Line
    [A,B,C] = [{0.0, 0.6, 0.0}, {0.8, 0.6, 0.0}, {1.0, 0.6, 0.0}],
    [_] = R2 = test_tri(Ref, [A,B,C]),
    io:format("Tri: ~p ~p~n", [?LINE-1, R2]),
    [_] = R3 = test_tri(Ref, [B,C,A]),
    io:format("Tri: ~p ~p~n", [?LINE-1, R3]),
    [_] = R4 = test_tri(Ref, [C,A,B]),
    io:format("Tri: ~p ~p~n", [?LINE-1, R4]),

    ok.

test_tri(Ref, TriVs) ->
    TriBvh = make_tri(1, TriVs),
    e3d_bvh:intersect(e3d_bvh:init(Ref), e3d_bvh:init(TriBvh)).

test(Ref, Trans) ->
    M = make_model(1, Trans),
    Hits0 = e3d_bvh:intersect(e3d_bvh:init(Ref), e3d_bvh:init(M)),
    Hits = [I || I = #{p1:=P1,p2:=P2} <- Hits0, P1 =/= P2],
    io:format("~p: ~p~n", [length(Hits0),Hits]), %length(Hits)]),
    test2(Hits, Ref, M).

test2([], _, _) -> ok;
test2(Hits0, _Ref, _Other) ->
    [io:format(" ~p:~.2w  ~p:~.2w ~.5w ~s ~s~n", [M1,F1,M2,F2,P1==P2,f(P1),f(P2)])
     || #{mf1:={M1,F1},mf2:={M2,F2},p1:={P1,_,_},p2:={P2,_,_}} <- Hits0],
    %Hits1 = filter_tess_edges(Hits0, Ref, Other),
    ok.

make_tri(MeshId, Vs) ->
    GetFace = fun({verts,_Face}) -> {0,1,2};
		 (verts) -> array:from_list(Vs);
		 (meshId) -> {tri,MeshId}
	      end,
    [{1, GetFace}].

make_model(MeshId, Trans) ->
    Fs = lists:append([ [{V1,V2,V3},{V1,V3,V4}] || [V1,V2,V3,V4] <- ?FS]),
    TFs = list_to_tuple(Fs),
    Vs = array:from_list([e3d_vec:add(Trans, Point) || Point <- tuple_to_list(?VS)]),
    format_faces(0, Fs, Vs),
    GetFace = fun({verts,Face}) -> element(Face+1, TFs);
		 (verts) -> Vs;
		 (meshId) -> MeshId
	      end,
    [{tuple_size(TFs), GetFace}].

format_faces(I, [FVs={V1,V2,V3}|Fs], Vs) ->
    io:format("~.3w ~p => [~s,~s,~s]~n",
	      [I, FVs, f(array:get(V1,Vs)),f(array:get(V2,Vs)),f(array:get(V3,Vs))]),
    format_faces(I+1, Fs,Vs);
format_faces(_,[],_) -> ok.

f({X,Y,Z}) ->
    io_lib:format("{~5.2f, ~5.2f, ~5.2f}", [X,Y,Z]);
f(X) when is_float(X) ->
    io_lib:format("~6.3f", [X]);
f(X) when is_integer(X) ->
    io_lib:format("~p", [X]).
