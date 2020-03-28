import Local from './local';
export default class Memory extends Local {
    private state;
    mutation_raw(mut: Riptide.Mutation): void;
    mutation_reverse(mut: Riptide.Mutation): {
        merge: {};
        delete: {};
    };
    query_raw(query: Riptide.Query): {
        [key: string]: any;
    };
    private static query;
    private static delete;
    private static merge;
    private static merge_reverse;
}
