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
        result.map(item => item(val => val + 1))
      })
    })
  }, [props.store])

  return (
    <RiptideStoreContext.Provider value={props.store}>
      {props.children}
    </RiptideStoreContext.Provider>
  )
}

export function useRiptidePath(path: string[]) {
  const [_, render] = React.useState(0)
  const path_full = [...path, this]
  Dynamic.put(subs, path_full, render)
  const store = React.useContext(RiptideStoreContext)
  return store.query_path(path)
}
