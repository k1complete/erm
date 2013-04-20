Code.require_file "../test_helper.exs", __FILE__

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

end
