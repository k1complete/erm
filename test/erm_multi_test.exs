Code.require_file "../test_helper.exs", __FILE__

defmodule Module1 do
  use ExUnit.Case

  test "Multi.defmacro" do
    
    defrecord(:"b", [a1: 1, a2: 2, a3: 3, a4: 4])
    defmodule M2 do
      use Erm
      defrecord(:a, [a1: 1, a2: 2, a3: 3, a4: :"b"[]])
      def m() do
#	      r = :"a"[a1: 2]
        r4 = :"a"[]
        assert(elem(r4, 0) == :"a")
        assert(r4 == :"a"[])
#        IO.puts "#{inspect r4, raw: true}"
      end
    end
    M2.m()
    assert_raise(CompileError,
		   fn() ->
		       defmodule M3 do
             defrecord(:am1, [a1: 1, a2: 2, a3: 3])
             defrecord(:am2, [a1: 1, a2: 2, a3: 3, a4: :"am1"[]])
             def m() do
               :am2[]
             end
		       end
           M3.m() 
		   end)
    end
end