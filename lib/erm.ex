defmodule Erm do
  @moduledoc "Erlang like Record Manipulater module"
  defp pid do
    list_to_atom(pid_to_list(self))
  end
  defmacro __using__(_opts) do
    r = :ets.info(pid())
    unless (r == :undefined) do
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
  @spec addpath(path :: binary) :: nil
  def addpath(path) do
    m = Mix.project
    case Keyword.keys(m[:deps]) do
      [k] -> 
	dp = m[:deps_path]
	:error_logger.info_msg("Erm: include paths ~p~n", [path])
	pj = Path.wildcard(Path.join([dp, atom_to_binary(k), path]))
      _ -> 
	pj = Path.wildcard(path)
    end
    filepaths = Enum.map(pj, fn(x) -> 
				                         binary_to_list(Path.dirname(x)) 
			                       end)
    :error_logger.info_msg("Erm: add include paths ~p~n", [filepaths])
    Enum.each(filepaths, fn(x) -> :code.add_patha(x) end)
  end
  @doc "open named ets table"
  def init() do
    :ets.new(pid(), [:named_table])
  end
  @doc "delete ets table"
  def delete() do
    :ets.delete(pid())
  end
  defp getdefs(rs, name) do
    try do
      [{^name, _recdef}]  = :ets.lookup(rs, name)
    rescue 
      MatchError ->
	raise MatchError, [actual: name]
    end
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
  defp conv(_rs, {:integer, _n, v}), do: v
  defp conv(rs, {:bin, _n, v}) do
    r = lc {:bin_element, _, tv, _d1, _d2} inlist v, do: conv(rs, tv)
    list_to_binary(r)
  end
  defp conv(_rs, {:nil, _n}), do: []
  defp conv(_rs, {:atom, _n, a}), do: a
  defp conv(_rs, {:function, f, a}), do: [:erlang, f, a]
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
  defp conv(_rs, {_type, _n, v}), do: v
  defp conv(_rs, {:eof, _n}), do: nil

  defp reduce_fields(rs, defs) do
    m = Enum.map(defs, 
                   fn
			               ({:record_field, _n, name_t}) ->
			                 {:atom, _m, name} = name_t
			                 {name, :undefined}
			               ({:record_field, _n, name_t, value_t}) ->
			                 {:atom, _m, name} = name_t
			                 {name, conv(rs, value_t)}
		               end)
    m
  end
  defp record_definition(rs, rdef) do
    case :ets.info(rs) do
      :undefined -> init()
      _ -> true
    end
    {name, fields} = rdef
    c = List.foldl(fields, [], 
                     fn({k, v}, a) -> 
				                 Keyword.put(a, k, v) 
			               end)
    case (fields -- c) do
      [] -> 
        true
      m ->
	      msg = String.from_char_list!(:io_lib.format("duplicate field names ~p in record ~s~n", [m, name]))
	      raise ArgumentError, message: msg
    end
    true = :ets.insert(rs, rdef)
    m = quote do
      defrecord(unquote(name),unquote(fields), [])
    end
    #IO.puts Macro.to_string(m)
    m
  end
  @doc "record definition from file"
  @spec defrecords_from_file(String, String, Keyword.t) :: nil | File.Error
  def defrecords_from_file(file, paths, opt //[]) do
    pathlist = Enum.map(paths, binary_to_list(&1))
    ## Ifile, Path, Predef
   try do
      [filepath | _ ] = Path.wildcard(file)
      {:ok, fp} = String.to_char_list(filepath)
      {:ok, r} = :epp.parse_file fp, pathlist, opt
      Enum.filter_map(r, fn
			                     ({:attribute, _n, :record, _d}) ->
			                       true
			                     ({:error, {_n, :epp, {path}}}) ->
			                       raise File.Error, 
                                          reason: :enoent, 
					                                  action: " maybe not search path", 
					                                    path: path
			                     (_) -> 
			                       false
		                    end,
		                    fn ({_a, _n, :record, {name, defs}}) ->
			                       m = reduce_fields(pid(), defs)
			                       record_definition(pid(), {name, m})
		                    end)
      rescue
        MatchError -> 
	      raise File.Error, reason: :enoent, action: "wildcard expand", 
		                 path: file
    end
  end
  @doc "all record defining from *.hrl"
  @spec defrecords_from_hrl(String) :: nil
  defmacro defrecords_from_hrl(file) do
    defrecords_from_file(file, [], [])
  end
  @doc """
  all record defining from 'app/include/*.hrl'

  app is OTP application name without version

      Erm.defrecords_from_lib("edoc/include/edoc_doclet.hrl")
  """
  @spec defrecords_from_lib(file :: String) :: nil
  defmacro defrecords_from_lib(file) do
    [libname | rest] = Path.split(file)
    case :code.lib_dir(binary_to_atom(libname)) do
      {:error, :bad_name} ->
	      raise ArgumentError, message: "Bad name #{libname}"
      m when(is_list(m)) -> 
	      r = [String.from_char_list!(m) | rest]
	      defrecords_from_file(Path.join(r), [], [])
    end
  end
end
