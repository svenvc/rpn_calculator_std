defmodule RPNCalculatorWeb.CalculatorLive.Calculator do
  use RPNCalculatorWeb, :live_view
  require Logger

  alias RPNCalculator.RPNCalculator

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="calculator" phx-window-keyup="calc-keyup" class="grid place-content-center">
        <div id="display" class="mb-2">
          <.calc_display soft>{render_stack_at(@rpn_calculator, 3)}</.calc_display>
          <.calc_display soft>{render_stack_at(@rpn_calculator, 2)}</.calc_display>
          <.calc_display soft>{render_stack_at(@rpn_calculator, 1)}</.calc_display>
          <.calc_display>{render_main_display(@rpn_calculator)}</.calc_display>
        </div>
        <div :if={@error_msg} role="alert" class="alert alert-error w-72 mb-2">
          {@error_msg}
        </div>
        <div id="keypad">
          <div class="grid grid-cols-4 grid-rows-1 gap-2 justify-items-center w-72 font-bold mb-2">
            <.calc_button key="XY" color="info">
              X <.icon name="hero-arrows-right-left" class="icon" />Y
            </.calc_button>
            <.calc_button key="RollDown" color="info">
              R <.icon name="hero-arrow-down" class="icon" />
            </.calc_button>
            <.calc_button key="RollUp" color="info">
              R <.icon name="hero-arrow-up" class="icon" />
            </.calc_button>
            <.calc_button key="Drop" color="info">
              DROP
            </.calc_button>
          </div>
          <div class="grid grid-cols-4 grid-rows-1 gap-2 justify-items-center w-72 font-bold mb-2">
            <.calc_button key="Enter" color="danger">
              ENTER
            </.calc_button>
            <.calc_button key="Clear" color="success">
              CLEAR
            </.calc_button>
            <div
              class="tooltip font-normal"
              data-tip="Switch between basic and scientific calculator style"
            >
              <.calc_button key="Style" color="success">
                <.icon name="hero-calculator" class="icon" />
              </.calc_button>
            </div>
            <.calc_button key="Backspace" color="success">
              <.icon name="hero-backspace" class="icon" />
            </.calc_button>
          </div>
          <div
            :if={!@basic_style?}
            class="grid grid-cols-4 grid-rows-3 gap-2 justify-items-center w-72 font-bold mb-2"
          >
            <.calc_button key="Sin" color="warning">SIN</.calc_button>
            <.calc_button key="Cos" color="warning">COS</.calc_button>
            <.calc_button key="Tan" color="warning">TAN</.calc_button>
            <.calc_button key="Power" color="warning">x<sup>y</sup></.calc_button>
            <.calc_button key="ArcSin" color="warning">ASIN</.calc_button>
            <.calc_button key="ArcCos" color="warning">ACOS</.calc_button>
            <.calc_button key="ArcTan" color="warning">ATAN</.calc_button>
            <.calc_button key="Reciprocal" color="warning">1 / x</.calc_button>
            <.calc_button key="Square" color="warning">x<sup>2</sup></.calc_button>
            <.calc_button key="Sqrt" color="warning">&radic; x</.calc_button>
            <.calc_button key="Exp" color="warning">e<sup>x</sup></.calc_button>
            <.calc_button key="Ln" color="warning">LN</.calc_button>
            <.calc_button key="Log" color="warning">LOG</.calc_button>
            <.calc_button key="Pi" color="success">&#960;</.calc_button>
            <.calc_button key="E" color="success">e</.calc_button>
            <.calc_button key="EE" />
          </div>
          <div class="grid grid-cols-4 grid-rows-3 gap-2 justify-items-center w-72 font-bold">
            <.calc_button key="7" />
            <.calc_button key="8" />
            <.calc_button key="9" />
            <.calc_button key="Divide" color="warning">&divide;</.calc_button>
            <.calc_button key="4" />
            <.calc_button key="5" />
            <.calc_button key="6" />
            <.calc_button key="Multiply" color="warning">&times;</.calc_button>
            <.calc_button key="1" />
            <.calc_button key="2" />
            <.calc_button key="3" />
            <.calc_button key="Subtract" color="warning">-</.calc_button>
            <.calc_button key="0" />
            <.calc_button key="Dot">&period;</.calc_button>
            <.calc_button key="Sign">+ / -</.calc_button>
            <.calc_button key="Add" color="warning">+</.calc_button>
          </div>
        </div>
        <div
          id="help-panel"
          class="grid grid-cols-4 grid-rows-1 gap-4 justify-items-center w-72 mt-10"
        >
          <.help_button
            sheet_id="sheet_help_instructions"
            tooltip="How should I use this calculator ?"
          >
            Help
          </.help_button>
          <.help_button
            sheet_id="sheet-keyboard-shortcuts"
            tooltip="What are the keyboard key equivalents ?"
          >
            Keyboard
          </.help_button>
          <.help_button sheet_id="sheet-key-log" tooltip="Show a log of all buttons that were pressed">
            Log
          </.help_button>
          <.help_button
            sheet_id="sheet-internals"
            tooltip="Show the state of the internal model of the calculator"
          >
            Internal
          </.help_button>
        </div>
      </div>
    </Layouts.app>
    <.sheet_help_instructions />
    """
  end

  defp sheet_help_instructions(assigns) do
    ~H"""
    <dialog id="sheet_help_instructions" class="modal">
      <div class="modal-box w-10/12 max-w-2xl">
        <.header>Help</.header>
        <div class="space-y-4 lg:w-128">
          <p>
            This calculator uses Reverse Polish Notation (RPN).
            That means that you first push numbers on a stack and then you select the operation to perform.
          </p>
          <p>
            For example, to compute <b>(100 + 200) / 3</b>, you would type <b>100</b>, <b>Enter</b>
            (to push the current number up the stack), <b>200</b>
            (the stack now contains 100 and 200), <b>+</b>
            (to add the top two stack entries, often called x, 200, and y, 100, together,
            remove them and leave the result on the top of the stack, as x), <b>3</b>
            and finally <b>/</b>
            (to divide y, 300 by x, 3).
            Note how you no longer need parenthesis, nor an equal sign.
            Even a memory register is not really necessary.
          </p>
          <p>
            Additionally, there are a number of stack manipulation operations, such as
            switching x and y, dropping x and rolling the stack downwards or upwards.
            The display shows the top 4 stack positions.
          </p>
          <p>
            This is an open-source project. See the GitHub repository
            <a href="https://github.com/svenvc/rpn_calculator" class="underline">
              https://github.com/svenvc/rpn_calculator
            </a>
            for more information.
          </p>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  attr :key, :string, required: true
  attr :color, :string, default: "primary", values: ~w(primary danger warning success info)
  attr :width, :string, default: "w-16"
  attr :id_prefix, :string, default: "button"
  slot :inner_block

  defp calc_button(assigns) do
    ~H"""
    <.button
      id={"#{@id_prefix}-#{@key}"}
      variant="solid"
      color={@color}
      class={"active:bg-accent #{@width}"}
      phx-click="calc-button"
      phx-value-key={@key}
      data-js-do={animate_click("#button-#{@key}")}
    >
      {render_slot(@inner_block) || @key}
    </.button>
    """
  end

  attr :soft, :boolean, default: false
  slot :inner_block, required: true

  defp calc_display(assigns) do
    ~H"""
    <div class={"mb-1 w-72 min-h-12 text-right font-mono text-2xl bg-input p-2 rounded-lg"
                    <> (if @soft, do: " text-foreground-softest", else: "")}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :sheet_id, :string, required: true
  attr :tooltip, :string, required: true
  slot :inner_block, required: true

  defp help_button(assigns) do
    ~H"""
    <div class="tooltip" data-tip={@tooltip}>
      <.button
        variant="soft"
        size="xs"
        class="w-16"
        onclick={"#{@sheet_id}.showModal()"}
      >
        {render_slot(@inner_block)}
      </.button>
    </div>
    """
  end

  defp render_main_display(%RPNCalculator{} = rpn_calculator) do
    case rpn_calculator.input_digits do
      "" -> RPNCalculator.top_of_stack(rpn_calculator) |> RPNCalculator.render_number()
      _ -> rpn_calculator.input_digits
    end
  end

  defp render_stack_at(%RPNCalculator{} = rpn_calculator, level) do
    if Enum.count(rpn_calculator.rpn_stack) > level do
      rpn_calculator.rpn_stack |> Enum.at(level) |> RPNCalculator.render_number()
    else
      ""
    end
  end

  defp animate_click(button_id) do
    JS.transition(
      {"ease-out duration-200", "opacity-0", "opacity-100"},
      time: 200,
      to: button_id
    )
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(rpn_calculator: %RPNCalculator{})
      |> assign(key_log: [])
      |> assign(basic_style?: true)
      |> assign(error_msg: nil)

    {:ok, socket}
  end

  @key_translations %{
    "+" => "Add",
    "-" => "Subtract",
    "*" => "Multiply",
    "/" => "Divide",
    "s" => "Sign",
    "c" => "Clear",
    "." => "Dot",
    "~" => "XY",
    "ArrowDown" => "RollDown",
    "ArrowUp" => "RollUp",
    "d" => "Drop",
    "e" => "EE"
  }

  @impl true
  def handle_event("calc-keyup", %{"key" => key}, socket) do
    Logger.debug("keyup: #{key}")
    translated_key = Map.get(@key_translations, key, key)

    if translated_key in RPNCalculator.known_keys() do
      {:noreply,
       socket
       |> process_key(translated_key)
       |> push_event("js-do", %{id: "button-#{translated_key}"})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("calc-button", %{"key" => "Style"}, socket) do
    Logger.debug("button: Style")
    {:noreply, assign(socket, basic_style?: !socket.assigns.basic_style?)}
  end

  @impl true
  def handle_event("calc-button", %{"key" => key}, socket) do
    Logger.debug("button: #{key}")
    {:noreply, socket |> process_key(key)}
  end

  defp process_key(socket, key) do
    Logger.debug("processing: #{key}")

    if key in RPNCalculator.known_keys() do
      try do
        rpn_calculator = socket.assigns.rpn_calculator |> RPNCalculator.process_key(key)
        Logger.debug("rpn_calculator: #{inspect(rpn_calculator)}")

        socket
        |> assign(rpn_calculator: rpn_calculator)
        |> assign(key_log: [key | socket.assigns.key_log])
        |> assign(error_msg: nil)
      rescue
        e -> socket |> assign(error_msg: Exception.message(e))
      end
    else
      socket
    end
  end
end
