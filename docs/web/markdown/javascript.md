# Javascript Setup

A guide for setting up Riptide on the front-end. 
*** 

In this guide we'll run through setting up `Riptide` on the front-end. Here are the steps we'll take: 

- Installing and importing `Riptide`
- Setting up a `remote` store for interacting with data on our remote server
- Setting up a `local`, in-memory store for immediate access to data
- Creating a `connection` instance to the remote server
- Syncing our two stores to ensure their data is consistent
- Using `onChange` and `interceptors` to take actions according to data transformations

<!--  -->
### 1. Install Riptide via npm

Let's start by installing Riptide via npm. 

```javascript
# Using npm 
npm install @ironbay/riptide

# Using yarn 
yard add @ironbay/riptide
```

### Create a riptide.js file

While this step isn't stictly necessary, we reccomend dedicating your `Riptide` setup its own file. As the complexity of your application grows, you might want to add further configuration here. An example configuration might entail fetching different data based off session-specific information like user's permissions. For now let's create a `riptide.js` file and import the `Riptide` library that we just installed: 


```javascript
// riptide.js

import * as Riptide from '@ironbay/riptide'
```

### Connect to the remote server

As we mentioned previously, we'll want to set up a remote store to interact with data on our remote server. The remote store itself is a client that exposes basic ready and write operations and more advanced helper functions. Before we instantiate a remote store, we have to create a connection to the remote server that the remote store can use. 

We create this connection via the `Riptide.Connection` class. This interface is where we'll handle all things connection related, including creating the connection, listening for connection status updates, etc. 

Let's instantiate a `Connection` interface with `Riptide.Connection.create()`, and then use the class to start a connection using the `transport.connect(url)` function, connection tjj the websocket url `ws://localhost:12000/socket`. 

Make sure your back-end is running and then add: 

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')
```

### Create a remote store

Great, now our connection is up and running and it's time to instantiate a remote store that will use this connection, allowing us to access data on the server. 

We'll create a remote store instance by calling `new Riptide.Store.Remote(connection)`, passing in the connection we previously created to the constructor. 

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)
```

That's it! Our remote store is connected to the back-end. Later in this guide we'll explain how to ensure the connection is ready before trying to interact with data on the server. But for now, here's a taste of what using the remote server will look like: 

```javascript
// app.js 

const merged = await remote.merge(['todos', 'todos_01'])
const deleted = await remote.delete(['todos'])

this.remote.onChange.add(mut => 
    console.dir('*** New Mutation ***')
    console.dir(mut)
)
```

Whenever we interact with data using our remote store, we're going over a network, and therefore these functions (here `query_path` and `delete`) return `Promises`. Next we'll create a local store where we can interact with data that's in-memory without having to reply on `Promises`. 

### Create a local store

Riptide has a `Memory` class that allows us to hold our data in-memory on the front-end. We can store whatever we want to use immediately in our local store. Most commonly, this is a mix of data imported from our `remote` store and session specific information server connection status, UI filtering settings, etc. 

In later steps we'll go over how to get data from our `remote` store into our `local` store. For now let's create a new store by calling `new Riptide.Store.Memory()`:

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)

const local = new Riptide.Store.Memory()
```

You'll notice that for the local store we didn't have to pass in any arguments to the constructor. This store's state is in a simple object that we can access instantly; no connection needed. You can see below how the remote and local stores have similar interfaces for interacting with data (one difference being local doesn't use `Promises`): 

```javascript
// app.js 

