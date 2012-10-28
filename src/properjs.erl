-module(properjs).

-export([
    main/1
  ]).

main(_) ->
  ok = erlang_js:start(),
  ok = application:start(properjs),

  {ok, JS} = js_driver:new(),

  FileName = filename:join([priv_dir(), "proper.js"]),
  io:format("FileName ~p~n", [FileName]),

  {ok, Binary} = file:read_file(FileName),
  R = js:define(JS, Binary),
  io:format("R: ~p~n", [R]),

  {ok, Props} = js:eval(JS, <<"props(Proper.props)">>),

  lists:foreach(fun(Prop) -> prop(JS, <<"Proper">>, Prop) end, Props).

priv_dir() ->
  "/Users/steve/src/mokele/proper.js/priv".

prop(JS, Module, PropName) ->
  NS0 = <<Module/binary, ".props">>,
  {ok, Prop} = js:call(JS, <<NS0/binary, ".", PropName/binary>>, []),
  io:format("~s() ->~n", [PropName]),

  NS = <<NS0/binary, ".", PropName/binary, "()">>,
  prop1(JS, Module, NS, Prop),

  io:format(".~n"),
  ok.


prop1(JS, Module, NS0, {struct, [{<<"FORALL">>, [Props, _]}]}) ->
  % {A, B, C, D...}
  io:format("  ?FORALL({~p},~n", [Props]),

  NS = <<NS0/binary, ".FORALL[1]">>,
  {ok, Prop} = js:eval(JS, NS),
  prop1(JS, Module, NS, Prop);

prop1(_, _, _NS, {struct, [{<<"fun">>, _}]}) ->
  io:format("    begin~n"),
  io:format("~n"),
  io:format("    end~n");
prop1(_JS, Module, NS, Prop) ->
  io:format("Prop ~p ~p ~p~n", [Module, NS, Prop]).
