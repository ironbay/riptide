import * as Riptide from '@ironbay/riptide'

// Create a connection to the remote server
const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

// Represents the remote store on the server
const remote = new Riptide.Store.Remote(connection)
// Represents local store that is synced with remote store
const local = new Riptide.Store.Memory()
// Setup local store to sync with remote.
// Returns a sync object that can be used to apply mutations both to local and remote
const sync = local.sync(remote)

export { connection, remote, local, sync }