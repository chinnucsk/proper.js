.PHONY: deps test

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
	mkdir -p $(PREFIX)
	find deps -name .git | xargs rm -rf
	cp -r ebin deps properjs* priv $(PREFIX)
	mkdir -p $(PREFIX)/bin
	(cd $(PREFIX)/bin && ln -fs ../properjs pjs)

test:
	./properjs \
		priv/proper.js Proper \
		priv/string.js String \
		priv/array.js Array
