// import * as Riptide from '@ironbay/riptide'

// // Create a connection to the remote server
// const connection = Riptide.Connection.create()
// connection.transport.connect('ws://localhost:12000/socket')

// // Represents the remote store on the server
// const remote = new Riptide.Store.Remote(connection)
// // Represents local store for the current session
// const local = new Riptide.Store.Memory()
// // Setup local store to sync with remote.
// // Returns a sync object that can be used to apply mutations both to local and remote
// const sync = local.sync(remote)

// // Log entire state when local store updates
// local.onChange.add(mut => {
//     console.dir('Mutation', mut)
//     console.dir('Local', local.query_path([]))

// })

// // When the connection status changes, save the state just to the local store
// connection.transport.onStatus.add(status => local.merge(['connection', 'status'], status))

// export { connection, local, remote, sync }