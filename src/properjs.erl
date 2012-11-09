-module(properjs).

-ifdef(EQC).
-include_lib("eqc/include/eqc.hrl").
-else.
-include_lib("proper/include/proper.hrl").
-endif.

-export([
    start/0,
    main/1
  ]).

start() ->
  ok = erlang_js:start(),
  start_qc().

-ifdef(EQC).
start_qc() ->
  ok = eqc:start().
-else.
start_qc() ->
  ok = application:start(properjs).
-endif.

opts() -> [
    %{path, "p", "path", {string, ".:test"}, "Path to find .js files separated with :s e.g. \".:lib\""}
  ].

main([]) -> getopt:usage(opts(), "pjs");
main(L) ->
  {ok, _Opts} = getopt:parse(opts(), L),

  start(),
  {ok, JS, ObjectsToTest} = js(L),
  Success =
    lists:foldl(
      fun(ObjectName, FoldSuccess0) ->
          {ok, Props} = js_eval(JS, <<"Proper.PROPS(", ObjectName/binary, ".props)">>),
          lists:foldl(
            fun(Prop, FoldSuccess1) ->
                {ok, JS0, _} = js(L),
                Success0 = prop(JS0, ObjectName, Prop),
                js_stop(JS0),
                if
                  not FoldSuccess1 -> false;
                  true -> Success0
                end
            end,
            FoldSuccess0,
            Props)
      end,
      true,
      ObjectsToTest
    ),
  halt(exitcode(Success)).

exitcode(true) -> 0;
exitcode(false) -> 1.

lib_dir(SubDir) ->
  %% Hacky workaround to handle running from a standard app directory
  %% and .ez package
  case code:lib_dir(properjs, SubDir) of
    {error, bad_name} ->
      filename:join([filename:dirname(code:which(?MODULE)), "..", atom_to_list(SubDir)]);
    Dir ->
      Dir
  end.

priv_dir() ->
  lib_dir(priv).

js_on_output(Format, [Data]) when Format =:= "~w~n"; Format =:= "~p~n" ->
  io:format("~s~n", [js_mochijson2:encode(Data)]);
js_on_output(Format, Data) ->
  io:format(Format, Data).

prop(JS, Module, PropName) ->
  NS = <<Module/binary, ".props.", PropName/binary, "()">>,

  {ok, Prop} = js_eval(JS, NS),

  io:format("property ~s~n", [NS]),
  qc(JS, Module, NS, Prop).

-ifdef(EQC).
qc(JS, Module, NS, Prop) ->
  eqc:quickcheck(on_output(fun js_on_output/2, prop1(JS, Module, NS, Prop))).
-else.
num_tests() ->
  case application:get_env(properjs, num_tests) of
    {ok, N} -> N;
    _ -> 100
  end.

qc(JS, Module, NS, Prop) ->
  Opts = [{on_output, fun js_on_output/2},num_tests()],
  proper:quickcheck(prop1(JS, Module, NS, Prop), Opts).
-endif.

prop1(JS, Module, NS0, {struct, [{<<"SUCHTHAT">>, [Props0, _]}]}) ->
  Props = prop1(JS, Module, <<NS0/binary, ".SUCHTHAT[0]">>, Props0),
  ?SUCHTHAT(Args, Props,
    begin
        F = <<NS0/binary, ".SUCHTHAT[1]">>,
        {ok, [Index, Prop]} = js_call(JS, <<"Proper.call">>, [F,Args]),
        NS = iolist_to_binary(["Proper.value(", integer_to_list(Index),")"]),
        prop1(JS, Module, NS, Prop)
    end
  );
%prop1(JS, Module, NS0, {struct, [{<<"SUCHTHATMAYBE">>, [Props0, _]}]}) ->
%  Props = prop1(JS, Module, <<NS0/binary, ".SUCHTHATMAYBE[0]">>, Props0),
%  ?SUCHTHATMAYBE(Args, Props,
%    begin
%        F = <<NS0/binary, ".SUCHTHATMAYBE[1]">>,
%        {ok, [Index, Prop]} = js_call(JS, <<"Proper.call">>, [F,Args]),
%        NS = iolist_to_binary(["Proper.value(", integer_to_list(Index),")"]),
%        prop1(JS, Module, NS, Prop)
%    end
%  );

prop1(JS, Module, NS0, {struct, [{<<"FORALL">>, [Props0, _]}]}) ->
  Props = props_list(JS, Module, <<NS0/binary, ".FORALL[0]">>, Props0),
  ?FORALL(Args, Props,
    begin
        F = <<NS0/binary, ".FORALL[1]">>,
        case js_call(JS, <<"Proper.call">>, [F|Args]) of
          {ok, [Index, Prop]} ->
            NS = iolist_to_binary(["Proper.value(", integer_to_list(Index),")"]),
            case Prop of
              null -> true;
              _ ->
                prop1(JS, Module, NS, Prop)
            end;
          {error, L} ->
            js_on_output("~p~n", [{struct, L}]),
            false
        end
    end
  );

prop1(JS, Module, NS0, {struct, [{<<"LET">>, [Props0, _]}]}) ->
  Props = props_list(JS, Module, <<NS0/binary, ".LET[0]">>, Props0),
  ?LET(Args, Props,
    begin
        F = <<NS0/binary, ".LET[1]">>,
        {ok, [Index, Prop]} = js_call(JS, <<"Proper.call">>, [F|Args]),
        NS = iolist_to_binary(["Proper.value(", integer_to_list(Index),")"]),
        prop1(JS, Module, NS, Prop)
    end
  );

