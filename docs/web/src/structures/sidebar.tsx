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
                    <Link to="/quick-start">Quick Start</Link>
                    <Link to="/caveats">Caveats</Link>

                    <div className="h-8" />
                    <Header>Core Concepts</Header>
                    <Link to="/quick-start">Mutations</Link>
                    <Link to="/quick-start">Queries</Link>

                    <div className="h-8" />
                    <Header>Section Three</Header>
                    <Link to="/quick-start">Link 1</Link>
                    <Link to="/quick-start">Link 2</Link>
                    <Link to="/quick-start">Link 3</Link>
                </div>

            </div>
        </div>
    )
}

function Header(props) {
    return (
        <div className="font-500 ">
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