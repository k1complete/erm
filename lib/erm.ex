defmodule Erm do
  @moduledoc "Erlang like Record Manipulater module"
  defmacro __using__(_opts) do
    r = :ets.info(:erec_records)
    unless (r == :undefined) do
      :error_logger.info_msg("delete table ~p", [r])
      delete()
    end
    init()
  end
  @doc """
  add erlang record definition search path available * and ** 
  usage: use into defmodule block  ... 
  defmodule foo do
    use Erm
    def f1() do
      Erm.record(:rec1) ....
      ...
    end
  end
  """
  def addpath(path) do
    m = Mix.project
    case Keyword.keys(m[:deps]) do
      [k] -> 
	dp = m[:deps_path]
	:io.format("Erm: include paths ~p~n", [path])
	pj = Path.wildcard(Path.join([dp, atom_to_binary(k), path]))
      _ -> 
	pj = Path.wildcard(path)
    end
    filepaths = Enum.map(pj, fn(x) -> 
				 binary_to_list(Path.dirname(x)) 
			     end)
    :io.format("Erm: add include paths ~p~n", [filepaths])
    Enum.each(filepaths, fn(x) -> :code.add_patha(x) end)
  end
  @doc "open named ets table, :erec_records"
  def init() do
    :ets.new(:erec_records, [:named_table, :public])
  end
  @doc "delete ets table :erec_records"
  def delete() do
    :ets.delete(:erec_records)
  end
  defp getdefs(rs, name) do
#    :io.format("getdefs ~s~n", [name])
    try do
      [{^name, _recdef}]  = :ets.lookup(rs, name)
    rescue 
      MatchError ->
	raise MatchError, [actual: name]
    end
  end
  defp get_record_fields(rs, name) do
    [{^name, recdef}] = getdefs(rs, name)
    Keyword.keys(recdef)
  end
  defp erec(rs, name, keylist) do
    [{^name, recdef}]  = getdefs(rs, name)
    case recdef do
      [] -> 
	[name]
      _ ->
	fields = Erm.Util.merge(recdef, keylist)
	ret = [name | Keyword.values(fields)]
	ret
    end
  end
  defp conv(rs, {:record, _n, name, fields}) do
    key_values = reduce_fields(rs, fields)
    {:"{}", [], erec(rs, name, key_values)}
  end
  defp conv(_rs, {:integer, _n, v}) do
    v
  end
  defp conv(rs, {:bin, _n, v}) do
    r = lc {:bin_element, _, tv, _d1, _d2} inlist v, do: conv(rs, tv)
    list_to_binary(r)
  end
  defp conv(_rs, {:nil, _n}) do
    []
  end
  defp conv(_rs, {:atom, _n, a}) do
    a
  end
  defp conv(_rs, {:function, f, a}) do
    [:erlang, f, a]
  end
  defp conv(_rs, {:function, m, f, a}) do
    [conv(_rs, m), conv(_rs, f), conv(_rs, a)]
  end
  defp conv(_rs, {:fun, _n, fp}) do
    [module, f, arity] = conv(_rs, fp)
    {:function, [import: Kernel], [module, f, arity]}
  end
  defp conv(_rs, {:cons, _n,a,b}) do
    [conv(_rs, a) | conv(_rs, b)]
  end
  defp conv(rs, {:call, _n, mf,args}) do
    {m, f} = case mf do
	       {:atom, _, v} -> {:erlang, v}
	       {:remote, _, mm, mf} -> {conv(rs, mm), conv(rs, mf)}
	     end
    apply(m, f, args)
  end
  defp conv(_rs, {_type, _n, v}) do
    v
  end
  defp conv(_rs, {:eof, _n}) do
    nil
  end
  defp reduce_fields(rs, defs) do
    m = Enum.map(defs, function do
			 ({:record_field, _n, name_t}) ->
			   {:atom, _m, name} = name_t
			   {name, :undefined}
			 ({:record_field, _n, name_t, value_t}) ->
			   {:atom, _m, name} = name_t
			   {name, conv(rs, value_t)}
		       end)
    m
  end
  def record_definition(rs, rdef) do
    case :ets.info(rs) do
      :undefined -> init()
      _ -> true
    end
    {name, fields} = rdef
    c = List.foldl(fields, [], fn({k, v}, a) -> 
				   Keyword.put(a, k, v) 
			       end)
    case (fields -- c) do
      [] -> true
      m ->
	msg = list_to_binary(:io_lib.format("duplicate field names ~p in record ~s~n", [m, name]))
	raise ArgumentError, message: msg
    end
    true = :ets.insert(rs, rdef)
  end
  @doc "record definition from file"
  @spec defrecords_from_file(String, String, Keyword.t) :: nil | File.Error
  def defrecords_from_file(file, paths, opt //[]) do
    pathlist = Enum.map(paths, binary_to_list(&1))
    ## Ifile, Path, Predef
    try do
      [filepath | _ ] = Path.wildcard(file)
      {:ok, r} = :epp.parse_file binary_to_list(filepath), pathlist, opt
#      :io.format("parsed: ~p~n", [r])
      Enum.filter_map(r, function do
			 ({:attribute, _n, :record, _d}) ->
			   true
			 ({:error, {_n, :epp, {path}}}) ->
			   raise File.Error, reason: :enoent, 
					action: " maybe not search path", 
					path: path
			 (_) -> 
			   false
		       end,
		      function do
			({_a, _n, :record, {name, defs}}) ->
			  m = reduce_fields(:erec_records, defs)
			  record_definition(:erec_records, {name, m})
		      end)
    rescue
      MatchError -> 
	raise File.Error, reason: :enoent, action: "wildcard expand", 
		     path: file
    end
    nil
  end
  @doc "all record defining from *.hrl"
  @spec defrecords_from_hrl(String) :: nil
  defmacro defrecords_from_hrl(file) do
    defrecords_from_file(file, [], [])
  end
  def defrecords_from_hrl(file, paths, opt //[]) do
    defrecords_from_file(file, paths, opt)
  end
  defmacro defrecord(name, datas) do
    record_definition(:erec_records, {name, datas})
  end
  defmacro record(name, keylist // []) do
    ret = erec(:erec_records, name, keylist)
    {:"{}", [], ret}
  end
  defmacro record(name, tuple, keylist) do
    keys = get_record_fields(:erec_records, name)
    opts = Keyword.keys(keylist)
    Erm.Util.check(keys, opts)
    quote do
      [_ | fields] = tuple_to_list(unquote(tuple))
      e = Enum.zip(unquote(keys), fields)
      merged_kv = Keyword.merge(e, unquote(keylist), 
				  fn(k, _v1, v2) -> v2 end)
      list_to_tuple [unquote(name) | Keyword.values(merged_kv)]
    end
  end
  defmacro recordl(name, keylist // []) do
    [{^name, recdef}]  = getdefs(:erec_records, name)
    recdef = Enum.map(recdef, fn({k, _v}) -> {k, {:_, [], Elixir}} end)
    fields = Erm.Util.merge(recdef, keylist)
    ret = [name | Keyword.values(fields)]
    {:"{}", [], ret}
  end
  defmacro record_info(:fields, name) when is_atom(name) do
    get_record_fields(:erec_records, name)
  end
  defmacro record_info(:size, name) when is_atom(name) do
    length(get_record_fields(:erec_records, name)) + 1
  end
end
