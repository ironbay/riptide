import Dispatcher from '../dispatcher';
import Interceptor from './interceptor';
import Mutator from './mutator';
declare abstract class Local {
    protected abstract mutation_raw(mut: Riptide.Mutation): void;
    protected abstract mutation_reverse(mut: Riptide.Mutation): void;
    protected abstract query_raw(q: Riptide.Query): any;
    readonly onChange: Dispatcher<Riptide.Mutation>;
    readonly interceptor: Interceptor;
    mutation(mut: Riptide.Mutation): Promise<void>;
    query(q: Riptide.Query): any;
    sync(target: Syncable): Sync;
    query_path<T>(path: string[], opts?: Riptide.Query.Opts): T;
    query_values<T>(path: string[], opts?: Riptide.Query.Opts): T[];
    query_keys(path: string[], opts?: Riptide.Query.Opts): string[];
}
interface Local extends Mutator {
}
interface Syncable {
    onChange: Dispatcher<Riptide.Mutation>;
    mutation(mut: Riptide.Mutation): Promise<void>;
}
declare class Sync {
    private target;
    private local;
    constructor(local: Local, target: Syncable);
    mutation(mut: Riptide.Mutation): Promise<void>;
}
interface Sync extends Mutator {
}
export default Local;
