import React from "react"
import { useRouter } from "next/router"
import Link from "next/link"

export default function Sidebar() {
  return (
    <div className="w-1/5 overflow-y-visible">
      <div className="relative sticky top-0 h-auto scrolling-touch">
        <div
          style={{
            backgroundImage:
              "linear-gradient(rgba(255,255,255,1), rgba(255,255,255,0))",
          }}
          className="absolute inset-x-0 z-10 h-16 pointer-events-none"
        />
        <div className="h-screen pt-12 overflow-y-scroll text-gray-600">
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
          <Doc href="/docs/queries">Queries</Doc>
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
    <div className="text-sm tracking-wider uppercase font-600">
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
