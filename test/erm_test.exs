Code.require_file "../test_helper.exs", __FILE__
defmodule ErmBadTest do
  use ExUnit.Case
  use Erm
  test "Erm.defmacro" do
    assert_raise(KeyError, 
		   fn() ->
		       defmodule MkeyError do
			 Erm.defrecord(:a, [a1: 1, b1: 2])
			 Erm.record(:a, [c1: 2])
		       end
		   end)
    assert_raise(ArgumentError,
		   fn() -> 
		       defmodule MargError do
			 Erm.defrecord(:a, [a1: 1, a1: 2])
		       end
		   end)
  end
end
defmodule ErmTest do
  use ExUnit.Case
  use Erm
  test "Erm.defmacro" do
    Erm.defrecord(:a, [a1: 1, b1: 2])
    Erm.defrecord(:b, [a1: 1, b1: Erm.record(:a)])
    Erm.defrecord(:c, [a1: 1, b1: 2])
    assert(Erm.record(:a) == {:a, 1, 2})
    assert(Erm.record(:b) == {:b, 1, {:a, 1, 2}})
    assert(Erm.record(:c) == {:c, 1, 2})
  end
  test "record_fields test" do
    Erm.defrecord(:testrecord, [field1: nil, field2: 1, field3: []])
    assert(Erm.record_info(:fields, :testrecord) ==  [:field1, :field2, :field3])
  end
  test "record_size test" do
    Erm.defrecord(:testrecord, [field1: nil, field2: 1, field4: []])
    assert(Erm.record_info(:size, :testrecord) ==  4)
  end
  test "record match test" do
    Erm.defrecord(:testrecord, [field1: nil, field2: 1, field4: []])
    assert(Erm.record(:testrecord) ==  {:testrecord, nil, 1, []})
    Erm.record(:testrecord, [field2: x]) = Erm.record(:testrecord, [field2: 30])
    assert(x == 30)
  end

  test "record_from_hrl_fun" do
    Erm.defrecords_from_hrl("test/amqp_c.hrl")
    Erm.recordl(:list_reverse_fun, [node: f]) = Erm.record(:list_reverse_fun)
    assert(f.([1,2,3]) == [3,2,1])
    Erm.recordl(:node_fun, [node: f]) = Erm.record(:node_fun)
    assert(f.() == node())
  end
  test "record_from_hrl_call" do
    Erm.defrecords_from_hrl("test/amqp_c.hrl")
    Erm.recordl(:node_self, [node: f]) = Erm.record(:node_self)
    assert(f == node())
  end
  Erm.addpath("test/deps/**/include")
  test "record_has_no_field" do
    Erm.defrecord(:nomember, [])
    m = Erm.record(:nomember)
    assert(m == {:nomember})
  end

  Erm.addpath("test/deps/**/include")
  test "record_from_hrl_addpath" do
    Erm.defrecords_from_hrl("test/include_hrl.hrl")
    m = Erm.record(:"include_hrl2")
    assert(m == {:include_hrl2, {:test_record, :undefined, :undefined}})
    assert(Erm.record(:"include_hrl1") == {:include_hrl1, :undefined, :undefined})
    assert(Erm.record(:"include_hrl3") == {:include_hrl3, :undefined, :undefined, :undefined})
  end
  
end
