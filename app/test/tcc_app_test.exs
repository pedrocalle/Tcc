defmodule TccAppTest do
  use ExUnit.Case
  doctest TccApp

  test "greets the world" do
    assert TccApp.hello() == :world
  end
end
