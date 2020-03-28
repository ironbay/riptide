interface BeforeMutation {
    path: string[];
    callback: (mut: Riptide.Mutation, path: string[], full: Riptide.Mutation) => Promise<void>;
}
export default class Interceptor {
    private before;
    before_mutation(path: string[], callback: BeforeMutation['callback']): void;
    trigger_before(mut: Riptide.Mutation): Promise<Riptide.Mutation>;
    static pattern(mut: Riptide.Mutation, path: string[]): Dynamic.Layer<Riptide.Mutation>[];
}
export {};
