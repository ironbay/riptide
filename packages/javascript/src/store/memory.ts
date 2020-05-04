import Local from "./local"
export default class Memory extends Local {
  private state: { [key: string]: any } = {}

  mutation_raw(mut: Riptide.Mutation) {
    Memory.delete(this.state, mut.delete)
    Memory.merge(this.state, mut.merge)
  }

  mutation_reverse(mut: Riptide.Mutation) {
    return Memory.merge_reverse(this.state, mut.merge)
  }

  query_raw(query: Riptide.Query) {
    return Memory.query(this.state, query)
  }

  private static query(state: { [key: string]: any }, input: Riptide.Query) {
    const result = {} as { [key: string]: any }
    let found = false
    for (let key of Object.keys(input)) {
      const value = input[key]
      if (value instanceof Object) {
        found = true
        const existing = state && state[key]
        result[key] = Memory.query(existing, value as Riptide.Query)
      }
    }
    if (!found) return state
    return result
  }

  private static delete(
    state: { [key: string]: any },
    input: Riptide.Mutation["delete"]
  ) {
    for (let key of Object.keys(input)) {
      const value = input[key]

      if (value === 1) {
        delete state[key]
        continue
      }

      const existing = state[key]
      if (!existing) continue
      Memory.delete(existing, value)
    }
  }

  private static merge(
    state: { [key: string]: any },
    input: Riptide.Mutation["merge"]
  ) {
    for (let key of Object.keys(input)) {
      const value = input[key]

      if (!(value instanceof Object)) {
        state[key] = value
        continue
      }

      if (!state[key]) state[key] = {}
      const existing = state[key]
      Memory.merge(existing, value)
      continue
    }
  }
  private static merge_reverse(
    state: { [key: string]: any },
    input: Riptide.Mutation["merge"]
  ) {
    const result = {
      merge: {},
      delete: {}
    }
    for (let key of Object.keys(input)) {
      const value = input[key]
      const exists = state[key]
      if (!exists) {
        result.delete[key] = 1
        continue
      }

      if (!(value instanceof Object)) {
        result.merge[key] = exists
        continue
      }

      const child = this.merge_reverse(exists, value)
      result.merge[key] = child.merge
      result.delete[key] = child.delete
    }
    return result
  }
}
