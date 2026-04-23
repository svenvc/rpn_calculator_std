defmodule RPNCalculatorWeb.CalculatorController do
  use RPNCalculatorWeb, :controller

  alias RPNCalculator.RPNCalculator

  def new(conn, _params) do
    conn |> json(to_map(%RPNCalculator{}))
  end

  def known_keys(conn, _params) do
    conn |> json(RPNCalculator.known_keys())
  end

  def process_key(conn, %{"key" => key} = params)
      when is_binary(key) do
    try do
      state = to_rpn_calculator(params)
      # IO.puts("/process-key/#{key} - #{inspect(state)}")
      state = state |> RPNCalculator.process_key(key)
      conn |> json(to_map(state))
    rescue
      error -> conn |> put_status(:bad_request) |> json(%{"error" => Exception.message(error)})
    end
  end

  def push(conn, %{"number" => number} = params)
      when is_binary(number) do
    try do
      state = to_rpn_calculator(params)
      number = RPNCalculator.parse_input(number)
      # IO.puts("/push/#{number} - #{inspect(state)}")
      state = state |> RPNCalculator.push(number)
      conn |> json(to_map(state))
    rescue
      error -> conn |> put_status(:bad_request) |> json(%{"error" => Exception.message(error)})
    end
  end

  defp to_map(%RPNCalculator{} = rpn_calculator) do
    rpn_calculator |> Map.take([:rpn_stack, :input_digits, :computed?])
  end

  defp to_rpn_calculator(%{
         "input_digits" => input_digits,
         "computed?" => computed?,
         "rpn_stack" => rpn_stack
       })
       when is_binary(input_digits) and
              is_boolean(computed?) and
              is_list(rpn_stack) do
    if !Enum.all?(rpn_stack, fn x -> is_number(x) end) do
      raise "rpn_stack must only contain numbers"
    end

    %RPNCalculator{input_digits: input_digits, computed?: computed?, rpn_stack: rpn_stack}
  end
end
