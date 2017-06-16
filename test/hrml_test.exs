defmodule HrmlTest do
  use ExUnit.Case
  doctest Hrml

  test "it parses the file correctly" do
    input = """
    6 3
    <tag1 value = "HelloWorld" foo = "bar">
    <tag2 name = "Name1">
    </tag2>
    </tag1>
    <tag3 foo = "bar">
    </tag3>
    tag1.tag2~name
    tag1~name
    tag1~value
    """

    output = """
    Name1
    Not Found!
    HelloWorld
    """

    assert Hrml.parse(input) == output
  end
end
