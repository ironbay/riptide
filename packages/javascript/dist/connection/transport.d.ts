import Dispatcher from '../dispatcher';
export declare abstract class Base implements Riptide.Transport {
    abstract write(data: string): void;
    protected dispatcher_data: Dispatcher<string>;
    handle_data(cb: (data: string) => void): void;
}
export declare class WS extends Base {
    attempts: number;
    private socket;
    readonly onStatus: Dispatcher<string>;
    write(data: string): void;
    connect(url: string): Promise<void>;
    disconnect(): void;
    private cleanup;
}
