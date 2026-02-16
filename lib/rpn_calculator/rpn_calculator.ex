defmodule RPNCalculator.RPNCalculator do
  defstruct rpn_stack: [0], input_digits: "", computed?: false

  @moduledoc """
  RPNCalculator implements the core model of a Reverse Polish Notation calculator.

  RPNCalculator is a struct that holds a stack of numbers (rpn_stack),
  the input being entered/edited by the user (input_digits)
  and a flag that indicates if the top of the stack was the result of a computation
  or if the user is still entering/editing it (computed?).
  The top of the stack, x, equals the interpretation of the input_digits.

  The basic operation is proces_key that transitions the model from one state to the next.
  """

  @known_keys ~w(
    0 1 2 3 4 5 6 7 8 9
    Dot Sign
    Enter XY RollDown RollUp Drop
    Add Subtract Multiply Divide
    Backspace Clear
    EE Pi E
    Sin Cos Tan
    ArcSin ArcCos ArcTan
    Power Exp
    Square Sqrt
    Log Ln
    Reciprocal)

  @doc "Return the list of keys that I can process"

  def known_keys, do: @known_keys

  # keys relating to entering/editing input numbers

  @max_input_length 16

  @doc "Process key, transitioning rpn_calculator to its next state"

  def process_key(%__MODULE__{} = rpn_calculator, key)
      when key in ~w(0 1 2 3 4 5 6 7 8 9) do
    if rpn_calculator.input_digits == "" and rpn_calculator.computed? do
      # stack lift or auto enter when entering a new number after a computation
      rpn_calculator
      |> update_rpn_stack(
        fn [top | tail] -> [0 | [top | tail]] end,
        clear_input: false
      )
    else
      rpn_calculator
    end
    |> update_input_digits(fn input_digits ->
      cond do
        input_digits == "0" -> key
        String.length(input_digits) >= @max_input_length -> input_digits
        String.last(input_digits) == "e" and key == "0" -> input_digits
        true -> input_digits <> key
      end
    end)
    |> update_x()
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Dot") do
    rpn_calculator
    |> update_input_digits(fn input_digits ->
      cond do
        String.contains?(input_digits, ".") -> input_digits
        input_digits == "" -> "0."
        true -> input_digits <> "."
      end
    end)
    |> update_x()
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Sign") do
    rpn_calculator =
      rpn_calculator
      |> update_input_digits(fn input_digits ->
        if String.contains?(input_digits, "e") do
          cond do
            String.last(input_digits) == "e" ->
              input_digits

            true ->
              [mantisse, exponent] = String.split(input_digits, "e")

              if String.first(exponent) == "-" do
                mantisse <> "e" <> String.trim_leading(exponent, "-")
              else
                mantisse <> "e-" <> exponent
              end
          end
        else
          cond do
            input_digits == "" -> ""
            String.first(input_digits) == "-" -> String.slice(input_digits, 1..-1//1)
            true -> "-" <> input_digits
          end
        end
      end)

    if rpn_calculator.input_digits == "" do
      rpn_calculator
      |> update_rpn_stack(
        fn [x | tail] -> [-x | tail] end,
        clear_input: false
      )
      |> update_computed?(true)
    else
      rpn_calculator
      |> update_x()
    end
  end

  def process_key(%__MODULE__{} = rpn_calculator, "EE") do
    rpn_calculator
    |> update_input_digits(fn input_digits ->
      if input_digits == "" or String.contains?(input_digits, "e") do
        input_digits
      else
        if String.contains?(input_digits, ".") do
          input_digits <> "e"
        else
          input_digits <> ".0e"
        end
      end
    end)
    |> update_x()
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Backspace") do
    rpn_calculator
    |> update_input_digits(fn input_digits ->
      cond do
        String.length(input_digits) == 2 and String.first(input_digits) == "-" ->
          ""

        String.contains?(input_digits, "e") and String.at(input_digits, -2) == "-" ->
          String.slice(input_digits, 0..-3//1)

        true ->
          String.slice(input_digits, 0..-2//1)
      end
    end)
    |> update_x()
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Clear") do
    rpn_calculator
    |> update_rpn_stack(fn rpn_stack ->
      if rpn_calculator.input_digits == "" do
        [0]
      else
        rpn_stack
      end
    end)
    |> update_x()
  end

  # Fundamental RPN functions, mathematical operations and stack manipulation

  def process_key(%__MODULE__{} = rpn_calculator, "Enter") do
    rpn_calculator
    |> update_rpn_stack(fn [top | tail] -> [top | [top | tail]] end)
    |> update_computed?(false)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Add") do
    rpn_calculator
    |> update_rpn_stack(fn
      [x | [y | tail]] -> [x + y | tail]
      rpn_stack -> rpn_stack
    end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Subtract") do
    rpn_calculator
    |> update_rpn_stack(fn
      [x | [y | tail]] -> [y - x | tail]
      rpn_stack -> rpn_stack
    end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Multiply") do
    rpn_calculator
    |> update_rpn_stack(fn
      [x | [y | tail]] -> [x * y | tail]
      rpn_stack -> rpn_stack
    end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Divide") do
    rpn_calculator
    |> update_rpn_stack(fn
      [x | [y | tail]] -> [y / x | tail]
      rpn_stack -> rpn_stack
    end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Power") do
    rpn_calculator
    |> update_rpn_stack(fn
      [x | [y | tail]] -> [:math.pow(x, y) | tail]
      rpn_stack -> rpn_stack
    end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Pi") do
    rpn_calculator
    |> update_rpn_stack(fn
      [0] -> [:math.pi()]
      rpn_stack -> [:math.pi() | rpn_stack]
    end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "E") do
    rpn_calculator
    |> update_rpn_stack(fn
      [0] -> [:math.exp(1)]
      rpn_stack -> [:math.exp(1) | rpn_stack]
    end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Reciprocal") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [1 / x | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Sqrt") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [:math.sqrt(x) | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Square") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [x * x | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Exp") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [:math.exp(x) | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Log") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [:math.log10(x) | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Ln") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [:math.log(x) | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Sin") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [:math.sin(x / 180 * :math.pi()) | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Cos") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [:math.cos(x / 180 * :math.pi()) | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Tan") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [:math.tan(x / 180 * :math.pi()) | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "ArcSin") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [:math.asin(x) / :math.pi() * 180 | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "ArcCos") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [:math.acos(x) / :math.pi() * 180 | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "ArcTan") do
    rpn_calculator
    |> update_rpn_stack(fn [x | tail] -> [:math.atan(x) / :math.pi() * 180 | tail] end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "XY") do
    rpn_calculator
    |> update_rpn_stack(fn
      [x | [y | tail]] -> [y | [x | tail]]
      rpn_stack -> rpn_stack
    end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "RollDown") do
    rpn_calculator
    |> update_rpn_stack(fn rpn_stack ->
      {top, rest} = List.pop_at(rpn_stack, 0)
      rest ++ [top]
    end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "RollUp") do
    rpn_calculator
    |> update_rpn_stack(fn rpn_stack ->
      {bottom, rest} = List.pop_at(rpn_stack, -1)
      [bottom] ++ rest
    end)
  end

  def process_key(%__MODULE__{} = rpn_calculator, "Drop") do
    rpn_calculator
    |> update_rpn_stack(fn
      [top] -> [top]
      [_top | tail] -> tail
    end)
  end

  # support for testing

  @doc "Process a list of keys in sequence"

  def process_keys(%__MODULE__{} = rpn_calculator, keys) when is_list(keys) do
    Enum.reduce(
      keys,
      rpn_calculator,
      fn key, rpn_calculator -> process_key(rpn_calculator, key) end
    )
  end

  # support for interfaces

  @doc "Return the top of the stack, x, of rpn_calculator, the display value"

  def top_of_stack(%__MODULE__{} = rpn_calculator) do
    [top_of_stack | _tail] = rpn_calculator.rpn_stack
    top_of_stack
  end

  @max_integer 999_999_999_999_999_999
  @max_output_length 18

  @doc "Render number to a string, for human consumption, limiting its size and precision"

  def render_number(number) do
    integer = trunc(number)

    cond do
      number == integer and abs(integer) <= @max_integer ->
        to_string(integer)

      true ->
        string = :erlang.float_to_binary(number * 1.0, [:short])

        if String.length(string) > @max_output_length do
          :erlang.float_to_binary(number * 1.0, [{:scientific, 8}])
        else
          string
        end
    end
  end

  # internal functions, declared public for documentation purposes

  @doc "Apply fun to update the rpn_stack in rpn_calculator and clear the input unless disabled"

  def update_rpn_stack(%__MODULE__{} = rpn_calculator, fun, opts \\ [clear_input: true]) do
    if Keyword.get(opts, :clear_input) do
      Map.update!(rpn_calculator, :rpn_stack, fun)
      |> clear_input()
    else
      Map.update!(rpn_calculator, :rpn_stack, fun)
    end
  end

  @doc "Apply fun to update input_digits in rpn_calculator"

  def update_input_digits(%__MODULE__{} = rpn_calculator, fun) do
    Map.update!(rpn_calculator, :input_digits, fun)
  end

  @doc "Set computed? to boolean in rpn_calculator"

  def update_computed?(%__MODULE__{} = rpn_calculator, boolean) do
    Map.replace!(rpn_calculator, :computed?, boolean)
  end

  @doc "Update the top of the stack, x, by parsing the input_digits, not clearing the input and setting computed? to false"

  def update_x(%__MODULE__{} = rpn_calculator) do
    new_x = parse_input(rpn_calculator.input_digits)

    rpn_calculator
    |> update_rpn_stack(
      fn [_top | tail] -> [new_x | tail] end,
      clear_input: false
    )
    |> update_computed?(false)
  end

  @doc "Clear the input_digits and set computed? to true"

  def clear_input(%__MODULE__{} = rpn_calculator) do
    rpn_calculator
    |> update_input_digits(fn _ -> "" end)
    |> update_computed?(true)
  end

  @doc "Convert a string with input into a number, float or integer"

  def parse_input(""), do: 0

  def parse_input(input_digits) do
    # Use the correct parser for an integer or float, giving it the correct input
    if String.contains?(input_digits, "e") do
      if String.last(input_digits) == "e" do
        String.to_float(String.slice(input_digits, 0..-2//1))
      else
        String.to_float(input_digits)
      end
    else
      if String.contains?(input_digits, ".") do
        if String.last(input_digits) == "." do
          String.to_integer(String.slice(input_digits, 0..-2//1))
        else
          String.to_float(input_digits)
        end
      else
        String.to_integer(input_digits)
      end
    end
  end
end
