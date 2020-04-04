import React from 'react'
import * as ReactDOM from 'react-dom'
import * as Riptide from '@ironbay/riptide'

// Create a connection to the remote server
const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

// Represents the remote store on the server
const remote = new Riptide.Store.Remote(connection)
// Represents local store for the current session
const local = new Riptide.Store.Memory()
// Setup local store to sync with remote.
// Returns a sync object that can be used to apply mutations both to local and remote
const sync = local.sync(remote)

// Log entire state when local store updates
local.onChange.add(mut => {
    console.dir('Mutation', mut)
    console.dir('Local', local.query_path([]))

})

// When the connection status changes, save the state just to the local store
connection.transport.onStatus.add(status => local.merge(['connection', 'status'], status))

// Create interceptor to fetch todos whenever connection becomes ready
local.interceptor.before_mutation(['connection'], async (mut) => {
    if (mut.merge.status !== 'ready') return

    // Refresh todos path from remote and subscribe to any future changes
    await remote.query({
        'todos': {
            subscribe: true
        }
    })
})

interface Todo {
    name?: string
    key?: string
    created?: number
    completed?: boolean
}

function App() {
    // Tell React to rerender the application when there's a change to the local store
    const [_, render] = React.useState(0)
    React.useEffect(() => {
        local.onChange.add(() => render(val => val + 1))
    }, [])

    async function create_todo() {
        const name = prompt('Name of new todo?')
        if (!name) return
        const key = Riptide.UUID.ascending()
        try {
            await sync.merge(['todos', key], {
                key,
                name
            })
        } catch (ex) {
            alert(ex)
            await local.delete(['todos', key])
        }
    }

    function handle_click(todo: Todo) {
        todo.completed ? sync.delete(['todos', todo.key]) : sync.merge(['todos', todo.key, 'completed'], true)
    }

    return (
        <div>
            <ul>
                <h3>Todos</h3>
                {
                    local
                        .query_values<Todo>(['todos'])
                        .map(todo => {
                            return (
                                <li key={todo.key} onClick={() => handle_click(todo)}>
                                    {
                                        todo.completed ? <s>{todo.name}</s> : todo.name
                                    }
                                    &nbsp;-&nbsp;
                                    {
                                        todo.created && `created ${new Date(todo.created).toLocaleTimeString()}`
                                    }
                                    <hr />
                                </li>
                            )
                        })
                }
            </ul >
            <button onClick={create_todo}>Create New</button>
        </div >
    )
}

ReactDOM.render(<App />, document.querySelector('.root'))