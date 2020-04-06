# Javascript

The first step to setting up Riptide is creating a connection instance, which provides an interface for interacting with our Websocket connection to the remote server. We'll later user this connection instance to listen for changes in our connection status.

```javascript
const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')
```

Next lets instantiate the remote server store, passing in our websocket connection.

```javascript
const remote = new Riptide.Store.remote(connection)
```

Now that we have the remote server store accessible, let's create a representation of the local store for the current session. 

```javascript
const local = new Riptide.Store.Memory()
```

Now that we have both a local and remote store, the next step is to create a sync object. Any change we want to apply from the client, we do so through the sync object. This ensures are local and remote stores are kept in sync. We insantiate a sync like this:

```javascript
const sync = local.sync(remote)
```
Now that we have a sync object, we can write Mutations that will be applied to both stores. 

```javascript
sync.delete(['todos', 'todo_01'])

sync.merge(['todos', 'todo_02'], {name: 'Clean the fish bowl'})
```

Now that we have the ability to update our local and remote states, we need a way to listen to our local store. If take an action when our local store updates (such as rerendering our list of todos) we do so with a listener: 

```javascript
local.onChange.add(mut => {
    console.dir('Mutation', mut)
    console.dir('Local', local.query_path([]))
})
```

We can also listen for changes to our Websocket connection. We can listen for changes in our connection's status and keep a local record of the status:

```javascript
connection.transport.onStatus.add(status => 
    local.merge(['connection', 'status'], status)
)
```

Now our local state will keep an up-to-date record of our connection status. What if we want to take an action whenever the connection status updates? To do this we'll use an interceptor on our local store that will listen for any changes under the `['connection']` path. Whenever that path is altered in our local store our interceptor will run, passing the responsible Mutation to the callback. 

```javascript
local.interceptor.before_mutation(['connection'], async (mut) => {
    if (mut.merge.status !== 'ready') return 

    await remote.query({
        'todos': {
            subscribe: true
        }
    })
})
```

Here we're waiting for a `ready` status from the Websocket connection. When that status is written to our local state, we query all of our todos from the remote server. We also make sure to write `subscribe: true`, so that we'll be subscribed to any future changes.