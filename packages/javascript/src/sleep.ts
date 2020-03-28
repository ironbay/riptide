export default function (time: number) {
    return new Promise<number>((resolve) => {
        setTimeout(() => resolve(time), time)
    })
}