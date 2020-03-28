import Interceptor from './interceptor'

describe('interceptor', () => {
    it('implementation', async () => {
        const interceptor = new Interceptor()

        let hit = false
        interceptor.before_mutation(['+'], async (mut, path) => {
            hit = true
            expect(mut.merge.shark).toEqual('hammerhead')
            expect(path).toEqual(['animals'])
        })

        await interceptor.trigger_before({
            delete: {}, merge: {
                animals: {
                    shark: 'hammerhead'
                }
            }
        })
        expect(hit).toBe(true)
    })
})
