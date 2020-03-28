defmodule Riptide.Handler do
  @callback handle_call(action :: String.t(), body :: any(), state :: any()) ::
              nil | {:reply, any(), any()}
  @callback handle_cast(action :: String.t(), body :: any(), state :: any()) ::
              nil | {:reply, any(), any()} | {:noreply, any(), any()}
  @callback handle_info(msg :: any(), state :: any()) ::
              nil | {:reply, any(), any()} | {:noreply, any(), any()}
  defmacro __using__(_opts) do
    quote do
      @behaviour Riptide.Handler
      @before_compile Riptide.Handler
    end
  end

  defmacro __before_compile__(_opts) do
    quote do
      def handle_call(_action, _body, _state), do: nil
      def handle_cast(_action, _body, _state), do: nil
      def handle_info(_msg, _state), do: nil
    end
  end
end
