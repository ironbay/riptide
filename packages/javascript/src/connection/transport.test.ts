import * as Connection from '.'

describe('connection', () => {
    it('client', async done => {
        const conn = Connection.create()
        await conn.transport.connect('wss://echo.websocket.org')
        conn.on_cast.add(msg => {
            expect(msg).toEqual({ action: 'test', body: 'hello', type: 'cast' })
            done()
        })
        conn.cast('test', 'hello')
    })
})
