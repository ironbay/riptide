# Handlers

It is possible to extend Riptide to support more than simple Mutations and Queries. Riptide Handlers let you define custom commands that can be triggered by the client. It's effectively a simple RPC framework. Handlers can be added to your Riptide configuration.

```elixir

config :riptide,
  handlers: [
    Todo.Auth,
    Todo.Ping
  ]


```

When a command is sent up from the client, every handler in this is called in order until one handles the command.

---

## Structure

Clients connect to Riptide over a websocket connection and send commands (either cast or calls) that contain an action and a body. Each connection has state that is passed into the handler when it is triggered by a command. The handler can process the command and choose to update the state. The lifecycle looks very similar to Elixir's GenServer.

&nbsp;

### `handle_call`

A call is a command that expects a reply.

```elixir
defmodule Todo.Auth do
  use Riptide.Command

  def handle_call("todo.login", %{"email" => email, "password" => password}, state) do
    case Todo.User.login(email, password) do
      {:ok, user} -> {:reply, true, %{user: user}}
      {:error, error} -> {:error, error, state}
    end
  end
end

```

The valid responses are

- `{:reply, reply, next_state}` - Sends the reply to the client and updates the connection state
- `{:error, error, next_state}` - Sends the error to the client and updates the connection state

&nbsp;

### `handle_cast`

A cast is a command that does not expect a reply.

```elixir
defmodule Todo.Ping do
  use Riptide.Command

  def handle_cast("todo.ping", _body, state) do
    Riptide.merge!(["user:info", state.user, "last_seen"], :os.system_time(:millisecond))
    {:noreply, state}
  end
end

```

A valid response is

- `{:noreply, next_state}` - Updates the connection state with next_state
