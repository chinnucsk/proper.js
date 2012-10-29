-module(properjs).

-include_lib("proper/include/proper.hrl").

-export([
    start/0,
    main/1
  ]).

start() ->
  ok = erlang_js:start(),
  ok = application:start(properjs).

main(_) ->
  start(),

  {ok, JS} = js_driver:new(),

  FileName = filename:join([priv_dir(), "proper.js"]),

  {ok, Binary} = file:read_file(FileName),
  ok = js:define(JS, Binary),

  {ok, Props} = js:eval(JS, <<"PROPS(Proper.props)">>),

  lists:foreach(fun(Prop) -> prop(JS, <<"Proper">>, Prop) end, Props).

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
        NS = <<NS0/binary, ".FORALL[1]">>,
        F = <<"$f">>,
        ok = js:define(JS, <<"var ", F/binary, " = ", NS/binary>>),
        {ok, Prop} = js:call(JS, F, Args),
        Prop
        % todo: nested FORALL(..., ..., FORALL(....)
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

prop1(_, _, _, {struct, [{Key, Args}]}) ->
  % property function catchall
  Atom = binary_to_atom(Key, utf8),
  apply(Atom, Args);
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
