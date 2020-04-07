import React from 'react'
import Sidebar from '../../structures/sidebar'
import Markdown from '../../components/markdown'
import Wrap from '../../components/wrap'
import Header from '../../structures/header'


function Doc(props) {
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
                        <Markdown code={props.source} />
                    </div>
                </div>

            </Wrap>
        </div>
    )
}

Doc.getInitialProps = async (context) => {
    try {
        const result = await require('../../markdown/' + context.query.doc + '.md')
        return { source: result.default }
    } catch (ex) {
        return { source: '' }
    }

}

export default Doc