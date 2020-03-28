export class Json implements Riptide.Format {
    encode(input) {
        return JSON.stringify(input)
    }
    decode<T>(input) {
        const result = JSON.parse(input) as T
        return result
    }
}