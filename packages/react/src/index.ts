import * as React from "react"

export function useRiptide(local) {
  const [num, render] = React.useState(0)

  React.useEffect(() => {
    local.onChange.add(() => render(num + 1))
  }, [])
}
