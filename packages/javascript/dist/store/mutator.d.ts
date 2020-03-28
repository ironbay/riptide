export default abstract class Mutator {
    abstract mutation(mut: Riptide.Mutation): Promise<void>;
    merge(path: string[], value: any): Promise<void>;
    delete(path: string[]): Promise<void>;
}
