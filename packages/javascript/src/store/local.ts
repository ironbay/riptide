import Dynamic from "@ironbay/dynamic"
import Dispatcher from "../dispatcher"
import Interceptor from "./interceptor"
import mixin from "./mixin"
import Mutator from "./mutator"
import { Mutation, Query } from "../types"

abstract class Local {
  protected abstract mutation_raw(mut: Mutation): void
  protected abstract mutation_reverse(mut: Mutation): void
  protected abstract query_raw(q: Query): any

  public readonly onChange = new Dispatcher<Mutation>()
  public readonly interceptor = new Interceptor()

  public async mutation(mut: Mutation) {
    await this.interceptor.trigger_before(mut)
    this.mutation_raw(mut)
    this.onChange.trigger(mut)
  }

  public query(q: Query) {
    return this.query_raw(q)
  }

  public sync(target: Syncable) {
    return new Sync(this, target)
  }

  public query_path<T>(path: string[], opts: Query.Opts = {}) {
    return Dynamic.get<T>(
      this.query(
        path.length === 0 ? {} : (Dynamic.put({}, path, opts) as Query)
      ),
      path
    )
  }

  public query_values<T>(path: string[], opts: Query.Opts = {}) {
    return Object.values<T>(
      this.query_path<{ [key: string]: T }>(path, opts) || {}
    )
  }

  public query_keys(path: string[], opts: Query.Opts = {}) {
    return Object.keys(this.query_path(path, opts) || {})
  }
}

interface Local extends Mutator {}
mixin(Local, [Mutator])

interface Syncable {
  onChange: Dispatcher<Mutation>
  mutation(mut: Mutation): Promise<void>
}

class Sync {
  private target: Syncable
  private local: Local

  constructor(local: Local, target: Syncable) {
    this.local = local
    this.target = target
    target.onChange.add(async mut => {
      await this.local.mutation(mut)
    })
  }

  public async mutation(mut: Mutation) {
    await this.local.mutation(mut)
    await this.target.mutation(mut)
  }
}

interface Sync extends Mutator {}
mixin(Sync, [Mutator])

export default Local
