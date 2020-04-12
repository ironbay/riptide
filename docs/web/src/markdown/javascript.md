# Javascript

The first step in setting up Riptide is instantiating a `Connection` instance. Let's create a new instance: 


```javascript
const connection = Riptide.Connection.create()
```

This instance creates a simple interface for managing our connection to the remote server. The `Connection` client has a `transport` property providing an interface for dealing with our connection to the remote server. The `transport` interface abstracts away nitty details of the connection like retrying failed writes and cleaning up state on disconnects. Using the `tranport` interface, we'll create a `Websocket` connection the remote server:

```javascript
connection.transport.connect('ws://localhost:12000/socket')
```

Now that we have our `Websocket` connection up and running, we need a way of querying and writing data across this connection. In Riptide, we use `Store` instances for querying and writing data. The store instance we use for communicating with the remote server is the aptly named `Riptide.Store.Remote`. We'll create a new remote store, passing in our previously created connection instance that our remote store will now use:  

```javascript
const remote = new Riptide.Store.Remote(connection)
```

Great, now we have a way to query and write data to the backend. 

Now that we have access to remote data, we need a way for our front end to access that data in memory. To complement our `Remote` store, we'll now create a `Memory` store to handle our in-memory data. The interfaces for our `Remote` and `Memory` stores are very similar, but the former is reading from the remote server and the latter is reading whatever we've put in memory. Let's create a new `Memory` instance: 


```javascript
const local = new Riptide.Store.Memory()
```

Now that we have a `Memory` instance, we can start dicating what we want put in memory of our application. We can start by using a special feature of the `Memory` class called `sync` to connection our local and remote stores. Instanating a `Sync` instance is a simple way of telling our local store, "whenever our remote store hears a change, we want our local store to also hear about the change." We create a new `Sync` like this: 

```javascript
const sync = local.sync(remote)
```

In Riptide, changes to our data come in the form of `Mutations`. `Mutations` are simple objects that explain how data should change. Whenver our remote store handles an incoming `Mutation`, our `Memory` store will also hear of the change. We can use our local store's `onChange` function to listen for any incoming `Mutations`. We can log the triggering `Mutation` and the entire local store on a change: 

```javascript
local.onChange.add(mut => {
    console.dir('Mutation', mut)
    console.dir('Local', local.query_path([]))
})
```

In addition to data from the remote server, there's other data we might want to store in Memory alone and not write to our database. An example that our application might depend on is information about our `Websocket` connection. Using the connection's `transport` property we discussed earlier, we can attach a listener that will listen for changes in the Websocket's connection and save that information in memory like this:

```javascript
connection.transport.onStatus.add(status => 
    local.merge(['connection', 'status'], status)
)
```

In addition to the `onChange` function, the `Memory` store includes an `interceptor` property that provides helpful functions for dealing with incoming merges. One of these functions is the `before_mutation` function, which listens for an incoming `Mutation` that is writing under a specific path. In the `before_mutation` callback, we can expect the `Mutation` and decide to take action before that is merged into `Memory`. 

In the previous step we told our local store to merge in our connection status to the remote server whenever it changes. We can now use the `interceptor` interface to listen for that merge to happen, and take some action: 

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

To review, we're now listening for our `Connection` instance to say "I've connection to the remote server successfully." When that happens, we know we can now use our `Remote` store to query some data from the server. In this case we tell the `Remote` store we want everything under the `['todos']` path on our server. We also pass in an optional argument, `{subscribe: true}`. This tells our server that we want our `Remote` store to be notified about changes under this path. 

Since we set up our `Sync` instance previously, we know that any changes that our `Remote` store hears, our `Memory` store will also hear about. Now if any data changes on our remote server, the following flow will trigger:

```
1. Data is written under the `todos` path on our remote server. 
2. Our remote server sees if there are any subscriptions to this path. Since we passed in the `{subscribe: true}` options when querying `todos`, this is true. 
3. The `Remote` store recieves the `Mutation` responsible for the write. 
4. The `Sync` passes this information to our `Memory` store. 
5. Our `Memory` checks if there are any `before_mutation` interceptors listening for the `todos` path. We set up a `before_mutation` interceptor, but it was listening to the `connection` path, so nothing is yet triggered. 
6. Our `Memory` store writes the `Mutation` to its state. 
7. Detecting that our `Memory` state has changed, our `local.onChange` functions fire, and we see the `Mutation` logged as well as the newly updated `Memory` state. 
```