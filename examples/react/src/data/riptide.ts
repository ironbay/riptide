import * as Riptide from '@ironbay/riptide'

// Create a connection to the remote server
export const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

// Represents the remote store on the server
const remote = new Riptide.Store.Remote(connection)

// Represents local store for the current session
export const local = new Riptide.Store.Memory()

// Setup local store to sync with remote.
// Returns a sync object that can be used to apply mutations both to local and remote
export const sync = local.sync(remote)

// Log entire state when local store updates
local.onChange.add(mut => {
    console.dir(mut)
    console.dir(local.query_path([]))

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