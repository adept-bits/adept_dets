defmodule Adept.Dets do
  @moduledoc """
  Documentation for `Adept.Dets`.
  """
  alias :dets, as: Dets

  @type t :: {__MODULE__, any}

  # --------------------------------------------------------
  # file open/close

  @spec open(path :: binary) :: {:ok, t()} | {:error, any}
  def open(path) when is_binary(path) do
    path_charlist = to_charlist(path)

    case Dets.open_file(path, file: path_charlist) do
      {:ok, _} -> {:ok, {__MODULE__, path}}
      err -> err
    end
  end

  @spec close(db :: t()) :: :ok
  def close({__MODULE__, name}) do
    Dets.close(name)
  end

  # --------------------------------------------------------
  # accessors

  @spec get(db :: t(), id :: any) :: any
  def get({__MODULE__, name}, id) when is_binary(id), do: do_get(name, id)

  def do_get(name, id) do
    case Dets.lookup(name, id) do
      [{^id, obj}] -> obj
      [] -> nil
    end
  end

  @spec get!(db :: t(), id :: any) :: any
  def get!({__MODULE__, name}, id) when is_binary(id), do: do_get!(name, id)

  def do_get!(name, id) do
    case Dets.lookup(name, id) do
      [{^id, obj}] -> obj
      err -> raise "Lookup Failed #{inspect(err)}"
    end
  end

  @spec fetch(db :: t(), id :: any) :: {:ok, any} | :error
  def fetch({__MODULE__, name}, id) when is_binary(id), do: do_fetch(name, id)

  defp do_fetch(name, id) do
    case Dets.lookup(name, id) do
      [{^id, obj}] -> {:ok, obj}
      _ -> :error
    end
  end

  @spec keys(db :: t()) :: list(any)
  def keys({__MODULE__, name}), do: do_keys(name, Dets.first(name), [])
  defp do_keys(_name, :"$end_of_table", acc), do: Enum.reverse(acc)
  defp do_keys(name, key, acc), do: do_keys(name, Dets.next(name, key), [key | acc])

  @spec list(db :: t()) :: list({any, any})
  def list({__MODULE__, name} = db) do
    keys(db) |> Enum.map(fn k -> {k, do_get(name, k)} end)
  end

  @spec load(db :: t()) :: map
  def load({__MODULE__, _} = db) do
    list(db) |> Enum.into(%{})
  end

  @spec member?(db :: t(), id :: any) :: boolean
  def member?({__MODULE__, name}, id), do: Dets.member(name, id)

  @spec reduce(db :: t(), default :: any, (any, any -> any)) :: any
  def reduce({__MODULE__, name}, default, func) when is_function(func, 2) do
    do_reduce(name, default, func)
  end

  defp do_reduce(name, default, func), do: Dets.foldr(func, default, name)

  @spec count(db :: t()) :: non_neg_integer
  def count({__MODULE__, name}) do
    do_reduce(name, 0, fn _, acc -> acc + 1 end)
  end

  # --------------------------------------------------------

  @spec put(db :: t(), id :: any, obj :: any) :: :ok
  def put({__MODULE__, name}, id, obj) do
    Dets.insert(name, {id, obj})
  end

  def put({__MODULE__, name}, objs) when is_list(objs) do
    Dets.insert(name, objs)
  end

  def put(db, %{} = objs) do
    put(db, Enum.into(objs, []))
  end

  @spec put_new(db :: t(), id :: any, obj :: any) :: :ok | :error
  def put_new({__MODULE__, name}, id, obj) do
    case Dets.insert_new(name, {id, obj}) do
      true -> :ok
      false -> :error
    end
  end

  def put_new({__MODULE__, name}, objs) when is_list(objs) do
    case Dets.insert_new(name, objs) do
      true -> :ok
      false -> :error
    end
  end

  def put_new(db, %{} = objs) do
    put_new(db, Enum.into(objs, []))
  end

  @spec delete(db :: t(), id :: any) :: :ok
  def delete({__MODULE__, name}, id), do: Dets.delete(name, id)

  # --------------------------------------------------------
  # search / match
  # uses erlang match syntax...

  @spec match(db :: t(), pattern :: any) :: [[any]] | {:error, any}
  def match({__MODULE__, name}, pattern) do
    Dets.match(name, pattern)
  end

  @spec match_delete(db :: t(), pattern :: any) :: :ok
  def match_delete({__MODULE__, name}, pattern) do
    Dets.match_delete(name, pattern)
    :ok
  end

  # --------------------------------------------------------

  @spec info(db :: t()) :: list()
  def info({__MODULE__, name}), do: Dets.info(name)

  @spec sync(db :: t()) :: :ok | {:error, reason :: any}
  def sync({__MODULE__, name}), do: Dets.sync(name)
end
