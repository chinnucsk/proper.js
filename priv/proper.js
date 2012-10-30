var log = function(s) {
    ejsLog("/tmp/erlang_js.txt", s);
}

function PROPS(hash) {
    var props = [];
    for(k in hash) {
        props.push(k);
    }
    return props;
}

function FORALL(arg_props, f) {
    return {
        FORALL: [arg_props, f]
    };
}

function LET(arg_props, f) {
    return {
        LET: [arg_props, f]
    };
}

function oneof() {
    var args = arguments;
    if(args.length == 1) {
        args = args[0];
    }
    var a = [];
    for(var i=0; i<args.length; i++) {
        a.push(args[i]);
    };
    return {oneof: a};
}

function string() {
    return {string: []};
}
function pos_integer() {
    return {pos_integer: []};
}
function neg_integer() {
    return {neg_integer: []};
}
function non_neg_integer() {
    return {non_neg_integer: []};
}
function integer() {
    var a = [];
    for(var i=0; i<arguments.length; i++) {
        a.push(arguments[i]);
    };
    return {integer: a};
}

function even_number() {
    return LET([integer()],
        function(i) {
            return i * 2;
        }
    );
}
function odd_number() {
    return LET([even_number()],
        function(i) {
            return i*2 - 1;
        }
    );
}

function boolean() {
    return oneof(true, false);
}
function odd_or_even(b) {
    return b ? odd_number() : even_number();
}

var Proper = (function() {
    var returnValues = [];
    return {
        reset: function() {
            returnValues = [];
        },
        call: function() {
            var f = eval(arguments[0]);
            var a = [];
            for(var i=1; i<arguments.length; i++) {
                a.push(arguments[i]);
            }
            var index = returnValues.length;
            var value = f.apply(this, a);
            returnValues.push(value);
            return [index, value];
        },
        value: function(index) {
            return returnValues[index];
        }
    };
})();


Proper.props = {
    forall_forall: function() {
        // todo: write less contrived nested FORALL property
        return FORALL([boolean()],
            function(b) {
                return FORALL([odd_or_even(b)],
                    function(i) {
                        return Math.abs(i % 2) == (b ? 1 : 0);
                    }
                );
            }
        );
    },
    oneof: function() {
        return FORALL([oneof(true, false)],
            function(n) {
                return n === true || n === false;
            }
        )
    },
    even_number: function() {
        return FORALL([even_number()],
            function(i) {
                return i % 2 == 0;
            }
        );
    },
    pos_integer: function() {
        return FORALL([pos_integer()],
            function(i) {
                return i > 0
            }
        );
    },
    neg_integer: function() {
        return FORALL([neg_integer()],
            function(i) {
                return i < 0
            }
        );
    },
    non_neg_integer: function() {
        return FORALL([non_neg_integer()],
            function(i) {
                return i >= 0
            }
        );
    }
};
