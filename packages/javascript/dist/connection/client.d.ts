import Dispatcher from '../dispatcher';
export default class Client<T extends Riptide.Transport, F extends Riptide.Format> {
    transport: T;
    format: F;
    counter: number;
    on_cast: Dispatcher<Riptide.Message>;
    private pending;
    constructor(transport?: {
        new (): T;
    }, format?: {
        new (): F;
    });
    call<T>(action: string, body: any): Promise<T>;
    cast(action: string, body: any): Promise<void>;
    private write;
    private handle_data;
}
