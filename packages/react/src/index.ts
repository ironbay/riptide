import * as React from "react"
import * as Riptide from "@ironbay/riptide"

export function useRiptide(local: Riptide.Store.Memory) {
  const [, render] = React.useState(0)

  React.useEffect(() => {
    local.onChange.add(val => render(val + 1))
  }, [])
}
