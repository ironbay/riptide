import Dynamic from "@ironbay/dynamic"
import { Mutation } from "../types"

interface BeforeMutation {
  path: string[]
  callback: (mut: Mutation, path: string[], full: Mutation) => Promise<void>
}

export default class Interceptor {
  private before = new Array<BeforeMutation>()

  public before_mutation(path: string[], callback: BeforeMutation["callback"]) {
    this.before.push({
      path,
      callback
    })
  }

  public async trigger_before(mut: Mutation) {
    for (let interceptor of this.before) {
      const promises = Interceptor.pattern(mut, interceptor.path).map(
        async pattern =>
          await interceptor.callback(pattern.value, pattern.path, mut)
      )
      await Promise.all(promises)
    }
    return mut
  }

  static pattern(mut: Mutation, path: string[]): Dynamic.Layer<Mutation>[] {
    const layers = {} as { [key: string]: Mutation }

    Dynamic.get_pattern(mut.merge, path).reduce((collect, item) => {
      return Dynamic.put(collect, [item.path, "merge"], item.value)
    }, layers)

    Dynamic.get_pattern(mut.delete, path).reduce((collect, item) => {
      return Dynamic.put(collect, [item.path, "delete"], item.value)
    }, layers)

    return Object.entries(layers).map(([path, obj]) => {
      return {
        path: path.split(","),
        value: {
          merge: obj.merge || {},
          delete: obj.delete || {}
        }
      }
    })
  }
}
