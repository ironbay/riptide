export interface Mutation {
  merge: { [key: string]: any | Mutation["merge"] }
  delete: { [key: string]: 1 | Mutation["delete"] }
}

export type Query = { [key: string]: Query | Query.Opts }

export namespace Query {
  export type Opts = {
    min?: string
    max?: string
    limit?: string
    subscribe?: boolean
  }
}

export interface Format {
  encode(input: any): string
  decode<T>(input: any): T
}

export interface Transport {
  write(data: string): void
  handle_data(cb: (data: string) => void): void
}

export interface Message {
  key?: number
  action?: string
  body?: any
  type?: "call" | "cast" | "reply" | "error"
}

export interface Syncable {
  mutation(mut: Mutation): Promise<void>
}
