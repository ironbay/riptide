import Dynamic from '@ironbay/dynamic'
import Dispatcher from '../dispatcher'
import Interceptor from './interceptor'
import mixin from './mixin'
import Mutator from './mutator'


abstract class Local {
    protected abstract mutation_raw(mut: Riptide.Mutation): void
    protected abstract mutation_reverse(mut: Riptide.Mutation): void
    protected abstract query_raw(q: Riptide.Query): any

    public readonly onChange = new Dispatcher<Riptide.Mutation>()
    public readonly interceptor = new Interceptor()

    public async mutation(mut: Riptide.Mutation) {
        await this.interceptor.trigger_before(mut)
        this.mutation_raw(mut)
        this.onChange.trigger(mut)
    }

    public query(q: Riptide.Query) {
        return this.query_raw(q)
    }

    public sync(target: Syncable) {
        return new Sync(this, target)
    }

    public query_path<T>(path: string[], opts: Riptide.Query.Opts = {}) {
        return Dynamic.get<T>(
            this.query(
                path.length === 0 ? {} : Dynamic.put({}, path, opts) as Riptide.Query
            ),
            path
        )
    }

    public query_values<T>(path: string[], opts: Riptide.Query.Opts = {}) {
        return Object.values<T>(this.query_path<{ [key: string]: T }>(path, opts) || {})
    }

    public query_keys(path: string[], opts: Riptide.Query.Opts = {}) {
        return Object.keys(this.query_path(path, opts) || {})
    }
}

interface Local extends Mutator { }
mixin(Local, [Mutator])

interface Syncable {
    onChange: Dispatcher<Riptide.Mutation>
    mutation(mut: Riptide.Mutation): Promise<void>
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

    public async mutation(mut: Riptide.Mutation) {
        await this.local.mutation(mut)
        await this.target.mutation(mut)
    }
}

interface Sync extends Mutator { }
mixin(Sync, [Mutator])

export default Local