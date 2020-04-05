import Interceptor from './interceptor'

describe('interceptor', () => {
    it('implementation', async () => {
        const interceptor = new Interceptor()

        let hit = false
        interceptor.before_mutation(['+'], async (mut, path) => {
            hit = true
            expect(mut.merge.todo_01).toEqual('hammerhead')
            expect(path).toEqual(['todos'])
        })

        await interceptor.trigger_before({
            delete: {}, merge: {
                todos: {
                    todo_01: 'hammerhead'
                }
            }
        })
        expect(hit).toBe(true)
    })
})
