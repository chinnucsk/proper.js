.PHONY: deps

all: deps compile

deps:
	./test/rebar get-deps

compile:
	./test/rebar compile

compile_eqc:
	./test/rebar compile -DEQC

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
