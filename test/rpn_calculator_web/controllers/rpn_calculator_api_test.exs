defmodule RPNCalculatorWeb.RPNCalculatorAPITest do
  use RPNCalculatorWeb.ConnCase

  test "GET /api/known-keys", %{conn: conn} do
    conn = get(conn, ~p"/api/known-keys")

    assert json_response(conn, 200) |> Enum.member?("Enter")
  end

  test "GET /api/new", %{conn: conn} do
    conn = get(conn, ~p"/api/new")

    state = json_response(conn, 200)

    assert state["input_digits"] == ""
    assert state["computed?"] == false
    assert state["rpn_stack"] == [0]
  end

  test "POST /api/process-key", %{conn: conn} do
    conn = get(conn, ~p"/api/new")
    state = json_response(conn, 200)

    conn =
      conn
      |> recycle()
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/process-key/1", state)

    state = json_response(conn, 200)
    assert state["input_digits"] == "1"
    assert state["computed?"] == false
    assert state["rpn_stack"] == [1]
  end

  test "POST /api/push", %{conn: conn} do
    conn = get(conn, ~p"/api/new")
    state = json_response(conn, 200)

    conn =
      conn
      |> recycle()
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/push/42", state)

    state = json_response(conn, 200)
    assert state["input_digits"] == ""
    assert state["computed?"] == true
    assert state["rpn_stack"] == [42]
  end

  test "simple addition", %{conn: conn} do
    conn = get(conn, ~p"/api/new")
    state = json_response(conn, 200)

    {_conn, state} =
      ["1", "Enter", "2", "Add"]
      |> Enum.reduce({conn, state}, fn key, {conn, state} ->
        conn =
          conn
          |> recycle()
          |> put_req_header("content-type", "application/json")
          |> post(~p"/api/process-key/#{key}", state)

        state = json_response(conn, 200)
        {conn, state}
      end)

    assert state["rpn_stack"] == [3]
  end
end
