import React from 'react'
import ReactMarkdown from 'react-markdown'
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
                    code: props => {
                        return (
                            <div className="font-mono text-sm leading-snug rounded-md overflow-hidden p-2 mb-6" style={{ background: '#282c34' }}>
                                <Highlight
                                    className={props.language}
                                >
                                    {props.value}
                                </Highlight>
                            </div>
                        )
                    },
                    link: props => {
                        return <a {...props} className="text-blue-600 underline font-500" />
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
                {require('bundle-text:/markdown/overview.md')}
            </ReactMarkdown>
        </div>
    )
}