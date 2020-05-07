import * as React from "react"
import * as Riptide from "@ironbay/riptide"

export function useRiptide(local: Riptide.Store.Memory) {
  const [num, render] = React.useState(0)

  React.useEffect(() => {
    local.onChange.add(() => render(num + 1))
  })
}
