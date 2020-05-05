import React from "react"

function useHook(local) {
  const [num, render] = React.useState(0)

  React.useEffect(() => {
    local.onChange.add(() => render(num + 1))
  }, [])

  console.dir("uh....realy?!?!?!?!")
}

export { useHook }
