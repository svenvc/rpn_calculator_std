defmodule RPNCalculator.RPNCalculatorTest do
  use ExUnit.Case

  alias RPNCalculator.RPNCalculator

  test "initial state" do
    rpn_calculator = %RPNCalculator{}

    assert RPNCalculator.top_of_stack(rpn_calculator) == 0
    assert rpn_calculator.rpn_stack == [0]
    assert rpn_calculator.input_digits == ""
  end

  test "simple addition" do
    rpn_calculator =
      %RPNCalculator{}
      |> RPNCalculator.process_keys(["1", "Enter", "2", "Add"])

    assert RPNCalculator.top_of_stack(rpn_calculator) == 3
  end

  test "input editing" do
    rpn_calculator =
      %RPNCalculator{}
      |> RPNCalculator.process_keys(["1", "2", "Sign", "Backspace", "Dot", "5"])

    assert RPNCalculator.top_of_stack(rpn_calculator) == -1.5
  end

  test "input editing scientific" do
    rpn_calculator =
      %RPNCalculator{}
      |> RPNCalculator.process_keys([
        "1",
        "2",
        "Sign",
        "Backspace",
        "5",
        "Dot",
        "5",
        "EE",
        "Backspace",
        "5",
        "EE",
        "3",
        "1",
        "Sign",
        "Backspace",
        "2"
      ])

    assert RPNCalculator.top_of_stack(rpn_calculator) == -15.55e-32
  end

  test "xy swap" do
    rpn_calculator =
      %RPNCalculator{}
      |> RPNCalculator.process_keys(["1", "Enter", "2", "XY"])

    assert RPNCalculator.top_of_stack(rpn_calculator) == 1
    assert rpn_calculator.rpn_stack == [1, 2]
  end

  test "roll up down drops" do
    rpn_calculator =
      %RPNCalculator{}
      |> RPNCalculator.process_keys([
        "1",
        "Enter",
        "2",
        "Enter",
        "3",
        "Enter",
        "4",
        "RollUp",
        "Drop",
        "RollDown",
        "Drop"
      ])

    assert RPNCalculator.top_of_stack(rpn_calculator) == 2
    assert rpn_calculator.rpn_stack == [2, 4]
  end

  test "using stack instead of parenthesis to compute ( 1 + 2 ) * ( 8 — 5 )" do
    rpn_calculator =
      %RPNCalculator{}
      |> RPNCalculator.process_keys([
        "1",
        "Enter",
        "2",
        "Add",
        "8",
        "Enter",
        "5",
        "Subtract",
        "Multiply"
      ])

    assert RPNCalculator.top_of_stack(rpn_calculator) == 9
  end

  test "push to top of stack" do
    rpn_calculator = %RPNCalculator{}
    rpn_calculator = rpn_calculator |> RPNCalculator.push(123_456)
    assert RPNCalculator.top_of_stack(rpn_calculator) == 123_456
  end

  test "drop clears top of stack" do
    rpn_calculator = %RPNCalculator{}
    rpn_calculator = rpn_calculator |> RPNCalculator.push(42)
    rpn_calculator = rpn_calculator |> RPNCalculator.process_key("Drop")
    assert RPNCalculator.top_of_stack(rpn_calculator) == 0
  end

  test "constants pi & e" do
    rpn_calculator = %RPNCalculator{}
    rpn_calculator = rpn_calculator |> RPNCalculator.process_key("Pi")
    assert RPNCalculator.top_of_stack(rpn_calculator) == :math.pi()
    rpn_calculator = rpn_calculator |> RPNCalculator.process_key("E")
    assert RPNCalculator.top_of_stack(rpn_calculator) == :math.exp(1)
  end

  test "np-op, need 2 args" do
    rpn_calculator = %RPNCalculator{}
    rpn_calculator = rpn_calculator |> RPNCalculator.push(123)
    ~w(Add Subtract Multiply Divide Power XY) |> Enum.each(fn key ->
      rpn_calculator = rpn_calculator |> RPNCalculator.process_key(key)
      assert RPNCalculator.top_of_stack(rpn_calculator) == 123
    end)
  end

  test "inverses" do
    rpn_calculator = %RPNCalculator{}
    rpn_calculator = rpn_calculator |> RPNCalculator.push(123)
    rpn_calculator = rpn_calculator |> RPNCalculator.process_keys(~w(Square Sqrt))
    assert RPNCalculator.top_of_stack(rpn_calculator) == 123
    rpn_calculator = rpn_calculator |> RPNCalculator.process_keys(~w(Exp Ln))
    assert RPNCalculator.top_of_stack(rpn_calculator) == 123
    rpn_calculator = rpn_calculator |> RPNCalculator.push(10)
    rpn_calculator = rpn_calculator |> RPNCalculator.process_keys(~w(Power Log))
    assert RPNCalculator.top_of_stack(rpn_calculator) == 123
  end

  test "render" do
    assert RPNCalculator.render_number(123) == "123"
    assert RPNCalculator.render_number(123.0) == "123"
    assert RPNCalculator.render_number(123.5) == "123.5"
    assert RPNCalculator.render_number(-123) == "-123"
    assert RPNCalculator.render_number(-123.0) == "-123"
    assert RPNCalculator.render_number(-123.5) == "-123.5"
    assert RPNCalculator.render_number(1.23e5) == "123000"
    assert RPNCalculator.render_number(-1.23e-5) == "-1.23e-5"
    assert RPNCalculator.render_number(-1.234567890123456789) == "-1.23456789e+00"
    assert RPNCalculator.render_number(1/3) == "0.3333333333333333"
    assert RPNCalculator.render_number(-1/3) == "-3.33333333e-01"
  end

  test "edge cases input editing" do
    rpn_calculator = %RPNCalculator{}
    rpn_calculator = rpn_calculator |> RPNCalculator.process_keys(~w(0 1 2 3))
    assert RPNCalculator.top_of_stack(rpn_calculator) == 123
    rpn_calculator = rpn_calculator |> RPNCalculator.process_keys(~w(Clear Dot 5))
    assert RPNCalculator.top_of_stack(rpn_calculator) == 0.5
    rpn_calculator = rpn_calculator |> RPNCalculator.process_keys(~w(Dot 5))
    assert RPNCalculator.top_of_stack(rpn_calculator) == 0.55
    rpn_calculator = rpn_calculator |> RPNCalculator.process_keys(~w(Clear 1 Sign Dot 5 EE EE 4 Sign 4))
    assert RPNCalculator.top_of_stack(rpn_calculator) == -1.5e-44
  end
end
