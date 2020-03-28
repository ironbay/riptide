import Dispatcher from '../dispatcher';
import * as Connection from '../connection';
import Mutator from './mutator';
declare class Remote<T extends Riptide.Transport, F extends Riptide.Format> {
    readonly onChange: Dispatcher<Riptide.Mutation>;
    private conn;
    constructor(client: Connection.Client<T, F>);
    mutation(mut: Riptide.Mutation): Promise<void>;
    query(q: Riptide.Query): Promise<{
        [key: string]: any;
    }>;
    query_path<T>(path: string[], opts?: Riptide.Query.Opts): Promise<T>;
    query_values<T>(path: string[], opts?: Riptide.Query.Opts): Promise<T[]>;
    query_keys(path: string[], opts?: Riptide.Query.Opts): Promise<string[]>;
}
interface Remote<T extends Riptide.Transport, F extends Riptide.Format> extends Mutator {
}
export default Remote;
