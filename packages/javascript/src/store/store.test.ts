import Memory from './memory'

[
    Memory
]
    .map(mod => {
        describe(mod.name, () => {
            it('implementation', async () => {
                const store = new mod()

                await store.mutation({
                    merge: {
                        animals: {
                            shark: "hammerhead"
                        }
                    },
                    delete: {}
                })
                store.mutation_reverse({
                    merge: {
                        animals: {
                            shark: 'great white',
                            whale: 'orca',
                        }
                    },
                    delete: {}
                })
                expect(store.query({})).toEqual({ animals: { shark: "hammerhead" } })

                await store.mutation({
                    delete: {
                        animals: {
                            shark: 1
                        }
                    },
                    merge: {}
                })
                expect(store.query({})).toEqual({ animals: {} })

                await store.mutation({
                    delete: { animals: {} },
                    merge: { animals: { fish: "barracuda", shark: "hammerhead" } }
                })
                expect(store.query({})).toEqual({ animals: { fish: "barracuda", shark: "hammerhead" } })
                expect(store.query({ animals: { shark: {} } })).toEqual({ animals: { shark: "hammerhead" } })
                expect(store.query({ animals: { stingray: { climate: {} } } })).toEqual({ animals: { stingray: { climate: undefined } } })

                expect(store.query_path(['animals', 'shark'])).toEqual('hammerhead')
                expect(store.query_keys(['animals'])).toEqual(['fish', 'shark'])
                await store.merge(['animals', 'whale'], 'orca')
                expect(store.query_path(['animals', 'whale'])).toEqual('orca')
                await store.delete(['animals', 'whale'])
                expect(store.query_path(['animals', 'whale'])).toEqual(undefined)
            })

        })

    })
