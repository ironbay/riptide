import Dispatcher from '../dispatcher'
import sleep from '../sleep'

export default class Client<T extends Riptide.Transport, F extends Riptide.Format> {
    public transport: T
    public format: F
    public counter: number = 0
    public on_cast = new Dispatcher<Riptide.Message>()
    private pending = new Map<number, { resolve: any, reject: any }>()

    constructor(transport: { new(): T } = null, format: { new(): F } = null) {
        this.transport = new transport()
        this.transport.handle_data(data => this.handle_data(data))
        this.format = new format()
    }

    async call<T>(action: string, body: any) {
        this.counter++
        const promise = new Promise<T>((resolve, reject) => {
            this.pending.set(this.counter, { resolve, reject })
        })
        await this.write({
            key: this.counter,
            action,
            body,
            type: 'call'
        })
        return promise
    }

    async cast(action: string, body: any) {
        await this.write({
            action,
            body,
            type: 'cast'
        })
    }

    private async write(msg: Riptide.Message) {
        const encoded = this.format.encode(msg)
        try {
            this.transport.write(encoded)
        } catch (ex) {
            await sleep(1000)
            return await this.write(msg)
        }
    }

    private handle_data(data: string) {
        const msg = this.format.decode<Riptide.Message>(data)
        const match = this.pending.get(msg.key)
        switch (msg.type) {
            case 'reply':
                match.resolve(msg.body)
                this.pending.delete(msg.key)
            case 'error':
                match.reject(msg.body)
                this.pending.delete(msg.key)
            default:
                this.on_cast.trigger(msg)
        }
    }

}

