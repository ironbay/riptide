import { Format } from "../types"

export class Json implements Format {
  encode(input) {
    return JSON.stringify(input)
  }
  decode<T>(input) {
    const result = JSON.parse(input) as T
    return result
  }
}
