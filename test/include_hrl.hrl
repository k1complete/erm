-include_lib("testapp/include/testrecord.hrl").
-record(include_hrl1, {member, m2}).
-record(include_hrl3, {a, b, c}).
-record(include_hrl2, {member=#test_record{}}).
