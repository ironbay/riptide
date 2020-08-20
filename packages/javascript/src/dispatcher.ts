export default class Dispatcher<T> {
  private callbacks = new Array<Callback<T>>()

  public add(cb: Callback<T>) {
    this.callbacks.push(cb)
    return cb
  }

  public remove(cb: Callback<T>) {
    this.callbacks = this.callbacks.filter(item => item === cb)
  }

  public trigger(msg: T) {
    this.callbacks.forEach(cb => cb(msg))
  }
}
export type Callback<T> = (msg: T) => void
