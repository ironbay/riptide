import "./example"
import * as React from "react"
import * as Riptide from "@ironbay/riptide"
import Dynamic from "@ironbay/dynamic"

export function useRiptide(local: Riptide.Store.Memory) {
  const [, render] = React.useState(0)

  React.useEffect(() => {
    function trigger() {
      render(val => val + 1)
    }
    local.onChange.add(trigger)
    return function() {
      local.onChange.remove(trigger)
    }
  }, [])
}

const RiptideStoreContext = React.createContext(null as Riptide.Store.Local)

const subs = {}

export function RiptideStoreProvider(props: {
  store: Riptide.Store.Local
  children: any
}) {
  React.useEffect(() => {
    props.store.onChange.add(mut => {
      Dynamic.flatten(mut.merge).map(layer => {
        const result = Dynamic.get_values<any>(subs, layer.path)
        result.map(render => render())
      })
    })
  }, [props.store])

  return (
    <RiptideStoreContext.Provider value={props.store}>
      {props.children}
    </RiptideStoreContext.Provider>
  )
}

export function useRiptideContext() {
  // Ref might not even be needed if you store subs as an array of render funcs under a path
  const ref = React.useRef()
  const store = React.useContext(RiptideStoreContext)
  const [_, render] = React.useState(0)

  // TODO: Delete old subs

  return function(path: string[]) {
    const path_full = [...path, ref]
    Dynamic.put(subs, path_full, () => render(v => v + 1))
    return store.query_path(path)
  }
}
