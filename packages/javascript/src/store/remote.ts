import Dispatcher from "../dispatcher"
import * as Connection from "../connection"
import Mutator from "./mutator"
import mixin from "./mixin"
import { Layer, Transport, Format, Mutation, Query } from "../types"
import { get, put, del } from "@ironbay/dynamic"

type QueryBatchItem = {
  query: Query
  resolve: (q: QueryResult) => void
  reject: (reason: any) => void
}

type QueryResult = Mutation["merge"]

class Remote<T extends Transport, F extends Format> {
  public readonly onChange = new Dispatcher<Mutation>()
  private conn: Connection.Client<T, F>

  private query_batch: QueryBatchItem[]
  private query_batch_job?: NodeJS.Timeout

  constructor(client: Connection.Client<T, F>) {
    this.conn = client
    client.on_cast.add(async msg => {
      if (msg.action !== "riptide.mutation") return
      this.onChange.trigger(msg.body)
    })
  }

  public async mutation(mut: Mutation) {
    await this.conn.call("riptide.mutation", mut)
  }

  public async query(q: Query) {
    if (!this.query_batch_job) {
      this.query_batch = []
      this.query_batch_job = setTimeout(() => {
        this.query_batch_execute()
      }, 10)
    }
    return new Promise<QueryResult>((resolve, reject) => {
      this.query_batch.push({
        resolve: resolve,
        reject: reject,
        query: q
      })
    })
  }

  private async query_batch_execute() {
    const combined = this.query_batch
      .map(item => query_flatten(item.query))
      .reduce((collect, next) => [...collect, ...next], [])
      .reduce((collect, next) => {
        // Wide replaces narrow
        if (get(collect, next.path) != null) {
          del(collect, next.path)
          put(collect, next.path, next.value)
          return collect
        }

        // Skip narrow because wider query exists
        let current = collect
        for (let part of next.path) {
          const value = current[part]
          if (value == null) break
          if (query_is_final(value as Query)) return collect
          current = value as Query
        }

        // Simply combine query
        put(collect, next.path, next.value)
        return collect
      }, {} as Query)
    const resolves = this.query_batch.map(item => item.resolve)
    const rejects = this.query_batch.map(item => item.reject)
    this.query_batch_job = null

    try {
      const result = await this.conn.call<Mutation>("riptide.query", combined)
      await this.onChange.trigger(result)
      resolves.map(f => f(result.merge))
      return result.merge
    } catch (ex) {
      rejects.map(f => f(ex))
    }
  }

  public async query_path<T>(path: string[], opts: Query.Opts = {}) {
    return get<T>(await this.query(put({}, path, opts) as Query), path)
  }

  public async query_values<T>(path: string[], opts: Query.Opts = {}) {
    return Object.values<T>(
      (await this.query_path<{ [key: string]: T }>(path, opts)) || {}
    )
  }

  public async query_keys(path: string[], opts: Query.Opts = {}) {
    return Object.keys((await this.query_path(path, opts)) || {})
  }
}

interface Remote<T extends Transport, F extends Format> extends Mutator {}
mixin(Remote, [Mutator])

export default Remote

function query_flatten(query: Query, root: string[] = []) {
  let has_children = false
  let results = [] as Layer<Query.Opts>[]

  for (let key in query) {
    const value = query[key]
    if (value.constructor === Object) {
      const path = [...root, key]
      has_children = true
      results = [...results, ...query_flatten(value as Query, path)]
    }
  }

  if (!has_children) {
    results.push({
      path: root,
      value: query
    })
  }
  return results
}

function query_is_final(query: Query) {
  for (let key in query) {
    const value = query[key]
    if (value.constructor === Object) {
      return false
    }
  }
  return true
}
