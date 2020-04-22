# Javascript Setup

A guide for setting up Riptide on the front-end. 
*** 

In this guide we'll show you the basic setup steps for getting Riptide running on the front-end. Here are some of the steps we'll cover: 

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

### 2. Create a riptide.js file

While this step isn't necessary, we highly reccomend dedicating a file to your `Riptide` setup. As your application grows, you might want to extend your setup to account for new developments. For example, you can alter your initial set up based off a end-user's permissions. A detailed explanation is beyond the scope of this guide, so for now let's create the file and import `Riptide.`

```javascript
// riptide.js

import * as Riptide from '@ironbay/riptide'
```

### 3. Connect to the remote server

Before we create any of our stores, we need to connect to the remote server. We'll use `Riptide.Connection` to create a connection interface that we'll use to begin the connection. As we'll see later in the guide, we can also use this interface to listen for changes to our `connection` status and accordingly take actions. 

We call `Riptide.Connection.create()` to create the interface, and then call the instance's `transport.connect()` function, passing in the Websocket url. 

Make sure your back-end is running and then add: 

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')
```

### 4. Create a remote store

Now that we have a `connection` instance, let's create our `remote` store. The `remote` store is how we'll interact with data on our remote server. It also comes with a group of helper functions that let us do things like listen for data transformations.

We'll instantiate a new `remote` store by calling `new Riptide.Store.Remote(connection)`, passing the `connection` we just created to the constructor: 

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)
```

That's it! There's more setup involved to ensure that our connection status is ready before we stary interacing with data on the remote server, but to give you a taste of what using the `remote` store is like, here are some simple examples: 

```javascript
// app.js 

const todos = await remote.query_path(['todos'])
const deleted = await remote.delete(['todos'])
```

You'll notice that when we interact with data via our remote store, our interactions return `Promises`. Since the requests are going over network, we have to wait for the back-end to respond. Next we'll create a local store where we can interact with data that's in-memory without having to reply on `Promises`. 

### 5. Create a local store

Riptide has a `Memory` class that allows us to hold our data in-memory on the front-end. We can store whatever we want to use immediately in our local store. Most commonly, this is a mix of data imported from our `remote` store and session specific information (server connection status, UI filtering settings, etc). 

In later steps we'll go over how to get data from our `remote` store into our `local` store. For now let's create a new store by calling `new Riptide.Store.Memory()`:

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)

const local = new Riptide.Store.Memory()
```

You'll notice that for the `local` store we didn't have to pass in any arguments to the constructor. That's because our local store is all held in-memory, so initially it's state is just an empty object. All reading and writing will happen in-memory and not over any network, so no `connection` instance needed. 

Similar to our remote store, we can interact with data on our `local` store as such:

```javascript
// app.js 

local.merge(['todos'], {name: 'i am a todo!'})

local.query_path(['todos'])
```

### 6. Sync the local store 

Now that we have an in-memory store we can use to render data, how do we get data from our `remote` store to our `local` one? Our `local` store provides us with a `sync` function that we'll use to ensure our data is consistent between the stores. 

The `sync` is at its core very simple: any data transformations that our `remote` store hears about, our `local` store will hear about as well. We can still store additional data in our `local` store that remote doesn't know about. But for any paths that remote recieves transformations for, our `local` store will here about and apply those changes.

The `sync` function not only instantiates this coordination between stores, it acts as it's own interface that allows us to write to both stores simultanesouly. We can perform optimistic updates by immediately writing to both stores upon a user-action. If the action doesn't validate on the back-end, our `remote` and `local` stores will still be kept in sync. The optimistic update will be reversed in the `local` store.


Let's instantiate the `sync` object. We call `local.sync(remote)`, passing in the `remote` instance that we want our `local` store to sync with:


Let's instantiate a `sync`:

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)

const local = new Riptide.Store.Memory()

const sync = local.sync(remote)
```

Awesome, now we know that our `remote` store will pass along any mutations it recieves to our `local` store. We don't have to worry about our data being consistent between stores. 

As we mentioned, the `sync` instance provides its own data transormation functions (similar to those on our local and remote stores). To give you a glimpse of what this looks like:

```javascript
// add this todo to both stores 
sync.merge(['todos'], {task: "clean the fishtank"})

// remore the todo from both stores 
sync.delete(['todos]) 
```

Now that our stores are synced, let's start to explore some of the features of our stores beyond interacting directly with data. 

### 7. Listen for changes to our local store 

It might be nice to print the state of our `local` store. That way we could verify that mutations are being sent from the `remote` store, and we could debug issues by tracing the data flow in our console. 

