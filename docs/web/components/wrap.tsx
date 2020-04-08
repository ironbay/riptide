import React from 'react'

export default function Wrap(props) {
    return (
        <div className="flex justify-center">
            <div className="w-full max-w-screen-xl px-6" >
                {props.children}
            </div>
        </div>
    )
}