local.merge(['todos'], {name: 'i am a todo!'})
local.delete(['todos'])
```

### 6. Sync the local store 

With our local store we can now access data instantly. When we want to display data from our server on our front-end, we'll want to query that data with the remote store and then save it to the local store for instant access. Since this is such a common pattern, our local store ships with a `sync` function that allows a seamless coordination between the two stores. 

The functionality of calling `local.sync(remote)` is very simple: it ensures that any data transformations (mutations) that reach our remote store will also reach our local store. For example: 

- If we call a `remote.query(['todos'])`, both our local and remote stores will store the result of the query. 
- If we call a `remote.delete(['todos', 'todo_01'])`, our local store will recievie a mutation, describing that `todo_01` was deleted and update accordingly. 

Insantiation a sync by calling `local.sync(remote)` initiates the above functionality. A sync instance is returned from calling `local.sync(remote)` that also has it's own functionality. To give you a preview of what this looks like: 

```javascript
const sync = local.sync(remote)
sync.merge(['todos', 'todo_01'])
sync.delete(['todos', 'todo_01'])
```

The `merge` and `delete` function look eerily similar to the `merge` and `delete` functions we saw on the local and remote stores, is sync its own store? The sync objects provied a helpful interface for interact with our local and remote stores at once. 

We use the sync object to perform [optimistic updates](https://stackoverflow.com/questions/33009657/what-is-optimistic-updates-in-front-end-development). If we want to have our UI update instantly (rather than waiting for the back-end to confirm that a user action was successful), we call `sync.merge` or `sync.delete` and both stores get written to. 

For this guides purposes, we'll be satisfied creating the sync to ensure that our remote and local stores are recieving the same information. We'll export the sync object at the end of this guide for use in our application's components. 

Let's instantiate a sync:

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)

const local = new Riptide.Store.Memory()

const sync = local.sync(remote)
```

### Query and subscribe to data 

Let's recap our setup so far. We've connected our remote store to the remote server with the connection we initiated. We created a local store and then synced it with our remote store. Now whenever remote recieves information, that info will be passed onto our local store. 

Since `Riptide` was built with real-time applications in-mind, we want to ensure that our remote store is kept up-to-date with the latest information from our remote server. 

Using our todos example, imagine that we initially call a `remote.query(['todos'])` in our application. The remote store will recieive any todos and pass those along to our local store. So good so far. 

But what happens if another todo is added to our back-end? This could come from anywhere: another user's actions, an external API, a data migration, etc. We might want to create a polling system to requery todos every x seconds. But what if we need to subscribe to more than just todos? Rewriting a polling function for each path of data would quickly become cumbersome. We could also write a polling system to query ALL of our server data, `remote.query([])`, but loading all of our back-end data into our in-memory store is clearly not the best option. 

To solve this issue, `Riptide` ships with an optional `{subscribe: true}` parameter when calling `remote.query()`. This option tells our back-end that we want to be notified of any updates happening under the path we're querying. For example: 

```javascript
await remote.query({
    'todos': {
        subscribe: true
    }
})
```
This is telling our back-end two things: 

- Query for all the todos and return them
- Notify our remote store of and updates happening under the todos path

So far we've used the word "notify" to describe when parts of our system are speaking to each other. `Riptide` uses the concept of mutations to speak across components. Mutations are a simple description of how our data is being transformed in the form of an object, for example: 

```javascript
{
    merge: {
        todos: {
            todo_01: {
                user: 'Alan' 
            }
        }
    }, 
    delete: {}
}
```

This mutation alters the user's name under the path: `['todos', 'todo_01', 'user']`. If we were subscribed to this path, the following data flow would take place: 

- back-end recieves mutation 
- data transformation occurs 
- back-end looks for any subscriptions on the todos path
- since remote is subscribe to this path, it broadcasts the mutation 
- the remote store recieves the mutation and forwards to our local store (since they're synced)
- our local store updates it's state accordingly


### Listen for changes to our local store 

We mentioned previously that our stores are capable of more than data querying and transformation functions. One of these helpful functions is the `onChange.add` function, which allows us to pass in callbacks which will be called anytime that our store recieves a mutation. 

A common pattern is to add an `onChange` callback to our local store that prints the incoming mutation and entire local state. Doing so makes it easy to track the local state and find bugs. 

We add that callback like this:

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)

const local = new Riptide.Store.Memory()

const sync = local.sync(remote)

local.onChange.add(mut => {
    console.dir(mut)
    console.dir(local.query_path([]))
})
```

Great! Now anytime a mutation comes into our `local` store, we'll hear about it. We can inspect the incoming mutations to our local store and how these mutations are affecting our local state. 

### Putting it all together 

So far we've outlined how to set up the invididual components in our `Riptide` system. Now we'll explain a common pattern for assembling the components which ensures that all of our components are up and running before they try to interact with each other. 

Here are the basic steps that we'll cover in this section: 

- Listen for a server connection status update
- Whenever our connection status updates, save this information to our local store 
- Attach a listener to our local store that listens for the connection status being updated
- Inside this listener, if our connection status is "ready", query the remote server using our remote store and pass in the subscription parameter

That might be a lot to digest at once, so let's just focus on the first task, listening for the connection status update. 

As we explained earlier, the connection interface that we instantiated comes with some helpful functions. One of these is the `transport.onStatus.add()` function, which allows us to add callbacks which will run whenever the connection status updates. This way we can add a callback that will merge the connection status to our local store whenever the connection status updates. 

Let's add the callback: 

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)

const local = new Riptide.Store.Memory()

const sync = local.sync(remote)

local.onChange.add(mut => {
    console.dir(mut)
    console.dir(local.query_path([]))
})

connection.transport.onStatus.add(status => {
    local.merge(['connection', 'status'], status)
})
```

