import Dynamic from '@ironbay/dynamic'

interface BeforeMutation {
    path: string[],
    callback: (mut: Riptide.Mutation, path: string[], full: Riptide.Mutation) => Promise<void>
}

export default class Interceptor {
    private before = new Array<BeforeMutation>()

    public before_mutation(path: string[], callback: BeforeMutation['callback']) {
        this.before.push({
            path,
            callback
        })
    }

    public async trigger_before(mut: Riptide.Mutation) {
        for (let interceptor of this.before) {
            const promises =
                Interceptor
                    .pattern(mut, interceptor.path)
                    .map(async pattern => await interceptor.callback(pattern.value, pattern.path, mut))
            await Promise.all(promises)
        }
        return mut
    }

    static pattern(mut: Riptide.Mutation, path: string[]): Dynamic.Layer<Riptide.Mutation>[] {
        const layers = {} as { [key: string]: Riptide.Mutation }
        Dynamic
            .get_pattern(mut.merge, path)
            .reduce((collect, item) => {
                return Dynamic.put(collect, [item.path, 'merge'], item.value)
            }, layers)

        Dynamic
            .get_pattern(mut.delete, path)
            .reduce((collect, item) => {
                return Dynamic.put(collect, [item.path, 'delete'], item.value)
            }, layers)

        return Object
            .entries(layers)
            .map(([path, obj]) => {
                return {
                    path: path.split(','),
                    value: {
                        merge: obj.merge || {},
                        delete: obj.delete || {}
                    }
                }
            })
    }

}