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

function list() {
    // todo: rename $list to not confuse with a actual object
    // with this property. This requires everything to change
    // e.g. $FORALL, $oneof, etc, etc or $.FORALL etc
    var a = [];
    for(var i=0; i<arguments.length; i++) {
        a.push(arguments[i]);
    };
    return {
        list: a
    };
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

(function() {
    var my_object_type = function(type) {
        return {
            greeting: "Hello World!",
            id: pos_integer(),
            listoftype: [type, type, type],
            type: type
        };
    };
    var my_list_type = function(type) {
        return [type, type, type, type];
    };

    Proper.props = {
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
        },
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
        let_let: function() {
            var my_nested_let = function() {
                // create an array of integers but the first
                // element is 1 larger than the rest which are 
                // all the same.
                return LET([pos_integer()],
                    function(i) {
                        return LET([list(i)],
                            function(a) {
                                a.push(i);// force it to have 2 items
                                a.push(i);
                                var shift = a.shift();
                                a.unshift(shift+1);
                                return a;
                            }
                        );
                    }
                );
            };
            return FORALL([my_nested_let()],
                function(a) {
                    var first = a[0];
                    for(var i=1; i<a.length; i++) {
                        if(first != a[i] + 1) {
                            return false;
                        }
                    }
                    return true;
                }
            );
        },
        list: function() {
            return FORALL([list(integer())],
                function(list) {
                    for(var i=0; i<list.length; i++) {
                        if(typeof list[i] != 'number') {
                            return false;
                        }
                    }
                    return true;
                }
            );
        },
        my_object_type: function() {
            return FORALL([oneof(pos_integer(), boolean())],
                function(type) {
                    return FORALL([my_object_type(type)],
                        function(my_object) {
                            return my_object.greeting == "Hello World!"
                                && typeof my_object.id == 'number'
                                && my_object.id > 0
                                && typeof my_object.type == typeof type
                                && typeof my_object.listoftype[0] == typeof type
                                && typeof my_object.listoftype[1] == typeof type
                                && typeof my_object.listoftype[2] == typeof type;

                        }
                    );
                }
            );
        },
        my_list_type: function() {
            return FORALL([oneof(pos_integer(), boolean())],
                function(type) {
                    return FORALL([my_list_type(type)],
                        function(my_list) {
                            return typeof my_list[0] == typeof type
                                && typeof my_list[1] == typeof type
                                && typeof my_list[2] == typeof type
                                && typeof my_list[3] == typeof type;
                        }
                    );
                }
            );
        }
    };
})();
