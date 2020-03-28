import * as Transport from './transport'
import * as Format from './format'
import Client from './client'

function create() {
    return new Client(Transport.WS, Format.Json)
}

export {
    Transport,
    Client,
    Format,
    create
}