prop1(JS, Module, NS0, {struct, [{<<"list">>, [Prop]}]}) ->
  ChildProp = prop1(JS, Module, <<NS0/binary, ".list[0]">>, Prop),
  list(ChildProp);

prop1(_, _, _, {struct, [{<<"neg_integer">>, []}]}) ->
  neg_integer();
prop1(_, _, _, {struct, [{<<"pos_integer">>, []}]}) ->
  pos_integer();
prop1(_, _, _, {struct, [{<<"non_neg_integer">>, []}]}) ->
  non_neg_integer();
prop1(_, _, _, {struct, [{<<"integer">>, []}]}) ->
  integer();
prop1(_, _, _, {struct, [{<<"integer">>, [A, B]}]}) ->
  integer(A, B);
prop1(_, _, _, {struct, [{<<"float">>, []}]}) ->
  float();
prop1(_, _, _, {struct, [{<<"float">>, [A, B]}]}) ->
  float(A, B);
prop1(_, _, _, {struct, [{<<"char_code">>, []}]}) ->
  char();
prop1(_, _, _, {struct, [{<<"string">>, []}]}) ->
  string();
%prop1(_, _, _, {struct, [{<<"list">>, []}]}) ->
%  % todo: list(js_supported_type())
%  list();

prop1(JS, Module, NS, {struct, [{<<"oneof">>, Props}]}) ->
  Choices = props_list(JS, Module, <<NS/binary, ".oneof">>, Props),
  oneof(Choices);

prop1(JS, Module, NS0, {struct, Props}) ->
  {struct, 
    lists:reverse(
      lists:foldl(
        fun
          ({K, V}, L) ->
            NS = <<NS0/binary, "['", K/binary, "']">>,
            [{K, prop1(JS, Module, NS, V)}|L];
          (P, L) ->
            [P|L]
        end,
        [],
        Props
      )
    )
  };

prop1(JS, Module, NS, Props) when is_list(Props) ->
  props_list(JS, Module, NS, Props);
prop1(_JS, _Module, _NS, Prop) ->
  Prop.

props_list(JS, Module, NS0, Props) ->
  lists:reverse(
    lists:foldl(
      fun(Prop, L) ->
          I = length(L),
          NS = iolist_to_binary([NS0, $[, integer_to_list(I), $]]),
          [prop1(JS, Module, NS, Prop)|L]
      end,
      [],
      Props
    )
  ).

js(L) ->
  FileName = filename:join([priv_dir(), "proper.js"]),
  Pid = spawn(fun() ->
      {ok, JS} = js_driver:new(),
      Paths = [lib_dir('.')],
      {ok, _} = js:eval(JS, list_to_binary(io_lib:format("proper_paths = ~p;", [Paths]))),
      js_driver:define_js(JS, {file, FileName}),
      {file, _} =
        lists:foldl(
          fun
            ("0", {object, Acc}) ->
              {file, Acc};
            (ObjectName, {object, Acc}) ->
              {file, [list_to_binary(ObjectName)|Acc]};
            (UserFileName, {file, Acc}) ->
              {ok, UserFileBinary} = file:read_file(UserFileName),
              ok = js:define(JS, UserFileBinary),
              {object, Acc}
          end,
          {file, []}, L
        ),
        js_loop(JS)
    end),
  {file, ObjectsToTest0} =
    lists:foldl(
      fun
        ("0", {object, Acc}) ->
          {file, Acc};
        (ObjectName, {object, Acc}) ->
          {file, [list_to_binary(ObjectName)|Acc]};
        (_UserFileName, {file, Acc}) ->
          {object, Acc}
      end,
      {file, []}, L
    ),
  ObjectsToTest =
    case ObjectsToTest0 of
      [] -> [<<"Proper">>];
      _ -> lists:reverse(ObjectsToTest0)
    end,
  {ok, Pid, ObjectsToTest}.

js_loop(JS) ->
  receive
    {eval, Pid, Eval} ->
      Pid ! {self(), js:eval(JS, Eval)},
      js_loop(JS);
    {call, Pid, F, Args} ->
      Pid ! {self(), js:call(JS, F, Args)},
      js_loop(JS);
    stop ->
      ok
  end.

js_eval(JS, Eval) ->
  JS ! {eval, self(), Eval},
  receive
    {JS, Any} ->
      Any
  end.

js_call(JS, F, Args) ->
  JS ! {call, self(), F, Args},
  receive
    {JS, Any} ->
      Any
  end.

js_stop(JS) -> JS ! stop.

-ifdef(EQC).

integer() ->
  int().

integer(A, B) -> choose(A, B).
non_neg_integer() ->
  ?SUCHTHAT(N, integer(), N > -1).
pos_integer() ->
  ?SUCHTHAT(N, integer(), N > 0).
neg_integer() ->
  ?SUCHTHAT(N, integer(), N < 0).

string() -> list(char()).

float() -> real().

float(A, B) ->
  ?LET(F, float(),
    if
      F < 0.5 -> ((1-F) * (B-A) + A);
      true -> (F * (B-A) + A)
    end
  ).

-endif.
