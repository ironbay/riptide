import './index.css'
import './highlight.css'
import React from 'react'
import * as ReactDOM from 'react-dom'
// import { local } from '/data/riptide'
import { useLocation } from 'react-router'
import {
    BrowserRouter as Router,
    Switch,
    Route,
    Link
} from 'react-router-dom'

import Overview from '/pages/overview'
import Doc from '/pages/doc'

function App() {
    // Tell React to rerender the application when there's a change to the local store
    // const [_, render] = React.useState(0)
    // React.useEffect(() => local.onChange.add(() => render(val => val + 1)), [])

    return (
        <Router>
            <ScrollTop />
            <div className="font-poppins leading-none">
                <Switch>
                    <Route exact path="/" component={Overview} />
                    {
                        [
                            [
                                '/inspiration',
                                require('bundle-text:/markdown/inspiration.md')
                            ],
                            [
                                '/javascript',
                                require('bundle-text:/markdown/javascript.md')
                            ]
                        ]
                            .map(([route, md]) => (
                                <Route
                                    exact
                                    path={route}
                                    component={() => <Doc markdown={md} />} />

                            ))
                    }
                </Switch>
            </div>
        </Router>
    )
}

function ScrollTop() {
    const { pathname } = useLocation()
    React.useEffect(() => window.scrollTo(0, 0), [pathname])
    return null
}

const root = document.querySelector('.root')
const fun = root.hasChildNodes() ? ReactDOM.hydrate : ReactDOM.render
fun(<App />, root)