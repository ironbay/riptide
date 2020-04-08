import React from 'react'
import Link from 'next/link'

export default function Header() {
    return (
        <div className="flex items-center ">
            <Link href="/">
                <a>
                    <div className="flex items-center">
                        <div style={{ width: 40 }}>
                            <img src="/img/logo.svg" />
                        </div>
                        <div className="ml-6 font-500 text-2xl opacity-75">Riptide</div>
                    </div>
                </a>
            </Link>
            <div className="flex-grow" />
            <div className="flex">
                {
                    [
                        ['/img/icons/dark/github.svg', 'https://github.com/ironbay/riptide-next']
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
    )
}