#!/bin/sh
erl -pa ebin/ deps/*/ebin -noshell -eval 'properjs:main([])' -s erlang halt
