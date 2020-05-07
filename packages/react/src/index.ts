import * as React from "react"
import * as Riptide from "@ironbay/riptide"

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
