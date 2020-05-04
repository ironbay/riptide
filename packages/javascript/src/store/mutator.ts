import Dynamic from "@ironbay/dynamic";

export default abstract class Mutator {
  abstract mutation(mut: Riptide.Mutation): Promise<void>;

  public async merge(path: string[], value: any) {
    await this.mutation({
      merge: Dynamic.put({}, path, value),
      delete: {},
    });
  }

  public async delete(path: string[]) {
    await this.mutation({
      delete: Dynamic.put({}, path, 1) as Riptide.Mutation["delete"],
      merge: {},
    });
  }
}
