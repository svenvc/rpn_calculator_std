defmodule RPNCalculatorWeb.UpController do
  use RPNCalculatorWeb, :controller

  def check(conn, _params) do
    text(
      conn,
      "OK - rpn_calculator #{Application.spec(:rpn_calculator, :vsn)} - #{DateTime.utc_now()}\n"
    )
  end
end
