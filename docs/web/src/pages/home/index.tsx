import React from 'react'
import Sidebar from '/structures/sidebar'
import ReactMarkdown from 'react-markdown'


export default function Home() {
    return (
        <div>
            <div className="bg-gray-100 flex justify-center">
                <div className="w-full max-w-screen-xl px-6">
                    <div className="h-8" />
                    <div className="flex items-center ">
                        <div style={{ width: 40 }}>
                            <img src={require('url:/assets/logo.svg')} />
                        </div>
                        <div className="ml-6 font-500 text-2xl opacity-75">Riptide</div>
                        <div className="flex-grow" />
                        <div className="flex">
                            {
                                [
                                    [require('url:/assets/icons/dark/github.svg'), 'https://github.com/ironbay/riptide-next']
                                ]
                                    .map(([icon, url]) => {
                                        return (
                                            <a href={url} target="_blank" className="transition-all duration-200 opacity-50 cursor-pointer hover:opacity-100">
                                                <img src={icon} />
                                            </a>
                                        )
                                    })
                            }
                        </div>
                    </div>
                    <div className="h-12" />
                    <div className="flex items-center">
                        <div>
                            <div className="text-3xl font-300 tracking-wide leading-snug">
                                <div>A data first framework for</div>
                                <div className="text-blue-500 font-400">building realtime applications</div>
                            </div>
                            <div className="mt-6 text-lg leading-relaxed text-gray-600">
                                Riptide makes building snappy, realtime applications a breeze by letting you think purely in terms of your data and functionally about what should happen when it changes.
                            </div>
                        </div>
                        <div className="p-8" />
                        <div className="flex-shrink-0">
                            <img width={650} src={require('url:./carbon.svg')} />
                        </div>
                    </div>
                    <div className="h-12" />
                </div>
            </div>
            <div className="bg-gray-100 h-16" style={{ background: 'linear-gradient(to bottom, #f7fafc 0%,#ffffff 100%)' }} />
            <div className="flex justify-center">
                <div className="w-full max-w-screen-xl px-6 flex ">
                    <Sidebar />

                    <div className="min-h-screen w-full lg:static lg:max-h-full lg:overflow-visible lg:w-3/4 xl:w-4/5 p-12">
                        <div >
                            <ReactMarkdown
                                escapeHtml={false}
                                renderers={{
                                    heading: props => {
                                        if (props.level === 1)
                                            return <h1 className="text-3xl font-200 tracking-wide text-gray-700 mb-6" {...props} />
                                    },
                                    paragraph: props => <p className="leading-relaxed text-gray-700 mb-6" {...props} />
                                }}
                            >
                                {require('bundle-text:/markdown/overview.md')}
                            </ReactMarkdown>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

function Title(props) {
    return <div className="text-3xl font-200 tracking-wide text-gray-700" {...props} />
}

function Paragraph(props) {
    return <div className="leading-relaxed text-gray-700" {...props} />
}