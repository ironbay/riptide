import React from "react"
import { useRouter } from "next/router"
import Link from "next/link"

export default function Sidebar() {
  return (
    <div className="overflow-y-visible w-1/5">
      <div className="scrolling-touch h-auto relative sticky top-0">
        <div
          style={{
            backgroundImage:
              "linear-gradient(rgba(255,255,255,1), rgba(255,255,255,0))",
          }}
          className="h-16 pointer-events-none absolute inset-x-0 z-10"
        />
        <div className="h-screen overflow-y-scroll pt-12 text-gray-600">
          <Header>Getting Started</Header>
          <Doc href="/">Overview</Doc>
          <Doc href="/docs/[...doc]" as="/docs/setup">
            Setup
          </Doc>
          <Doc href="/docs/[...doc]" as="/docs/inspiration">
            Inspiration
          </Doc>
          <Doc href="/docs/[...doc]" as="/docs/caveats">
            Caveats
          </Doc>

          <div className="h-12" />
          <Header>Core Concepts</Header>
          <Doc href="/quick-start">Mutations</Doc>
          <Doc href="/quick-start">Queries</Doc>
          <Doc href="/docs/interceptors">Interceptors</Doc>
          <Doc href="/docs/handlers">Handlers</Doc>

          <div className="h-12" />
          <Header>Stores</Header>
          <Doc href="/quick-start">Overview</Doc>
          <Doc href="/quick-start">Memory</Doc>
          <Doc href="/quick-start">LMDB</Doc>
          <Doc href="/quick-start">Postgres</Doc>

          <div className="h-12" />
          <Header>Frontends</Header>
          <Doc href="/docs/[..doc]" as="/docs/javascript">
            Javascript
          </Doc>
          <Doc href="/quick-start">React</Doc>
        </div>
      </div>
    </div>
  )
}

function Header(props) {
  return (
    <div className="font-600 tracking-wider text-sm uppercase">
      {props.children}
    </div>
  )
}

function Doc(props) {
  const router = useRouter()
  const active = router.asPath === (props.as || props.href)
  return (
    <div className="mt-4">
      <Link {...props}>
        <a
          className={`duration-200 transition-all text-sm font-500 hover:text-black ${
            active && "text-blue-500"
          }`}
        >
          {props.children}
        </a>
      </Link>
    </div>
  )
}
