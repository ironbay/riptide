import React from "react"
import * as ReactDOM from "react-dom"
import { UUID } from "@ironbay/riptide"
import { useRiptide } from "@ironbay/riptide-react"

// look at ./data/riptide to see how Riptide is bootstrapped
import { local, sync } from "./data/riptide"

interface Todo {
  name?: string
  key?: string
  created?: number
  completed?: boolean
}

function App() {
  console.dir(useRiptide(local))
  const [_, render] = React.useState(0)
  React.useEffect(() => {
    local.onChange.add(() => render((val) => val + 1))
  }, [])

  async function create_todo() {
    const name = prompt("Name of new todo?")
    if (!name) return
    const key = UUID.ascending()
    try {
      await sync.merge(["todos", key], {
        key,
        name,
      })
    } catch (ex) {
      alert(ex)
      await local.delete(["todos", key])
    }
  }

  function handle_click(todo: Todo) {
    todo.completed
      ? sync.delete(["todos", todo.key])
      : sync.merge(["todos", todo.key, "completed"], true)
  }

  return (
    <div>
      <ul>
        <h3>Todo Lists</h3>
        {local
          .query_values<Todo>(["todos"])
          .map((todo) => {
            return (
              <li key={todo.key} onClick={() => handle_click(todo)}>
                {todo.completed ? <s>{todo.name}</s> : todo.name}
                &nbsp;-&nbsp;
                {todo.created &&
                  `created ${new Date(todo.created).toLocaleTimeString()}`}
                <hr />
              </li>
            )
          })}
      </ul>
      <button onClick={create_todo}>Create New</button>
    </div>
  )
}

ReactDOM.render(<App />, document.querySelector(".root"))
