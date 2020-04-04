import './index.css'
import React from 'react'
import * as ReactDOM from 'react-dom'
import { local } from '/data/riptide'
import {
    BrowserRouter as Router,
    Switch,
    Route,
    Link
} from 'react-router-dom'

import Overview from './pages/overview'

function App() {
    // Tell React to rerender the application when there's a change to the local store
    const [_, render] = React.useState(0)
    React.useEffect(() => local.onChange.add(() => render(val => val + 1)), [])
    return (
        <Router>
            <div className="font-poppins leading-none">
                <Switch>
                    <Route exact path="/" component={Overview} />
                </Switch>
            </div>
        </Router>
    )
}

const root = document.querySelector('.root')
const fun = root.hasChildNodes() ? ReactDOM.hydrate : ReactDOM.render
fun(<App />, root)