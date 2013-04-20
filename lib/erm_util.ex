defmodule Erm.Util do
  def check(a1, a2) do
    Enum.all?(a2, fn(y) -> if (Enum.find(a1, fn(x) -> x == y end)) do
			     true
			   else
			     raise KeyError, key: y
			   end end)
  end
  def merge(plist, opt) do
    check(Keyword.keys(plist), Keyword.keys(opt))
    Keyword.merge(plist, opt, fn(_k, _v1, v2) -> v2 end)
  end
end
