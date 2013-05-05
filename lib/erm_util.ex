defmodule Erm.Util do
  @doc """
  unless list a1 == list a2, raise KeyError
  """
  def assert_equal(a1, a2) when is_list(a1) and is_list(a2) do
    Enum.all?(a2, fn(y) -> if (Enum.find(a1, fn(x) -> x == y end)) do
			     true
			   else
			     raise KeyError, key: y
			   end end)
  end
  @doc """
  merge keywordlist by kept keyword order.
  """
  def merge(plist, opt) do
    case plist do
      [] -> 
	case opt do
	  [] -> []
	  _ -> raise MatchError, key: opt
	end
      _ ->
	assert_equal(Keyword.keys(plist), Keyword.keys(opt))
	r = Keyword.merge(plist, opt, fn(_k, _v1, v2) -> v2 end)
	r
    end
  end
end
