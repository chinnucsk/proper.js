-module(properjs).

-include_lib("proper/include/proper.hrl").

-export([
    main/1
  ]).

-compile(export_all).

main(_) ->
  ok = erlang_js:start(),
  ok = application:start(properjs),

  {ok, JS} = js_driver:new(),

  FileName = filename:join([priv_dir(), "proper.js"]),
  io:format("FileName ~p~n", [FileName]),

  {ok, Binary} = file:read_file(FileName),
  R = js:define(JS, Binary),
  io:format("R: ~p~n", [R]),


  {ok, Props} = js:eval(JS, <<"PROPS(Proper.props)">>),

  lists:foreach(fun(Prop) -> prop(JS, <<"Proper">>, Prop) end, Props).

priv_dir() ->
  "/Users/steve/src/mokele/proper.js/priv".

prop(JS, Module, PropName) ->
  NS = <<Module/binary, ".props.", PropName/binary, "()">>,

  io:format("NS ~p~n", [NS]),
  {ok, Prop} = js:eval(JS, NS),

  proper:quickcheck(prop1(JS, Module, NS, Prop)),

  ok.

a_prop() ->
  io:format("a_prop()~n", []),
  true.

% require function registry and an opaque reference for them
% and always eval a function on that to return the ref from erlang

% generator for variables in js (function() { return generatorServer(name) })()
% after each attempt generatorServer is told to move to the next register
% FUN(function(){}) saves the function in the js and returns a reference to it

prop1(JS, Module, NS0, {struct, [{<<"FORALL">>, [Props, _]}]}) ->
  % {A, B, C, D...}
  % {fun() -> ... end, ...}
  io:format("Hello~n", []),
  ?FORALL(Tuple, {pos_integer()},
    begin
        %N > 0
        NS = <<NS0/binary, ".FORALL[1]">>,
        F = <<"$f">>,
        ok = js:define(JS, <<"var ", F/binary, " = ", NS/binary>>),
        {ok, Prop} = js:call(JS, F, tuple_to_list(Tuple)),
        Prop
        %prop1(JS, Module, NS, Prop),
    end
  );
prop1(_, _, NS, {struct, [{<<"fun">>, _}]}) ->
  io:format("    begin~n"),
  io:format("      properjs:call(~p)~n", [NS]),
  io:format("    end~n");
prop1(_JS, Module, NS, Prop) ->
  io:format("Prop ~p ~p ~p~n", [Module, NS, Prop]).
