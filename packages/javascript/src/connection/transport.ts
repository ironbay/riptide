import * as WebSocket from 'universal-websocket-client'
import sleep from '../sleep'
import Dispatcher from '../dispatcher'

export abstract class Base implements Riptide.Transport {
    abstract write(data: string): void
    protected dispatcher_data = new Dispatcher<string>()
    handle_data(cb: (data: string) => void) {
        this.dispatcher_data.add(cb)
    }
}

export class WS extends Base {
    public attempts = -1
    private socket: WebSocket;
    public readonly onStatus = new Dispatcher<string>()

    write(data: string) {
        if (!this.socket || this.socket.readyState !== 1) throw 'Socket unready'
        this.socket.send(data)
    }

    async connect(url: string) {
        this.attempts++
        await sleep(Math.min(this.attempts * 1000, 5 * 1000))
        this.socket = new WebSocket(url)
        this.socket.onopen = () => {
            this.attempts = 0
            this.onStatus.trigger('ready')
        }

        this.socket.onclose = () => {
            this.cleanup()
            this.connect(url)
        }

        this.socket.onerror = () => {
            // this._cleanup()
            // this._connect()
        }

        this.socket.onmessage = evt => {
            this.dispatcher_data.trigger(evt.data)
        }
    }

    disconnect() {
        if (!this.socket) return
        this.socket.onclose = () => { }
        this.socket.close()
        this.cleanup()
    }


    private cleanup() {
        this.onStatus.trigger('disconnected')
        this.socket = undefined
    }
}