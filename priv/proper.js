var log = function(s) {
    ejsLog("/tmp/erlang_js.txt", s);
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

var FUNS = (function() {
    return {

    };
})();

function reverse(s) {
    return s.reverse();
}

function FUN(fun) {
    return {fun: {fun: fun}};
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
    var l = [];
    for(var k in arguments) {
        l.push(arguments[k]);
    };
    return {integer: l};
}

function PROPS(hash) {
    var props = [];
    for(k in hash) {
        props.push(k);
    }
    return props;
}

function func() {
    return function() {return 2};
}

function even_number() {
    return LET([integer()],
        function(i) {
            return i * 2;
        }
    );
}

String.prototype.reverse = function() {
    return this.split("").reverse().join("");
};
String.fromCharCodes = function(a) {
    var s = "";
    for(var i=0; i<a.length; i++) {
        s += String.fromCharCode(a[i]);
    }
    return s;
};
String.prototype.toCharCodes = function() {
    var a = [];
    for(var i=0; i<this.length; i++) {
        a.push(this.charCodeAt(i));
    }
    return a;
};

var Proper = {};

Proper.props = {
    string_fromCharCode: function() {
        return FORALL([string()],
            function(charlist) {
                var s = String.fromCharCodes(charlist);
                if(typeof s != 'string') {
                    return false;
                }
                var converted = s.toCharCodes();
                for(var i=0; i<charlist.length; i++) {
                    if(charlist[i] != converted[i]) {
                        return false;
                    }
                }
                return charlist.length == converted.length;
            }
        );
    },
    string_reverse: function() {
        // todo: fix failing on [[0,1,1,0]]
        return FORALL([string()],
            function(charlist) {
                var s = String.fromCharCodes(charlist);
                var reversed = s.reverse();
                var half = s.length / 2;
                var left = s.substring(0, Math.floor(half));
                var right = s.substring(Math.ceil(half));
                var symetric = left == right;
                return (symetric && reversed == s) || (reversed != s && reversed.reverse() == s);
            }
        );
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
