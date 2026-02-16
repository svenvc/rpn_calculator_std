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
end
