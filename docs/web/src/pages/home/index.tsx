import React from 'react'

export default function Home() {
    return (
        <div>
            <div className="bg-gray-100 flex justify-center">
                <div className="w-full max-w-screen-xl ">
                    <div className="py-4" />
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
                    <div className="py-6" />
                    <div className="flex items-center">
                        <div>
                            <div className="text-3xl font-300 tracking-wide leading-snug">
                                <div>A data first framework for</div>
                                <div className="text-blue-500 font-400">building realtime applications</div>
                            </div>
                            <div className="mt-6 text-lg leading-relaxed text-gray-600">
                                Riptide makes building snappy, realtime applications a breeze by letting you think purely in terms of your data and functionally about what should happen when it changes.
                                <br />
                                <br />
                                Break down complex business logic into simple rules and push changes across clients automatically.
                            </div>
                        </div>
                        <div className="p-8" />
                        <div className="flex-shrink-0">
                            <img width={700} src={require('url:./carbon.svg')} />
                        </div>
                    </div>
                    <div className="py-6" />
                </div>
            </div>
        </div>
    )
}