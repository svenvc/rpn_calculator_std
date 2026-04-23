defmodule RPNCalculatorWeb.CalculatorController do
  use RPNCalculatorWeb, :controller

  alias RPNCalculator.RPNCalculator

  def new(conn, _params) do
    data = %RPNCalculator{} |> Map.take([:rpn_stack, :input_digits, :computed?])
    json(conn, data)
  end

  def known_keys(conn, _params) do
    data = RPNCalculator.known_keys()
    json(conn, data)
  end

  def process_key(conn, %{
        "input_digits" => input_digits,
        "computed?" => computed?,
        "rpn_stack" => rpn_stack,
        "key" => key
      } = _params)
      when is_binary(input_digits) and
             is_boolean(computed?) and
             is_list(rpn_stack) and
             is_binary(key) do
    state = %RPNCalculator{input_digits: input_digits, computed?: computed?, rpn_stack: rpn_stack}
    IO.puts("/process-key/#{key} - #{inspect(state)}")
    state = state |> RPNCalculator.process_key(key)
    data = state |> Map.take([:rpn_stack, :input_digits, :computed?])
    json(conn, data)
  end

  def push(conn, %{
        "input_digits" => input_digits,
        "computed?" => computed?,
        "rpn_stack" => rpn_stack,
        "number" => number
      } = _params)
      when is_binary(number) do
    state = %RPNCalculator{input_digits: input_digits, computed?: computed?, rpn_stack: rpn_stack}
    number = RPNCalculator.parse_input(number)
    IO.puts("/push/#{number} - #{inspect(state)}")
    state = state |> RPNCalculator.push(number)
    data = state |> Map.take([:rpn_stack, :input_digits, :computed?])
    json(conn, data)
  end
end
