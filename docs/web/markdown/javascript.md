# Javascript Setup

A guide for setting up Riptide on the front-end. 
*** 

Getting up and running with Riptide on the front-end is simple and straight-forward. In this guide we'll go through the steps of installing Riptide, connecting to our data stores, and getting started with Riptide's core features. 

<!--  -->
### 1. Install Riptide via npm

```javascript
# Using npm 
npm install @ironbay/riptide

# Using yarn 
yard add @ironbay/riptide
```

### 2. Create a riptide.js file

While not strictly necessary, we reccomend isolating Riptide's setup in its own file. Let's import all of Riptide at the top of `riptide.js`. 

```javascript
// riptide.js

import * as Riptide from '@ironbay/riptide'
```


### 3. Connect to the remote server

We'll use Riptide's `Connection` to connect to our remote server. We'll create a new `Connection` instance, and then use it's `transport` field to connection on port `12000` at the `/socket` endpoint:

Make sure your back end is running and then add: 

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')
```


### 4. Create a remote store

Our remote store is how we interact with data on our remote server. We'll instantiate a new Remote store, using the connection we just created: 

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)
```

That's it! Our remote store is now up and running. We can now use our remote store to interact with the remote server: 

```javacsript
const todos = await remote.query_path(['todos'])
const deleted = await remote.delete(['todos'])
```

You might notice that calling functions using our remote store returns functions. That's because our requests are going over the network to interact with our data. Let's store some of this data in-memory so that we don't have to rely solely on promises. 

### 5. Create a local store

Riptide has a `Memory` class that allows us to hold our data in-memory on the front-end. We can store whatever we want in our local store: session specific information, information we fetch from remote, etc. In the next steps we'll show you how to do both. Let's create a new in-memory local store: 

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)

const local = new Riptide.Store.Memory()
```

You can check that your local store is working by running some simple writes and reads on it: 

```javascript
local.merge(['todos'], {name: 'i am a todo!'})

local.query_path(['todos'])
// {todos: {name: 'i am a todo!'}
```



### 6. Sync our local store 

When you want to change data in Riptide, you do so through Mutations. Mutations are a simple way of describing how you want your data to change. 

When ou


When data changes in our application, our remote store will hear about those data transformations in the form of Mutations. In this example, we want to make sure our local store hears about those Mutations as well. 

Sync this two stores takes on line. We'll call our local store's `sync` function, passing in our remote store as an argument: 

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)

const local = new Riptide.Store.Memory()

const sync = local.sync(remote)
```

Notice how we saved the result of calling `local.sync(remote)` as a variable called `sync`. That's because `local.sync(remote)` returns a sync object. We'll see in a minute how `sync` can make our lives easier. 

### 7. Listen for changes to our local store 

We can test that our local store is recieiving Mutations from our remote store by adding a listener to our local store. Whenever our local store receives a mutations, we'll print the mutation and the entire local store: 

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

### 8. Print the connection status 

The `transport` property of our connection instance has an `onStatus` field that we can pass callbacks to. Anytime the status of our connection changes, the callbacks will get called. 

Let's add a callback that takes the connection status and saves it only to our local store: 

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

### 9. Make initial queries 

Now that we're saving the connection status to our local store, we can use an Interceptor to listen for the status changing. A common practice is to listen for a 'ready' status and make some initial queries for our application. 

In this example we'll query all of the todos from the remote store when the connection becomes ready. We'll pass in a `{subscribe: true}` option with the query, telling our remote server that we want our remote store to be kept up to date with any transformations happening under the `todos` path: 

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

Since we synced our stores previously, subscribing to the `todos` path means that our local store will also hear any `todo` transformations taking place. 

### 10. Export

The final step is to export our connection, sync object, and two stores. To understand how we use these tools in our front-ends, check out our our front-end frameworks guides. 

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

export { connection, remote, local, sync }
```




<!--  -->
<!--  -->
<!-- how do i set up riptide on the front end  -->
<!-- how do i configure it? -->
<!-- flexibility -->

<!-- minimal set up  -->
<!-- allows for a ton of flexibility -->
<!-- removes a lot of details -->