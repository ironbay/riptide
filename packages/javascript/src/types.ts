import { PathLike } from "fs";
const x: PathLike = "";
declare namespace Riptide {
  interface Mutation {
    merge: { [key: string]: any | Mutation["merge"] };
    delete: { [key: string]: 1 | Mutation["delete"] };
  }

  type Query = { [key: string]: Query | Query.Opts };

  namespace Query {
    type Opts = {
      min?: string;
      max?: string;
      limit?: string;
      subscribe?: boolean;
    };
  }

  interface Format {
    encode(input: any): string;
    decode<T>(input: any): T;
  }

  interface Transport {
    write(data: string): void;
    handle_data(cb: (data: string) => void): void;
  }

  interface Message {
    key?: number;
    action?: string;
    body?: any;
    type?: "call" | "cast" | "reply" | "error";
  }

  interface Syncable {
    mutation(mut: Mutation): Promise<void>;
  }
}
