import { useRiptide, useRiptidePath, RiptideStoreProvider } from "./index"
import * as Riptide from "@ironbay/riptide"
import React from "react"
import { act } from "react-dom/test-utils"
import ReactDOM from "react-dom"

function App() {
  return (
    <div className="root">
      <Child />
    </div>
  )
}

function Child() {
  const [count, ref] = useRiptidePath(["count"])

  return (
    <div ref={ref} className="count">
      {count}
    </div>
  )
}

test("useRiptide updates DOM", async () => {
  const local = new Riptide.Store.Memory()

  let container = document.createElement("div")
  document.body.appendChild(container)

  await act(async () => {
    ReactDOM.render(
      <RiptideStoreProvider store={local}>
        <App />
      </RiptideStoreProvider>,
      container
    )
  })

  await act(async () => {
    await local.merge(["count"], 100)
  })

  {
    const count = document.querySelector(".count")
    expect(count.textContent).toEqual("100")
  }

  await act(async () => {
    await local.merge(["count"], 1000)
  })

  {
    const count = document.querySelector(".count")
    expect(count.textContent).toEqual("1000")
  }
})
