import { useRiptide } from "../index"
import * as Riptide from "@ironbay/riptide"
import test_renderer from "react-test-renderer"
import App from "./app"
import React from "react"

function Link(props) {
  return <a href={props.page}>{props.children}</a>
}

const testRenderer = test_renderer.create(
  <Link page="https://google.com">Google</Link>
)

test("it works", () => {
  expect(1).toBe(2)
})

console.log(testRenderer.toJSON())
expect(1).toBe(1)
