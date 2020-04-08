import React from 'react'
import Sidebar from '../structures/sidebar'
import Markdown from '../components/markdown'
import Wrap from '../components/wrap'
import Header from '../structures/header'


export default function Overview() {
    return (
        <div>
            <div className="bg-gray-100">
                <Wrap>
                    <div>
                        <div className="h-8" />
                        <Header />
                        <div className="h-12" />
                        <div className="flex items-center">
                            <div>
                                <div className="text-3xl font-300 tracking-wide leading-snug">
                                    <div>A data first framework for</div>
                                    <div className="text-blue-500 font-400">building realtime Elixir apps</div>
                                </div>
                                <div className="mt-6 text-lg leading-relaxed text-gray-600">
                                    Riptide makes building snappy, realtime applications a breeze by letting you think purely in terms of your data and functionally about what should happen when it changes.
                            </div>
                            </div>
                            <div className="p-8" />
                            <div className="flex-shrink-0">
                                <img width={650} src="/img/carbon.svg" />
                            </div>
                        </div>
                        <div className="h-12" />
                    </div>
                </Wrap>
            </div>
            <div className="bg-gray-100 h-16" style={{ background: 'linear-gradient(to bottom, #f7fafc 0%,#ffffff 100%)' }} />
            <Wrap>
                <div className="flex">
                    <Sidebar />

                    <div className="min-h-screen w-full lg:static lg:max-h-full lg:overflow-visible lg:w-3/4 xl:w-4/5 p-12">
                        <Markdown code={require('../markdown/overview.md').default} />
                    </div>
                </div>

            </Wrap>
        </div>
    )
}
