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
            <.calc_button key="XY" color="btn-info">
              X&nbsp;↔&nbsp;Y
            </.calc_button>
            <.calc_button key="RollDown" color="btn-info">
              R ↓
            </.calc_button>
            <.calc_button key="RollUp" color="btn-info">
              R ↑
            </.calc_button>
            <.calc_button key="Drop" color="btn-info">
              DROP
            </.calc_button>
          </div>
          <div class="grid grid-cols-4 grid-rows-1 gap-2 justify-items-center w-72 font-bold mb-2">
            <.calc_button key="Enter" color="btn-error">
              ENTER
            </.calc_button>
            <.calc_button key="Clear" color="btn-success">
              CLEAR
            </.calc_button>
            <div
              class="tooltip font-normal"
              data-tip="Switch between basic and scientific calculator style"
            >
              <.calc_button key="Style" color="btn-success">
                <.icon name="hero-calculator" class="icon" />
              </.calc_button>
            </div>
            <.calc_button key="Backspace" color="btn-success">
              <.icon name="hero-backspace" class="icon" />
            </.calc_button>
          </div>
          <div
            :if={!@basic_style?}
            class="grid grid-cols-4 grid-rows-3 gap-2 justify-items-center w-72 font-bold mb-2"
          >
            <.calc_button key="Sin" color="btn-warning">SIN</.calc_button>
            <.calc_button key="Cos" color="btn-warning">COS</.calc_button>
            <.calc_button key="Tan" color="btn-warning">TAN</.calc_button>
            <.calc_button key="Power" color="btn-warning">x<sup>y</sup></.calc_button>
            <.calc_button key="ArcSin" color="btn-warning">ASIN</.calc_button>
            <.calc_button key="ArcCos" color="btn-warning">ACOS</.calc_button>
            <.calc_button key="ArcTan" color="btn-warning">ATAN</.calc_button>
            <.calc_button key="Reciprocal" color="btn-warning">1 / x</.calc_button>
            <.calc_button key="Square" color="btn-warning">x<sup>2</sup></.calc_button>
            <.calc_button key="Sqrt" color="btn-warning">&radic; x</.calc_button>
            <.calc_button key="Exp" color="btn-warning">e<sup>x</sup></.calc_button>
            <.calc_button key="Ln" color="btn-warning">LN</.calc_button>
            <.calc_button key="Log" color="btn-warning">LOG</.calc_button>
            <.calc_button key="Pi" color="btn-success">&#960;</.calc_button>
            <.calc_button key="E" color="btn-success">e</.calc_button>
            <.calc_button key="EE" />
          </div>
          <div class="grid grid-cols-4 grid-rows-3 gap-2 justify-items-center w-72 font-bold">
            <.calc_button key="7" />
            <.calc_button key="8" />
            <.calc_button key="9" />
            <.calc_button key="Divide" color="btn-warning">&divide;</.calc_button>
            <.calc_button key="4" />
            <.calc_button key="5" />
            <.calc_button key="6" />
            <.calc_button key="Multiply" color="btn-warning">&times;</.calc_button>
            <.calc_button key="1" />
            <.calc_button key="2" />
            <.calc_button key="3" />
            <.calc_button key="Subtract" color="btn-warning">-</.calc_button>
            <.calc_button key="0" />
            <.calc_button key="Dot">&period;</.calc_button>
            <.calc_button key="Sign">+ / -</.calc_button>
            <.calc_button key="Add" color="btn-warning">+</.calc_button>
          </div>
        </div>
        <div
          id="help-panel"
          class="grid grid-cols-4 grid-rows-1 gap-4 justify-items-center w-72 mt-10"
        >
          <.help_button
            dialog_id="dialog_help_instructions"
            tooltip="How should I use this calculator ?"
          >
            Help
          </.help_button>
          <.help_button
            dialog_id="dialog_keyboard_shortcuts"
            tooltip="What are the keyboard key equivalents ?"
          >
            Keyboard
          </.help_button>
          <.help_button
            dialog_id="dialog_key_log"
            tooltip="Show a log of all buttons that were pressed"
          >
            Log
          </.help_button>
          <.help_button
            dialog_id="dialog_internals"
            tooltip="Show the state of the internal model of the calculator"
          >
            Internal
          </.help_button>
        </div>
      </div>
    </Layouts.app>
    <.dialog_help_instructions />
    <.dialog_keyboard_shortcuts basic_style?={@basic_style?} />
    <.dialog_key_log key_log={@key_log} />
    <.dialog_internals rpn_calculator={@rpn_calculator} />
    """
  end

  defp dialog_help_instructions(assigns) do
    ~H"""
    <dialog id="dialog_help_instructions" class="modal">
      <div class="modal-box w-8/12 max-w-2xl">
        <.header>Help</.header>
        <div class="space-y-4">
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

  attr :basic_style?, :boolean, required: true

  defp dialog_keyboard_shortcuts(assigns) do
    ~H"""
    <dialog id="dialog_keyboard_shortcuts" class="modal">
      <div class="modal-box w-8/12 max-w-2xl">
        <.header>Keyboard Shortcuts</.header>
        <table class="table">
          <thead>
            <tr>
              <td class="py-2">Button</td>
              <td class="py-2">Operation</td>
              <td class="py-2">Shortcut</td>
            </tr>
          </thead>
          <tbody>
            <.help_row key="XY" color="btn-info" keyboard="~">
              X&nbsp;↔&nbsp;Y
            </.help_row>
            <.help_row key="RollDown" color="btn-info" keyboard="ArrowDown">
              R ↓
            </.help_row>
            <.help_row key="RollUp" color="btn-info" keyboard="ArrowUp">
              R ↑
            </.help_row>
            <.help_row key="Drop" color="btn-info" keyboard="d">
              DROP
            </.help_row>
            <.help_row key="Enter" color="btn-error" keyboard="Enter">
              ENTER
            </.help_row>
            <.help_row key="Clear" color="btn-success" keyboard="c">
              CLEAR
            </.help_row>
            <.help_row key="Backspace" color="btn-success" keyboard="Backspace">
              <.icon name="hero-backspace" class="icon" />
            </.help_row>
            <.help_row key="Add" color="btn-warning" keyboard="+">
              +
            </.help_row>
            <.help_row key="Subtract" color="btn-warning" keyboard="-">
              -
            </.help_row>
            <.help_row key="Multiply" color="btn-warning" keyboard="*">
              &times;
            </.help_row>
            <.help_row key="Divide" color="btn-warning" keyboard="/">
              &divide;
            </.help_row>
            <.help_row key="Sign" keyboard="s">
              + / -
            </.help_row>
            <.help_row key="Dot" keyboard=".">
              &period;
            </.help_row>
            <.help_row :if={!@basic_style?} key="EE" keyboard="e">
              EE
            </.help_row>
            <.help_row :for={number <- 0..9} key={number}>
              {number}
            </.help_row>
          </tbody>
        </table>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  attr :key_log, :list, required: true

  defp dialog_key_log(assigns) do
    ~H"""
    <dialog id="dialog_key_log" class="modal">
      <div class="modal-box w-8/12 max-w-2xl">
        <.header>Last Operations Log</.header>
        <p class="mb-4">These are the last operations executed, most recent first.</p>
        <div class="w-96 max-w-fit">
          <.button :for={key <- @key_log} variant="primary" class="btn m-1 btn-outline">
            {key}
          </.button>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  attr :rpn_calculator, :map, required: true

  defp dialog_internals(assigns) do
    ~H"""
    <dialog id="dialog_internals" class="modal">
      <div class="modal-box w-8/12 max-w-2xl">
        <.header>Internal State</.header>
        <p>This is the representation of the RPN Calculator's internal state.</p>
        <div class="mt-8 mb-8 font-mono">
          {render_internals(@rpn_calculator)}
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  attr :key, :string, required: true
  attr :color, :string, default: "btn-neutral"
  attr :width, :string, default: "w-16"
  attr :id_prefix, :string, default: "button"
  slot :inner_block

  defp calc_button(assigns) do
    ~H"""
    <.button
      id={"#{@id_prefix}-#{@key}"}
      variant="primary"
      class={"btn active:bg-accent #{@width} btn-active #{@color}"}
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
    <div class={"mb-1 w-72 min-h-12 text-right font-mono text-2xl bg-base-300 p-2 rounded-lg"
                    <> (if @soft, do: " text-foreground-softest", else: "")}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :dialog_id, :string, required: true
  attr :tooltip, :string, required: true
  slot :inner_block, required: true

  defp help_button(assigns) do
    ~H"""
    <div class="tooltip" data-tip={@tooltip}>
      <.button
        class="btn btn-sm btn-soft w-16"
        onclick={"#{@dialog_id}.showModal()"}
      >
        {render_slot(@inner_block)}
      </.button>
    </div>
    """
  end

  attr :key, :string, required: true
  attr :color, :string, default: "btn-primary"
  attr :keyboard, :string
  slot :inner_block

  defp help_row(assigns) do
    ~H"""
    <tr>
      <td class="py-2">
        <.calc_button key={@key} color={@color} id_prefix="help-button">
          {render_slot(@inner_block)}
        </.calc_button>
      </td>
      <td class="py-2">{@key}</td>
      <td class="py-2">
        <.button variant="primary" class="btn m-1 btn-outline">
          {Map.get(assigns, :keyboard, @key)}
        </.button>
      </td>
    </tr>
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

  defp render_internals(rpn_calculator) do
    inspect(
      rpn_calculator |> Map.take([:rpn_stack, :input_digits, :computed?]),
      pretty: true,
      charlists: :as_lists
    )
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
