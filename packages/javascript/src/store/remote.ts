import Dynamic from "@ironbay/dynamic"
import Dispatcher from "../dispatcher"
import * as Connection from "../connection"
import Mutator from "./mutator"
import mixin from "./mixin"

class Remote<T extends Riptide.Transport, F extends Riptide.Format> {
  public readonly onChange = new Dispatcher<Riptide.Mutation>()
  private conn: Connection.Client<T, F>

  constructor(client: Connection.Client<T, F>) {
    this.conn = client
    client.on_cast.add(msg => {
      if (msg.action !== "riptide.mutation") return
      this.onChange.trigger(msg.body)
    })
  }

  public async mutation(mut: Riptide.Mutation) {
    await this.conn.call("riptide.mutation", mut)
  }

  public async query(q: Riptide.Query) {
    const result = await this.conn.call<Riptide.Mutation>("riptide.query", q)
    this.onChange.trigger(result)
    return result.merge
  }

  public async query_path<T>(path: string[], opts: Riptide.Query.Opts = {}) {
    return Dynamic.get<T>(
      await this.query(Dynamic.put({}, path, opts) as Riptide.Query),
      path
    )
  }

  public async query_values<T>(path: string[], opts: Riptide.Query.Opts = {}) {
    return Object.values<T>(
      (await this.query_path<{ [key: string]: T }>(path, opts)) || {}
    )
  }

  public async query_keys(path: string[], opts: Riptide.Query.Opts = {}) {
    return Object.keys((await this.query_path(path, opts)) || {})
  }
}

interface Remote<T extends Riptide.Transport, F extends Riptide.Format>
  extends Mutator {}
mixin(Remote, [Mutator])

export default Remote
