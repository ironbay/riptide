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

      class RecursiveObject {
        child: RecursiveObject
        constructor() {
          this.child = this
        }
      }
      const r = new RecursiveObject()
      await store.merge(["recursive"], r)
      expect(store.query_path(["recursive"])).toBe(r)
      await store.delete(["recursive"])

      await store.merge(["primitive"], new Date())
      expect(store.query_path(["primitive"]).constructor === Date).toEqual(true)
      await store.delete(["primitive"])

      await store.mutation({
        delete: { todos: 1 },
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
        todos: { todo_03: { created: undefined } }
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
