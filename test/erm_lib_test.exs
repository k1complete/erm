Code.require_file "../test_helper.exs", __FILE__

defmodule ErmLibTest do
  use ExUnit.Case
  test "defrecords_from_lib" do
    defmodule M1 do
      use Erm
      Erm.defrecords_from_lib("edoc/include/edoc_doclet.hrl")
      def mes1() do
	      r = Erm.record(:context)
	      r
      end
    end
    assert(elem(M1.mes1, 0) == :context)
  end
  test "defrecords_from_lib_abort" do
    assert_raise(ArgumentError,
		   fn() ->
		       defmodule M2 do
			       use Erm
			       Erm.defrecords_from_lib("edoc_no_module/include/edoc_doclet.hrl")
			       def mes1() do
			         r = Erm.record(:context)
			         r
			       end
			       assert(elem(M2.mes1, 0) == :context)
		       end
		   end)
  end
end

