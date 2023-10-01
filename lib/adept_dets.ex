defmodule Adept.Dets do
  @moduledoc """
  Documentation for `Adept.Dets`.
  """
  alias :dets, as: Dets

  # import IEx


  #--------------------------------------------------------
  # file open/close

  def open( path ) when is_binary(path) do
    path_charlist = to_charlist( path )
    case Dets.open_file(path, file: path_charlist) do
      {:ok, _} -> {:ok, {__MODULE__, path}}
      err -> err
    end
  end

  def close( {__MODULE__, name} ) do
    Dets.close( name )
  end


  #--------------------------------------------------------
  # accessors

  def get( {__MODULE__, name}, id ) when is_binary(id), do: do_get(name, id)
  def do_get( name, id ) do
    case Dets.lookup(name, id) do
      [{^id, obj}] -> obj
      [] -> nil
    end
  end

  def get!( {__MODULE__, name}, id ) when is_binary(id), do: do_get!( name, id )
  def do_get!( name, id ) do
    case Dets.lookup(name, id) do
      [{^id, obj}] -> obj
      err -> raise "Lookup Failed #{inspect(err)}"
    end
  end

  def fetch( {__MODULE__, name}, id ) when is_binary(id), do: do_fetch(name, id)
  defp do_fetch(name, id) do
    case Dets.lookup(name, id) do
      [{^id, obj}] -> {:ok, obj}
      _ -> :error
    end
  end

  def keys( {__MODULE__, name} ), do: do_keys( name, Dets.first(name), [] )
  defp do_keys( _name, :"$end_of_table", acc ), do: Enum.reverse(acc)
  defp do_keys( name, key, acc ), do: do_keys( name, Dets.next(name, key), [key | acc] )

  def list( {__MODULE__, name} = db ) do
    keys( db ) |> Enum.map( fn(k) -> {k, do_get(name, k)} end)
  end

  def load( {__MODULE__, _} = db ) do
    list( db ) |> Enum.into(%{})
  end

  def member?( {__MODULE__, name}, id ), do: Dets.member(name, id)

  def reduce( {__MODULE__, name}, default, func ) when is_function(func, 2) do
    do_reduce(name, default, func)
  end
  defp do_reduce( name, default, func ), do: Dets.foldr(func, default, name)

  def count( {__MODULE__, name} ) do
    do_reduce( name, 0, fn(_, acc) -> acc + 1 end) 
  end


  #--------------------------------------------------------

  def put( {__MODULE__, name}, id, obj ) do
    Dets.insert(name, {id, obj})
  end
  def put( {__MODULE__, name}, objs ) when is_list(objs) do
    Dets.insert(name, objs)
  end
  def put( db, %{} = objs ) do
    put( db, Enum.into(objs, []) )
  end

  def put_new( {__MODULE__, name}, id, obj ) do
    case Dets.insert_new(name, {id, obj}) do
      true -> :ok
      false -> :error
    end
  end
  def put_new( {__MODULE__, name}, objs ) when is_list(objs) do
    case Dets.insert_new(name, objs) do
      true -> :ok
      false -> :error
    end
  end
  def put_new( db, %{} = objs ) do
    put_new( db, Enum.into(objs, []) )
  end

  def delete( {__MODULE__, name}, id ), do: Dets.delete( name, id )


  #--------------------------------------------------------
  # search / match
  # uses erlang match syntax...

  def match( {__MODULE__, name}, pattern ) do
    Dets.match(name, pattern)
  end

  def match_delete( {__MODULE__, name}, pattern ) do
    Dets.match_delete(name, pattern)
    :ok
  end

  #--------------------------------------------------------

  def info( {__MODULE__, name} ), do: Dets.info(name)
  def sync( {__MODULE__, name} ), do: Dets.sync(name)

end
