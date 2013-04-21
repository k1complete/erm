defmodule Erm.Util do
  def check(a1, a2) do
    Enum.all?(a2, fn(y) -> if (Enum.find(a1, fn(x) -> x == y end)) do
			     true
			   else
			     raise KeyError, key: y
			   end end)
  end
  def merge(plist, opt) do
    case plist do
      [] -> 
	case opt do
	  [] -> []
	  _ -> raise MatchError, key: opt
	end
      _ ->
	check(Keyword.keys(plist), Keyword.keys(opt))
	r = Keyword.merge(plist, opt, fn(_k, _v1, v2) -> v2 end)
	r
    end
  end
end