Great! Now whenever our connection to the remote server changes, our local store will save that information. Now we want to listen for an incoming mutation to our local store that says our server status connection is ready. Remember the `onChange.add` functionality that we used to print our local store's state? What if we tried to use that?

```javascript
local.onChange.add(mut => {
    if (
        mut.merge.connection && 
        mut.merge.connection.status && 
        mut.merge.connection.status === "ready"
    ) {
        // make the subscription query
    }
})
```

Hmm, this seems a little cumbersome. The `onChange.add` was a good option for logging the entire state, but having to filter each incoming mutation seems like a bit much. Is there a function that will allow us some more granularity?


`Riptide` uses an interceptor system for this exact purpose. Interceptors listen for incoming mutations, under a certain path, and allow us take an action according to the incoming mutation. In this case, we want to inspect the incoming connection status, and only query the back-end with our remote store if the connection has a ready status. 

We saw earier how we're saving the connection status under the `['connection', 'status']` path in our local store. So for our interceptor, we'll pass in this path and a callback function that checks the connection status, and either returns immediately or carries out our remote query and subscription based on the connection status. 

The implementation is simple and straightforward: 


```javascript
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
    console.dir(mut)
    console.dir(local.query_path([]))
})

// When the connection status changes, save the state just to the local store
connection.transport.onStatus.add(status => {
    local.merge(['connection', 'status'], status)
})

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
```

That's it! No we simply wait for an incoming mutation to our local store where `mut.merge.status === 'ready'`. To recap this portion, here's what's happening: 

- We instantiate a connection to the remote server 
- We add a listener to this connection, which will merge the current status into our local store
- We attach a `interceptor.before_mutation` function to the local store, which will listen for a mutation altering the `['connection']` path
- Inside the interceptor, we check the mutation to see if its returning a ready state. If we so we query for the todos and tell our back-end that we're subscribing to them 


### Export

Now we have several tools are our disposal, ready to interact and display data in our application. We'll export the `connection`, `remote`, `local`, and `sync` objects. This way, any module in our front-end can import whatever parts our our our `Riptide` setup they need, for example: 

```javascript
// app.js

import { local, sync } from './riptide.js'
```

### Recap 

Let's recap our whole setup. 

- First, we installed `Riptide` in our application, created a setup file, and imported `Riptide` into the file.
- Then we set up a `connection` instance to the remote server. We passed in a Websocket url to this constructor. 
- We created a `remote` store, and passed in the connection instance to the constructor. Our remote store will use this connection to interact with our remote server. 
- We created an in-memory `local` store. We learned we can store anything here that we want, including session-specific information, data from our remote server, etc. 
- We synced the stores. This ensure that any mutations that reach our remote store also reach our local store. It also provided us with a sync object so that we can implement optimistic updates by writing to both stores simultaneously. 
- We saw how we can add `onChange` callbacks to our stores. While not providing granularity, this callback is helpful for taking action whenever a mutation reaches our store. 
- We saw how to set up a subscription with our `remote` store. We learned that we do not have to implement any sort of polling: `Riptide` will tell our `remote` store if any changes occur under paths that we're subscribed to. Since our stores were synced, and mutations sent to our `remote` store will also hit our `local` store. 
- We learned that before interacting with data on our remote server, we want to ensure the `connection` is ready. We showed how we can use a listener on the `connection` to notify only our local store when a status change occurs. 
- We then saw how our `interceptors` can listen for changes to our stores (either before or after the write occurs). In our case, we listen for a `connection` status of `ready` being merged, and then make our initial query with a subscription option specified. 

# Next steps 

Now that we've exported our tools, other parts of our application can start to use them. Depending on which framework you're using, there are different ways of ensuring that your application updates according to data transformations. Check out our framework-specific implementations under the `Front ends` tab for guides on the next steps of integration. 
