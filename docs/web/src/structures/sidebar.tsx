import React from 'react'
import { NavLink } from 'react-router-dom'

export default function Sidebar() {
    return (
        <div className="overflow-y-visible w-1/5">
            <div className="scrolling-touch h-auto relative sticky top-0">
                <div style={{ backgroundImage: 'linear-gradient(rgba(255,255,255,1), rgba(255,255,255,0))' }} className="h-16 pointer-events-none absolute inset-x-0 z-10" />
                <div className="h-screen overflow-y-scroll pt-12 text-gray-600">
                    <Header>Getting Started</Header>
                    <Link to="/">Overview</Link>
                    <Link to="/setup">Setup</Link>
                    <Link to="/inspiration">Inspiration</Link>
                    <Link to="/caveats">Caveats</Link>

                    <div className="h-12" />
                    <Header>Core Concepts</Header>
                    <Link to="/quick-start">Mutations</Link>
                    <Link to="/quick-start">Queries</Link>
                    <Link to="/quick-start">Interceptors</Link>
                    <Link to="/quick-start">Commands</Link>

                    <div className="h-12" />
                    <Header>Stores</Header>
                    <Link to="/quick-start">Overview</Link>
                    <Link to="/quick-start">Memory</Link>
                    <Link to="/quick-start">LMDB</Link>
                    <Link to="/quick-start">Postgres</Link>

                    <div className="h-12" />
                    <Header>Frontends</Header>
                    <Link to="/quick-start">Javascript</Link>
                    <Link to="/quick-start">React</Link>
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

function Link(props) {
    return (
        <div className="mt-4">
            <NavLink {...props} activeClassName="text-blue-600" className="duration-200 transition-all text-sm font-500 hover:text-black" />
        </div>
    )
}