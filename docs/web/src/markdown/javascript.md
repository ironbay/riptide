# Javascript

The first step to setting up Riptide is creating a websocket connection. Create a Websocket on port 12000:

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

Great, now we have both a remote and local store. The next step is to set up a sync object which we'll later use to apply mutations to both the local and remote representations.

```javascript
const sync = local.sync(remote)
```

Now we can apply Mutations to local and remote and know they're synced. Next we can add a simple listener onto local which will listen for any updates. This is useful for handling rerenders in our application. In this case we'll log the Mutation being applie to local and the entire local store on every update: 

```javascript
local.onChange.add(mut => {
    console.dir('Mutation', mut)
    console.dir('Local', local.query_path([]))
})
```

We can listen for changes in our connection status. We can save the state to just the local store on a status change with the following:

```javascript
connection.transport.onStatus.add(status => 
    local.merge(['connection', 'status'], status)
)
```

Since our app displays a list of constantly updating todos, we want to make sure to do two things: fetch all the todos when our connection becomes ready, and subscribe to the todos so we're aware of any changes that take place. We can do this by placing a listener on the local store:


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