Our local store comes with a simple `onChange.add` function that allows us to pass in callbacks that get triggered when a mutation reaches our local store. 

The `onChange.add` handler does not provide a ton of granularity, its best for basic tasks like printing the current state, or taking a certain action every a mutation hits our local store. We'll see later in this guide how if we want futher granularity we can use `interceptors`. 

For now let's add the simple callback we described, one that will print the current `local` store. We'll also print the mutation being sent to our `local` store. 

```javascript
// Riptide.js

import * as Riptide from '@ironbay/riptide'

const connection = Riptide.Connection.create()
connection.transport.connect('ws://localhost:12000/socket')

const remote = new Riptide.Store.Remote(connection)

const local = new Riptide.Store.Memory()


local.onChange.add(mut => {
    console.dir(mut)
    console.dir(local.query_path([]))
})
```

Great! Now anytime a mutation comes into our `local` store, we'll hear about it. We can inspect how our data is being told to transform. 

### Start a subscription 
 
Let's recap the data flow we have now. Our back-end recieves a mutation (this could come from anywhere in our application, or from a back-end service, or from polling an API, etc). The back-end will read the path being written to (for example, ["todos", "todo_01"]) and then look if there are any subscriptions to that path. 

A subscription is simply a method our remote server uses to notify a store when a data transformation occurs under a specific path. If the store is subscribed to that path, our back-end will make sure to notify the store. The subscription model is opt-in, so that you can adjust the volume of information reaching your remote store. For high-write applications, subscribing to all of the data on our-back end could quickly become cumbersome. 

For our purposes, we want our remote store to subscribe to the `todos` path. This way, our `remote` and `local` stores (since they're synced) will both be kept up to date with any transformations happening under that path. We don't have to write any polling to check for changes, the subscription model will handle all of that. 

In `Riptide` we initiate subscriptions via a query. This way, we fetch the path initially by manually querying it, but making sure to pass in a `{subscribe: true}` option. If we omit this option, we'll still recieve all the current `todos`, but we won't hear about any future updates automatically. 

Here's what a query that initiates a subscription looks like:

```javascript
await remote.query({
    'todos': {
        subscribe: true
    }
})
```

Now both our stores (remember the sync!) will recieve all the current todos, and be made aware of any updates via mutations. 

Although the above query is straightforward, we have to ensure that our `connection` status is ready before we start querying our `remote` server. In The next step, we'll show you how to ensure that the `connection` is up and running before trying to query and subscribe to data. 

### Putting it all together 

Now that we know how to query and subscribe to our `remote` server, how can we ensure that our `connection` is up and running before trying to access the data? 

As we explained earlier, our `connection` client comes with functions that expose information about our `connection`. Similar to the `local.onChange.add` function, our `connection` comes with a `connection.transport.onStatus.add` callback. We can add and number of callbacks using this function, which will be called any time that our `connection` status updates. 

To start, let's add a listener that will simply listen for a `connection` status update and merge that information into the local store. We'll save it under the `['connection', 'status']` path. Remember, if we want to write to both stores at once, we use the `sync` object. But since a connection status is session-specific, we most likely don't want to save it on our remote server. We'll use a simple to `local.merge` function to save it locally. 


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

Great! Now whenever our `connection` status changes, our `local` store will hear about it. Remember, our goal is to make that subscription query once our `connection` status is ready. One approach might be to use the `local.onChange` callback we saw previously: 

```javascript
local.onChange(mut => {
    if (
        mut.merge.connection && 
        mut.merge.connection.status && 
        mut.merge.connection.status === "ready"
    ) {
        // make the subscription query
    }
})
```

But relying on the `onChange` handler doesn't provide us with a ton of granularity. We can see how we might end up with a huge switch statement, inspecting every merge to see if it's altering a path we care about. 

Luckily, `Riptide` has an `interceptor` functionality that allows us to specify this granularity easily. The `interceptor` framework allows us to specify a path as an argument. We also have both `interceptor.before_mutation` and `interceptor.after_mutation`, if we want to take after before or after a mutation is written. 

In this case, we'll use a `interceptor.before_mutation` to listen for a mutation coming into our local store that is specifying that the `['connection', 'status']` path is being written to. We'll then inspect the mutation to see if has a `ready` status. If not, we simply return (the interceptor will re-run when another status change occurs). If it is ready, we'll make the initial subscription query. 

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

And that's it! When our `connection` is ready, we'll subscribe to the todos path and fetch any initial todos. Our `local` and `remote` stores will subscribe to and further transformations automatically. 

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
