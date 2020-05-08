import * as React from "react"
import * as Riptide from "@ironbay/riptide"

const RiptideContext = React.createContext(null as Riptide.Store.Local)

function Root() {
  return (
    <RiptideContext.Provider value={new Riptide.Store.Memory()}>
      <div>
        <Child />
      </div>
    </RiptideContext.Provider>
  )
}

function Child(props) {
  const store = React.useContext(RiptideContext)
  return (
    <div>
      <SubChild />
    </div>
  )
}

function SubChild(props) {
  const store = React.useContext(RiptideContext)
  return <div>Hi I'm a child</div>
}
