var helloworld = function() {
    return "Hello World From proper.js!\n";
};

var fun2 = function(f) {
    return f();
};

function FORALL(names, props) {
    return {
        FORALL: [names, props]
    };
}

var FUNS = (function() {
    return {

    };
})();

function FUN(fun) {
    return {fun: {fun: fun}};
};

function pos_integer() {
    return {pos_integer: []};
}
function neg_integer() {
    return {neg_integer: []};
}
function non_neg_integer() {
    return {non_neg_integer: []};
}

function PROPS(hash) {
    var props = [];
    for(k in hash) {
        props.push(k);
    }
    return props;
};

function func() {
    return function() {return 2};
};

var Proper = {};

Proper.props = {
    // contrived extra pos_integer property even though it itself is a
    // propery
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
