-module(properjs).

-include_lib("proper/include/proper.hrl").

-export([
    start/0,
    main/1
  ]).

start() ->
  ok = erlang_js:start(),
  ok = application:start(properjs).

main(L) ->
  start(),

  FileName = filename:join([priv_dir(), "proper.js"]),
  {ok, ProperBinary} = file:read_file(FileName),

  {ok, JS} = js_driver:new(),
  js:define(JS, ProperBinary),
  {file, ObjectsToTest0} =
    lists:foldl(
      fun
        (<<"0">>, {object, Acc}) ->
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
  ObjectsToTest =
    case ObjectsToTest0 of
      [] -> [<<"Proper">>];
      _ -> lists:reverse(ObjectsToTest0)
    end,

  Success =
    lists:foldl(
      fun(ObjectName, FoldSuccess0) ->
          {ok, Props} = js:eval(JS, <<"PROPS(", ObjectName/binary, ".props)">>),
          lists:foldl(
            fun(Prop, FoldSuccess1) ->
                Success0 = prop(JS, ObjectName, Prop),
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

priv_dir() ->
  %% Hacky workaround to handle running from a standard app directory
  %% and .ez package
  case code:priv_dir(properjs) of
    {error, bad_name} ->
      filename:join([filename:dirname(code:which(?MODULE)), "..", "priv"]);
    Dir ->
      Dir
  end.

prop(JS, Module, PropName) ->
  NS = <<Module/binary, ".props.", PropName/binary, "()">>,

  {ok, Prop} = js:eval(JS, NS),

  io:format("property ~s~n", [NS]),
  proper:quickcheck(prop1(JS, Module, NS, Prop)).

prop1(JS, Module, NS0, {struct, [{<<"FORALL">>, [Props, _]}]}) ->
  PropsList = props_list(JS, Module, <<NS0/binary, ".FORALL[0]">>, Props),
  ?FORALL(Args, PropsList,
    begin
        F = <<NS0/binary, ".FORALL[1]">>,
        {ok, [Index, Prop]} = js:call(JS, <<"Proper.call">>, [F|Args]),
        NS = iolist_to_binary(["Proper.value(", integer_to_list(Index),")"]),
        prop1(JS, Module, NS, Prop)
    end
  );

prop1(JS, Module, NS0, {struct, [{<<"LET">>, [Props, _]}]}) ->
  PropsList = props_list(JS, Module, <<NS0/binary, ".LET[0]">>, Props),
  ?LET(Args, PropsList,
    begin
        NS = <<NS0/binary, ".LET[1]">>,
        F = <<"$f">>,
        ok = js:define(JS, <<"var ", F/binary, " = ", NS/binary>>),
        {ok, Prop} = js:call(JS, F, Args),
        Prop
        %prop1(JS, Module, <<NS/binary, "()">>, Prop)
    end
  );

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
prop1(_, _, _, {struct, [{<<"string">>, []}]}) ->
  string();

prop1(JS, Module, NS, {struct, [{<<"oneof">>, Props}]}) ->
  Choices = props_list(JS, Module, <<NS/binary, ".oneof">>, Props),
  oneof(Choices);

prop1(_JS, _Module, _NS, Prop) ->
  Prop.

% todo: this needs to follow the full tree of child elements
% so custom types can be used
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
