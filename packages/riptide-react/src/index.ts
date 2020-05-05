import React from "react"

export default function hook(local) {
  const [_, render] = React.useState(0)

  React.useEffect(() => {
    local.onChange.add(() => render())
  }, [])
}
