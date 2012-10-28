Extension for PropEr for Javascript Property Testing

    function prop_delete() {
        FORALL([integer(),list(integer())],
            function(key, list) {
                -1 == list.indexOf(key, delete(X,L));
            }
        );
    }
