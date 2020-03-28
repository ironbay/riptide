export default class Dispatcher<T> {
    private callbacks = new Array<Callback<T>>()

    public add(cb: Callback<T>) {
        this.callbacks.push(cb)
    }

    public trigger(msg: T, delay = 0) {
        this.callbacks.forEach(cb => cb(msg))
    }
}
export type Callback<T> = (msg: T) => void