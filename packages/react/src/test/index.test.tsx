import { useRiptide } from "../index"
import * as Riptide from "@ironbay/riptide"
import React from "react"
import { act } from "react-dom/test-utils"
import ReactDOM from "react-dom"

const App = props => {
  const { local } = props
  const [count, setCount] = React.useState(1)
  useRiptide(local)

  return <div className="count">{local.query_path(["count"])}</div>
}

test("use Riptide updates DOM", async () => {
  const local = new Riptide.Store.Memory()
  let container = document.createElement("div")
  document.body.appendChild(container)

  await act(async () => {
    ReactDOM.render(<App local={local} />, container)
  })

  await act(async () => {
    await local.merge(["count"], 1)
  })

  const count = document.querySelector(".count")
  expect(count.textContent).toEqual("1")
})
