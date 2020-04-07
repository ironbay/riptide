import React from 'react'
import Sidebar from '/structures/sidebar'
import Markdown from '/components/markdown'
import Wrap from '/components/wrap'
import Header from '/structures/header'
import { useLocation } from 'react-router'
import Routes from '/markdown'



export default function Doc() {
    const location = useLocation()
    const name = location.pathname.substring(1)
    return (
        <div>
            <div className="border-b">
                <Wrap>
                    <div>
                        <div className="h-5" />
                        <Header />
                        <div className="h-5" />
                    </div>
                </Wrap>
            </div>
            <Wrap>
                <div className="flex">
                    <Sidebar />
                    <div className="min-h-screen w-full lg:static lg:max-h-full lg:overflow-visible lg:w-3/4 xl:w-4/5 p-12">
                        <Markdown code={Routes[name]} />
                    </div>
                </div>

            </Wrap>
        </div>
    )
}
