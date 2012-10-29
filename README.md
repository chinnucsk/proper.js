This is currently just a proof of concept and only tests a set of
contrived properties in priv/proper.js

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
