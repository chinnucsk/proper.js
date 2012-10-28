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

  lists:foreach(fun(Prop) -> prop(Prop, JS) end, Props).

priv_dir() ->
  "/Users/steve/src/mokele/proper.js/priv".


prop(PropName, JS) ->
  {ok, Prop} = js:call(JS, <<"Proper.props.", PropName/binary>>, []),

  io:format("Prop ~p~n", [Prop]),
  ok.
