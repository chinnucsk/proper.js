
// http://stackoverflow.com/a/3955096/1562641
Array.prototype.remove = function() {
    var what, a = arguments, L = a.length, ax;
    while(L && this.length) {
        what = a[--L];
        while((ax = this.indexOf(what)) != -1) {
            this.splice(ax, 1);
        }
    }
    return this;
}

Array.seq = function(from, to) {
    var a = [];
    while(from <= to) {
        a.push(from++);
    }
    return a;
}

function min_max_pos_integer_pair() {
    return LET([pos_integer(), pos_integer()],
        function(n1, n2) {
            var min = Math.min(n1, n2);
            var max = Math.max(n1, n2);
            return {min: min, max: max};
        }
    );
};

Array.props = {
    min_max_pos_integer_pair: function() {
        return FORALL([min_max_pos_integer_pair()],
            function(pair) {
                return pair.min <= pair.max;
            }
        );
    },
    remove: function() {
        return FORALL([min_max_pos_integer_pair()],
            function(pair) {
                var n = pair.min;
                var size = pair.max;
                var seq = Array.seq(1, size);
                var length = seq.length;
                seq.remove(n);
                return seq.indexOf(n) == -1 && seq.length == length - 1;
            }
        )
    }
}
