.PHONY: deps

all: deps compile

deps:
	./rebar get-deps

compile:
	./rebar compile

test:
	./properjs.sh
