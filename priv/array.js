
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

Array.props = {
    remove: function() {
        return FORALL([pos_integer(), pos_integer()],
            function(n1, n2) {
                var size = Math.max(n1, n2);
                var n = Math.min(n1, n2);
                var seq = Array.seq(1, size);
                var length = seq.length;
                seq.remove(n);
                return seq.indexOf(n) == -1 && seq.length == length - 1;
            }
        )
    }
}
