import React from 'react'
import ReactMarkdown from 'react-markdown'
import { Link } from 'react-router-dom'
import Highlight from 'react-highlight'

interface Props {
    code: string
}
export default function Markdown(props: Props) {
    return (
        <div >
            <ReactMarkdown
                escapeHtml={false}
                renderers={{
                    list: props => {
                        const p = {
                            className: 'leading-relaxed mb-6 text-gray-700 pl-4',
                            style: { listStyle: 'inside' }
                        }
                        if (props.ordered)
                            return <ol {...p}>{props.children}</ol>
                        return <ul {...p}>{props.children}</ul>
                    },
                    code: props => {
                        return (
                            <div className="font-mono text-sm leading-relaxed rounded-md overflow-hidden p-2 mb-6" style={{ background: '#282c34' }}>
                                <Highlight
                                    className={props.language}
                                >
                                    {props.value}
                                </Highlight>
                            </div>
                        )
                    },
                    link: props => {
                        const classes = "text-blue-600 underline font-500 hover:text-blue-800 transition-all duration-300"
                        if (props.href.includes('://'))
                            return <a {...props} className={classes} />
                        return <Link to={props.href} className={classes} >{props.children}
                        </Link>
                    },
                    thematicBreak: props => {
                        return <hr className="my-12" {...props} />
                    },
                    heading: props => {
                        switch (props.level) {
                            case 1:
                                return <h1 className="text-3xl font-200 tracking-wide text-gray-700 mb-6" {...props} />
                            case 2:
                                return <h2 className="text-2xl mb-6 font-500" {...props} />

                        }

                    },
                    paragraph: props => <p className="leading-relaxed text-gray-700 mb-6" {...props} />
                }}
            >
                {props.code}
            </ReactMarkdown>
        </div>
    )
}