-module(properjs).

-include_lib("proper/include/proper.hrl").

-export([
    main/1
  ]).

main(_) ->
  ok = erlang_js:start(),
  ok = application:start(properjs),

  {ok, JS} = js_driver:new(),

  FileName = filename:join([priv_dir(), "proper.js"]),

  {ok, Binary} = file:read_file(FileName),
  R = js:define(JS, Binary),
  io:format("R: ~p~n", [R]),

  Reversed = js:call(JS, <<"reverse">>, [<<"hellö">>]),
  io:format("Reversed ~p~n", [Reversed]),

  {ok, Props} = js:eval(JS, <<"PROPS(Proper.props)">>),

  lists:foreach(fun(Prop) -> prop(JS, <<"Proper">>, Prop) end, Props).

priv_dir() ->
  "/Users/steve/src/mokele/proper.js/priv".

prop(JS, Module, PropName) ->
  NS = <<Module/binary, ".props.", PropName/binary, "()">>,

  {ok, Prop} = js:eval(JS, NS),

  io:format("Prop: ~s()~n", [PropName]),
  proper:quickcheck(prop1(JS, Module, NS, Prop)),

  ok.

% require function registry and an opaque reference for them
% and always eval a function on that to return the ref from erlang

% generator for variables in js (function() { return generatorServer(name) })()
% after each attempt generatorServer is told to move to the next register
% FUN(function(){}) saves the function in the js and returns a reference to it

prop1(JS, Module, NS0, {struct, [{<<"FORALL">>, [Props, _]}]}) ->
  % {A, B, C, D...}
  % {fun() -> ... end, ...}
  PropsList = props_list(JS, Module, <<"todo: ns">>, Props),
  ?FORALL(Args, PropsList,
    begin
        NS = <<NS0/binary, ".FORALL[1]">>,
        F = <<"$f">>,
        ok = js:define(JS, <<"var ", F/binary, " = ", NS/binary>>),
        {ok, Prop} = js:call(JS, F, Args),
        Prop
        %prop1(JS, Module, NS, Prop),
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

props_list(JS, Module, NS, Props) ->
  io:format("  ~p~n", [Props]),
  lists:map(
    fun(Prop) ->
        prop1(JS, Module, NS, Prop)
    end,
    Props
  ).
