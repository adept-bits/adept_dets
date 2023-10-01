defmodule AdeptDetsTest do
  use ExUnit.Case, async: false
  doctest Adept.Dets

  alias Adept.Dets

  @path_temp "test/dbs/temp.dets"
  @path_existing "test/dbs/test.dets"

  test "create and open a new dets file" do
    File.rm(@path_temp)
    refute File.exists? @path_temp
    {:ok, db} = Dets.open( @path_temp )
    assert File.exists? @path_temp
    :ok = Dets.close( db )
  end

  test "opens existing db" do
    {:ok, db} = Dets.open( @path_existing )
    assert Dets.count(db) == 2
    assert Dets.get(db, "abc") == 123
    assert Dets.get(db, "def") == 456
    :ok = Dets.close( db )
  end

  test "count calculates the number of objects in the db" do
    {:ok, db} = Dets.open( @path_existing )
    assert Dets.count(db) == 2
    :ok = Dets.close( db )
  end

  test "get returns data or nil if missing" do
    {:ok, db} = Dets.open( @path_existing )
    assert Dets.count(db) == 2
    assert Dets.get(db, "abc") == 123
    assert Dets.get(db, "efg") == nil
    :ok = Dets.close( db )
  end

  test "get! returns data or raises if missing" do
    {:ok, db} = Dets.open( @path_existing )
    assert Dets.count(db) == 2
    assert Dets.get!(db, "abc") == 123
    assert_raise RuntimeError, fn ->
      Dets.get!(db, "efg")
    end
    :ok = Dets.close( db )
  end

  test "fetch works similarly to Map.fetch" do
    {:ok, db} = Dets.open( @path_existing )
    assert Dets.count(db) == 2
    assert Dets.fetch(db, "abc") == {:ok, 123}
    assert Dets.fetch(db, "efg") == :error
    :ok = Dets.close( db )
  end

  test "keys returns a list of the keys in the db" do
    {:ok, db} = Dets.open( @path_existing )
    assert Dets.count(db) == 2
    assert Dets.keys(db) |> Enum.sort() == ["abc", "def"]
    :ok = Dets.close( db )
  end

  test "list returns a list the contents of the db" do
    {:ok, db} = Dets.open( @path_existing )
    assert Dets.count(db) == 2
    assert Dets.list(db) |> Enum.sort() == [{"abc", 123}, {"def", 456}]
    :ok = Dets.close( db )
  end

  test "map returns a map the contents of the db" do
    {:ok, db} = Dets.open( @path_existing )
    assert Dets.count(db) == 2
    assert Dets.load(db) == %{"abc" => 123, "def" => 456}
    :ok = Dets.close( db )
  end

  test "member? returns true or false depending on if the key is in the db" do
    {:ok, db} = Dets.open( @path_existing )
    assert Dets.count(db) == 2
    assert Dets.member?(db, "abc")
    assert Dets.member?(db, "def")
    refute Dets.member?(db, "ghi")
    :ok = Dets.close( db )
  end

  test "reduce iterates over the db, building an accumulator" do
    {:ok, db} = Dets.open( @path_existing )
    assert Dets.reduce(db, 0, fn(_k, acc) -> acc + 1 end) == 2
    :ok = Dets.close( db )
  end

  test "put adds and overwrites items in the db" do
    File.rm(@path_temp)
    {:ok, db} = Dets.open( @path_temp )

    assert Dets.count(db) == 0
    :ok = Dets.put( db, "abc", 321 )
    assert Dets.get(db, "abc") == 321
    assert Dets.count(db) == 1

    # overwrite
    :ok = Dets.put( db, "abc", 123 )
    assert Dets.get(db, "abc") == 123
    assert Dets.count(db) == 1

    :ok = Dets.close( db )
  end

  test "put_new only adds new items in the db" do
    File.rm(@path_temp)
    {:ok, db} = Dets.open( @path_temp )

    assert Dets.count(db) == 0
    :ok = Dets.put_new( db, "abc", 321 )
    assert Dets.get(db, "abc") == 321
    assert Dets.count(db) == 1

    # overwrite
    :error = Dets.put_new( db, "abc", 123 )
    assert Dets.get(db, "abc") == 321
    assert Dets.count(db) == 1

    :ok = Dets.close( db )
  end

  test "delete removes items from the db" do
    File.rm(@path_temp)
    {:ok, db} = Dets.open( @path_temp )

    assert Dets.count(db) == 0
    :ok = Dets.put_new( db, "abc", 321 )
    assert Dets.get(db, "abc") == 321
    assert Dets.count(db) == 1

    # delete it
    :ok = Dets.delete( db, "abc" )
    assert Dets.get(db, "abc") == nil
    assert Dets.count(db) == 0

    :ok = Dets.close( db )
  end

  test "match finds objects via erlang match patterns" do
    File.rm(@path_temp)
    {:ok, db} = Dets.open( @path_temp )

    assert Dets.count(db) == 0
    :ok = Dets.put( db, "abc", 123 )
    :ok = Dets.put( db, "def", 456 )
    assert Dets.count(db) == 2

    assert Dets.match(db, :"$1") == [[{"abc", 123}], [{"def", 456}]]
    assert Dets.match(db, {:"$1", 456}) == [["def"]]
    # assert Dets.match(db, {:"_", :"$1"}) == [[{"abc", 123}], [{"def", 456}]]

    :ok = Dets.close( db )
  end

  test "match_delete removes objects via erlang match patterns" do
    File.rm(@path_temp)
    {:ok, db} = Dets.open( @path_temp )

    assert Dets.count(db) == 0
    :ok = Dets.put( db, "abc", 123 )
    :ok = Dets.put( db, "def", 456 )
    assert Dets.get(db, "abc") == 123
    assert Dets.get(db, "def") == 456
    assert Dets.count(db) == 2

    :ok = Dets.match_delete(db, {:"$1", 456})
    assert Dets.count(db) == 1
    assert Dets.get(db, "abc") == 123
    assert Dets.get(db, "def") == nil

    :ok = Dets.close( db )
  end

  test "can use multiple dbs simultaneously" do
    File.rm(@path_temp)
    {:ok, dbt} = Dets.open( @path_temp )
    {:ok, dbe} = Dets.open( @path_existing )

    assert Dets.count(dbt) == 0
    assert Dets.count(dbe) == 2

    :ok = Dets.close( dbt )
    :ok = Dets.close( dbe )
  end

end