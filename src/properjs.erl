-module(properjs).

-export([
    main/1
  ]).

main(_) ->
  ok = erlang_js:start(),
  ok = application:start(properjs),

  {ok, JS} = js_driver:new(),

  js:define(JS, <<"var addOne = function(a){ return a + 1; }">>),

  FileName = filename:join([priv_dir(), "proper.js"]),
  io:format("FileName ~p~n", [FileName]),
  {ok, Binary} = file:read_file(FileName),

  R = js:define(JS, Binary),
  io:format("R: ~p~n", [R]),

  {ok, Hello} = js:call(JS, <<"helloworld">>, []),
  io:format("helloworld: ~s", [Hello]),

  {ok, Doubled} = js:call(JS, <<"fun2">>, [9]),
  io:format("Doubled: ~p~n", [Doubled]),

  {ok, N} = js:call(JS, <<"addOne">>, [3]),

  io:format("Hello World! ~p~n", [N]),
  ok.

priv_dir() ->
  "/Users/steve/src/mokele/proper.js/priv".
