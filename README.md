# Erm
Erlang like record manipulator

- no overhead convert to erlang record tuple.
- bulk convert *.hrl (and automatic resolving library path)
- search path management and available wildcard(use Erm.addpath("***"))
- available left hand for pattern matching(use Erm.recordl(:foo))

## usage

    defmodule M1
      use Erm
      Erm.defrecord(:foo, [field1: :undefined, field2: unfield])
      def method() do
        assert(Erm.record(:foo) == {:foo, :undefiend, :undefined})
        m = Erm.record(:foo, [field1: 1]) 
        assert(m == {:foo, 1, :undefined})
        assert(Erm.record(:foo, m, [field2: 2]) == {:foo, 1, 2})
        Erm.recordl(:foo) = m
        ## --> {:foo, _, _} = m
        Erm.recordl(:foo, [field2: 3]) = m 
        ## --> {:foo, _, 3} = m
        Erm.record_info(:fields, :foo)
        ## --> [:field1, :field2]
        Erm.record_info(:size, :foo)
        ## --> 3   ## length([:foo, :field1, :field2])
      end
    end
    defmodule M2
      use Erm
      Erm.addpath("path/to/**/library/modules/include")
      Erm.defrecord_from_hrl("path/to/**/*hrl")
      ## bulk record definition
    end
    defmodule M3
      use Erm
      Erm.defrecord_from_lib("edoc/include/edoc_doclet.hrl")
      ## bulk record definition
    end
