-record('P_basic', {foo}).
-record('P_basic2', {basic = #'P_basic'{foo=1}}).
-record(amqp_msg2, {props = #'P_basic2'{}, payoad = <<>>}).
-record(node_self, {node = node()}).
-record(node_fun, {node = fun node/0 }).
-record(list_reverse_fun, {node = fun lists:reverse/1 }).

