This is currently just a proof of concept and only tests a set of
contrived properties in priv/proper.js

    make

Then you can try running the properjs command in the properjs repository:

    ./properjs PATH/TO/file.js Object
    ./properjs PATH/TO/file.js Object PATH/TO/include.js 0 PATH/TO/otherfile.js OtherObject

    # where PATH/TO/file.js is a source file for your code
    #       Object.props will be how properjs discovers its properties
    #   and 0 denotes a source file without any properties defined

By default running properjs with no arguments runs the Proper.prop
properties.

To run the string tests in priv/string.js run:

    ./properjs priv/string.js String

```javascript
var Proper = {};

Proper.props = {
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
```
