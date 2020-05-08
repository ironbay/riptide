import Dynamic from "@ironbay/dynamic"
import Dispatcher from "../dispatcher"
import * as Connection from "../connection"
import Mutator from "./mutator"
import mixin from "./mixin"
import { Mutation, Query, Transport, Format } from "../types"

class Remote<T extends Transport, F extends Format> {
  public readonly onChange = new Dispatcher<Mutation>()
  private conn: Connection.Client<T, F>

  constructor(client: Connection.Client<T, F>) {
    this.conn = client
    client.on_cast.add(msg => {
      if (msg.action !== "riptide.mutation") return
      this.onChange.trigger(msg.body)
    })
  }

  public async mutation(mut: Mutation) {
    await this.conn.call("riptide.mutation", mut)
  }

  public async query(q: Query) {
    const result = await this.conn.call<Mutation>("riptide.query", q)
    this.onChange.trigger(result)
    return result.merge
  }

  public async query_path<T>(path: string[], opts: Query.Opts = {}) {
    return Dynamic.get<T>(
      await this.query(Dynamic.put({}, path, opts) as Query),
      path
    )
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
