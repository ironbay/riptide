import React from 'react'
import * as ReactDOM from 'react-dom'
import { local, remote, sync, connection } from './data/riptide'
import { UUID } from '@ironbay/riptide'

// Log entire state when local store updates
local.onChange.add(() => console.dir('Local', local.query_path([])))
// Log all mutations that happen
local.onChange.add(mut => console.dir('Mutation', mut))

// When the connection status changes, save the state just to the local store
connection.transport.onStatus.add(status => local.merge(['connection', 'status'], status))

// Create interceptor to fetch creatures path whenever connection becomes ready
local.interceptor.before_mutation(['connection'], async (mut) => {
    if (mut.merge.status !== 'ready') return

    // Refresh creatures path and subscribe to any future changes
    await remote.query({
        'creatures': {
            subscribe: true
        }
    })
})

interface Creature {
    name?: string
    key?: string
    created?: number
}

function App() {
    // Tell React to rerender the application when there's a change to the local store
    const [_, render] = React.useState(0)
    React.useEffect(() => {
        local.onChange.add(() => render(val => val + 1))
    }, [])
    return (
        <div >
            {
                local
                    .query_values<Creature>(['creatures'])
                    .map(item => {
                        return (
                            <div key={item.key} onClick={async () => await sync.delete(['creatures', item.key])}>
                                {item.name} - {item.created && `Created ${new Date(item.created).toLocaleTimeString()}`}
                            </div>
                        )
                    })
            }
            <button onClick={async () => {
                const name = prompt('Name of new creature?')
                if (!name) return
                const key = UUID.ascending()
                try {
                    await sync.merge(['creatures', key], {
                        key,
                        name
                    })
                } catch (ex) {
                    alert(ex)
                    await local.delete(['creatures', key])
                }
            }}>Create New</button>
        </div>
    )
}

ReactDOM.render(<App />, document.querySelector('.root'))