.PHONY: deps

all: deps compile

deps:
	./rebar get-deps

compile:
	./rebar compile

test:
	./properjs \
		priv/proper.js Proper \
		priv/string.js String \
		priv/array.js Array
