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

String.props = {
    string_fromCharCode: function() {
        return FORALL(list(char_code()),
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
    string: function() {
        return FORALL(string(),
            function(s) {
                return typeof s == 'string';
            }
        );
    },
    string_reverse: function() {
        return FORALL(string(),
            function(s) {
                return s.reverse().reverse() == s;
            }
        );
    }
};
