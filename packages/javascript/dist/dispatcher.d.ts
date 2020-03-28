export default class Dispatcher<T> {
    private callbacks;
    add(cb: Callback<T>): void;
    trigger(msg: T, delay?: number): void;
}
export declare type Callback<T> = (msg: T) => void;
