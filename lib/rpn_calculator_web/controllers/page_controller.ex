defmodule RPNCalculatorWeb.PageController do
  use RPNCalculatorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
