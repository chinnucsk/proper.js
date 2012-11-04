.PHONY: deps

all: deps compile

deps:
	./rebar get-deps

compile:
	./rebar compile

compile_eqc:
	./rebar compile -DEQC

cleanebin:
	rm -f ebin/*.beam

install:
	ln -s `pwd`/properjs $(PREFIX)/bin/pjs

test:
	./properjs \
		priv/proper.js Proper \
		priv/string.js String \
		priv/array.js Array
