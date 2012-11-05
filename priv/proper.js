var console = {
    log: function() {
        var s = "";
        for(var i=0; i<arguments.length; i++) {
            s += " " + arguments[i];
        }
        ejsLog("/tmp/erlang_js.txt", s);
    }
}

function clone(obj) {
    // Handle the 3 simple types, and null or undefined
    if (null == obj || "object" != typeof obj) return obj;

    // Handle Date
    if (obj instanceof Date) {
        var copy = new Date();
        copy.setTime(obj.getTime());
        return copy;
    }

    // Handle Array
    if (obj instanceof Array) {
        var copy = [];
        for (var i = 0; i< obj.length; ++i) {
            copy[i] = clone(obj[i]);
        }
        return copy;
    }

    // Handle Object
    if (obj instanceof Object) {
        var copy = {};
        for (var attr in obj) {
            if (obj.hasOwnProperty(attr)) copy[attr] = clone(obj[attr]);
        }
        return copy;
    }

    throw new Error("Unable to copy obj! Its type isn't supported.");
}

function SUCHTHATMAYBE(arg_props, f) {
    return {
        SUCHTHATMAYBE: [arg_props, f]
    };
}
function SUCHTHAT(arg_props, f) {
    return {
        SUCHTHAT: [arg_props, f]
    };
}
function FORALL() {
    var arg_props = [];
    for(var i=0; i<arguments.length-1; i++) {
        arg_props.push(arguments[i]);
    }
    var f = arguments[arguments.length-1];
    return {
        FORALL: [arg_props, f]
    };
}

function LET() {
    var arg_props = [];
    for(var i=0; i<arguments.length-1; i++) {
        arg_props.push(arguments[i]);
    }
    var f = arguments[arguments.length-1];
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

function array() {
    var a = [];
    for(var i=0; i<arguments.length; i++) {
        a.push(arguments[i]);
    };
    return {
        list: a
    };
}

function string() {
    return LET(array(char_code()), String.fromCharCodes);
}
function char_code() {
    return {char_code: []};
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
function $float() {
    var a = [];
    for(var i=0; i<arguments.length; i++) {
        a.push(arguments[i]);
    };
    return {"float": a};
}

function even_number() {
    return LET(integer(),
        function(i) {
            return i * 2;
        }
    );
}
function odd_number() {
    return LET(even_number(),
        function(i) {
            return i*2 - 1;
        }
    );
}
function $boolean() {
    return oneof(true, false);
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
        },
        PROPS: function(hash) {
            var props = [];
            for(k in hash) {
                props.push(k);
            }
            return props;
        }
    };
})();

Proper.props = {
    oneof: function() {
        return FORALL(oneof(true, false),
            function(n) {
                return n === true || n === false;
            }
        )
    },
    even_number: function() {
        return FORALL(even_number(),
            function(i) {
                return i % 2 == 0;
            }
        );
    },
    pos_integer: function() {
        return FORALL(pos_integer(),
            function(i) {
                return i > 0
            }
        );
    },
    neg_integer: function() {
        return FORALL(neg_integer(),
            function(i) {
                return i < 0
            }
        );
    },
    non_neg_integer: function() {
        return FORALL(non_neg_integer(),
            function(i) {
                return i >= 0
            }
        );
    },
    integer: function() {
        return FORALL(integer(), integer(),
            function(i1, i2) {
                var min = Math.min(i1, i2);
                var max = Math.min(i1, i2);
                return FORALL(integer(min, max),
                    function(i) {
                        return i >= min && i <= max;
                    }
                );
            }
        );
    },
    float_1: function() {
        return FORALL($float(),
            function(f) {
                return typeof f == 'number';
            }
        );
    },
    float_2: function() {
        return FORALL($float(), $float(),
            function(f1, f2) {
                var min = Math.min(f1, f2);
                var max = Math.min(f1, f2);
                return FORALL($float(min, max),
                    function(f) {
                        return f >= min && f <= max;
                    }
                );
            }
        );
    },
    forall_forall: function() {
        var odd_or_even = function(b) {
            return b ? odd_number() : even_number();
        }
        // todo: write less contrived nested FORALL property
        return FORALL($boolean(),
            function(b) {
                return FORALL(odd_or_even(b),
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
            return LET(pos_integer(),
                function(i) {
                    return LET(array(i),
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
        return FORALL(my_nested_let(),
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
        return FORALL(array(integer()),
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
        var my_object_type = function(type) {
            return {
                greeting: "Hello World!",
                id: pos_integer(),
                listoftype: [type, type, type],
                type: type
            };
        };
        return FORALL(oneof(pos_integer(), $boolean()),
            function(type) {
                return FORALL(my_object_type(type),
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
        var my_list_type = function(type) {
            return [type, type, type, type];
        };
        return FORALL(oneof(pos_integer(), $boolean()),
            function(type) {
                return FORALL(my_list_type(type),
                    function(my_list) {
                        return typeof my_list[0] == typeof type
                            && typeof my_list[1] == typeof type
                            && typeof my_list[2] == typeof type
                            && typeof my_list[3] == typeof type;
                    }
                );
            }
        );
    },
    suchthat: function() {
        var suchthattype = function() {
            return SUCHTHAT(integer(),
                function(i) {
                    return i > 0;
                }
            );
        };
        return FORALL(suchthattype(),
            function(i) {
                return i > 0 && typeof i == 'number';
            }
         );
    },
    suchthatmaybe: function() {
        var suchthattype = function() {
            return SUCHTHATMAYBE(integer(),
                function(i) {
                    return i == "";
                }
            );
        };
        return FORALL(suchthattype(),
            function(i) {
                return typeof i == 'number';
            }
         );
    }
};
