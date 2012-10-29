#!/usr/bin/env escript

main(L) ->
  Dir = filename:dirname(escript:script_name()),
  true = code:add_pathz(filename:join(Dir, "ebin")),
  true = code:add_pathz(filename:join([Dir, "deps", "erlang_js", "ebin"])),
  true = code:add_pathz(filename:join([Dir, "deps", "proper", "ebin"])),
  properjs:main(L).
