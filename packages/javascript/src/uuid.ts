const FORWARDS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
const BACKWARDS = FORWARDS.split('').reverse().join('')

function now() {
    return new Date().getTime()
}

export function ascending() {
    return ascending_from(now())
}

export function descending() {
    return descending_from(now())
}

export function descending_from(timestamp: number) {
    return generate(timestamp, BACKWARDS, BACKWARDS)
}
export function descending_uniform(timestamp: number) {
    return generate(timestamp, BACKWARDS, '0')
}

export function ascending_from(timestamp: number) {
    return generate(timestamp, FORWARDS, FORWARDS)
}
export function ascending_uniform(timestamp: number) {
    return generate(timestamp, FORWARDS, '0')
}

function generate(time: number, pool: string, random: string): string {
    const length = pool.length
    let now = time

    const result = new Array(20)

    // Time Part
    for (let i = 7; i >= 0; i--) {
        const n = now % length
        result[i] = pool.charAt(Math.abs(now % length))
        now = Math.floor(now / length)
    }

    // Random Part
    for (let i = 8; i < 20; i++) {
        const r = Math.floor(Math.random() * random.length)
        result[i] = random.charAt(r)
    }

    return result.join('')
}
