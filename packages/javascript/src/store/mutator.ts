import { put } from "@ironbay/dynamic"
import { Mutation } from "../types"

export default abstract class Mutator {
  abstract mutation(mut: Mutation): Promise<void>

  public async merge(path: string[], value: any) {
    await this.mutation({
      merge: put({}, path, value),
      delete: {}
    })
  }

  public async delete(path: string[]) {
    await this.mutation({
      delete: put({}, path, 1) as Mutation["delete"],
      merge: {}
    })
  }
}
