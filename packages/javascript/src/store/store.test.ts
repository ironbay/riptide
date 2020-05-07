import Memory from "./memory"
;[Memory].map(mod => {
  describe(mod.name, () => {
    it("implementation", async () => {
      const store = new mod()

      await store.mutation({
        merge: {
          todos: {
            todo_01: "hammerhead"
          }
        },
        delete: {}
      })
      store.mutation_reverse({
        merge: {
          todos: {
            todo_01: "pet the great white",
            todo_02: "feed the orca"
          }
        },
        delete: {}
      })
      expect(store.query({})).toEqual({ todos: { todo_01: "hammerhead" } })

      await store.mutation({
        delete: {
          todos: {
            todo_01: 1
          }
        },
        merge: {}
      })
      expect(store.query({})).toEqual({ todos: {} })

      await store.mutation({
        delete: { todos: {} },
        merge: {
          todos: {
            todo_01: "feed the barracuda",
            todo_02: "pet the hammerhead"
          }
        }
      })
      expect(store.query({})).toEqual({
        todos: { todo_01: "feed the barracuda", todo_02: "pet the hammerhead" }
      })
      expect(store.query({ todos: { todo_01: {} } })).toEqual({
        todos: { todo_01: "feed the barracuda" }
      })
      expect(store.query({ todos: { todo_03: { created: {} } } })).toEqual({
        todos: { todo_03: { creaded: undefined } }
      })

      expect(store.query_path(["todos", "todo_01"])).toEqual(
        "feed the barracuda"
      )
      expect(store.query_keys(["todos"])).toEqual(["todo_01", "todo_02"])
      await store.merge(["todos", "todo_01"], "feed the orca")
      expect(store.query_path(["todos", "todo_01"])).toEqual("feed the orca")
      await store.delete(["todos", "todo_01"])
      expect(store.query_path(["todos", "todo_01"])).toEqual(undefined)
    })
  })
})
