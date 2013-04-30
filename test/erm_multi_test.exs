Code.require_file "../test_helper.exs", __FILE__

defmodule Module1 do
  use ExUnit.Case

  test "Multi.defmacro" do
    defmodule M1 do
      use Erm
      Erm.defrecord(:a, [a1: 1, a2: 2])
      Erm.defrecord(:b, [a1: 1, a2: 2])
      def mm() do
	Erm.record(:a, [a1: 2])
      end
      assert(__MODULE__ == Module1.M1)
      m = list_to_atom(pid_to_list(self))
      assert(:ets.info(m)[:size] == 2)
      Enum.each :ets.tab2list(m),
		       fn(t) ->
			   :io.format("~p~n", [t])
		       end
    end
    defmodule M2 do
      use Erm
      m = list_to_atom(pid_to_list(self))
      assert(:ets.info(m)[:size] == 1)
      Enum.each :ets.tab2list(m),
		       fn(t) ->
			   :io.format("~p~n", [t])
		       end
      Erm.defrecord(:a, [a1: 1, a2: 2, a3: 3])
      def m() do
	Erm.record(:a, [a1: 2])
      end
    end

    assert_raise(MatchError,
		   fn() ->
		       defmodule M3 do
			 use Erm
			 Erm.record(:b, [a2: 1])
		       end
		   end)
    end
end