Code.require_file "../test_helper.exs", __FILE__
defmodule MM do
  Record.defmacros :"p_m", [a: 1, b: 1, c: 1], __ENV__, :"P.u"
  use ExUnit.Case
  test "test" do
    assert(p_m() == {:"P.u",1, 1, 1})
    assert(p_m(a: 2) = {:"P.u", 2, 1, 1})
  end
end
defmodule ErmBadTest do
  use ExUnit.Case
  use Erm
  :code.del_path(:testapp)
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
    assert_raise(File.Error,
		   fn() ->
		       defmodule MFileError do
			 Erm.defrecords_from_hrl("test/include_hrl.hrl")
		       end
		   end)
  end
  test "dynamic record reference" do
    Erm.defrecord(:r1, [f1: 1, f2: 2, f3: 3])
    opt = [f1: 2, f3: 4]
    m = Erm.record(:r1)
    assert({:r1, 2, 2, 4} == Erm.record(:r1, m, opt))
    assert(Erm.record(:r1, [f1: 2, f3: 4]) == Erm.record(:r1, m, opt))
    assert_raise(ArgumentError,
		   fn() ->
		       defmodule Dmodule do
			 def f() do
			   Erm.record(:r1, opt) == Erm.record(:r1, m, opt)
			 end
		       end
		   end)
  end
end
if nil do
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
end