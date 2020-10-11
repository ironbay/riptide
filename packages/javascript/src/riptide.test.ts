import * as Riptide from "./"
import sleep from "./sleep"

const hh = { key: "001", name: "Hammerhead" }
const gw = { key: "002", name: "Great White" }

describe("riptide", () => {
  it("implementation", async () => {
    const local = new Riptide.Store.Memory()

    const conn = Riptide.Connection.create()
    conn.transport.onStatus.add(async status => {
      await local.merge(["conn", "session"], status)
      expect(local.query_path(["conn", "session"])).toEqual("ready")
    })
    await conn.transport.connect("ws://localhost:12000/socket")

    const remote = new Riptide.Store.Remote(conn)
    const sync = local.sync(remote)

    await local.delete(["sharks"])
    expect(local.query_path(["sharks"])).toEqual(undefined)

    await sync.merge(["sharks", hh.key], hh)
    const result = await remote.query_path(["sharks", hh.key])
    expect(result).toEqual(hh)
    expect(local.query_path(["sharks", hh.key])).toEqual(hh)

    await remote.query_path(["sharks"], { subscribe: true })
    await remote.merge(["sharks", gw.key], gw)
    await sleep(100)
    expect(local.query_path(["sharks", gw.key])).toEqual(gw)
  })

  it("batch", async () => {
    const conn = Riptide.Connection.create()
    await conn.transport.connect("ws://localhost:12000/socket")
    const remote = new Riptide.Store.Remote(conn)
    remote.merge(["sharks", hh.key], hh)
    remote.merge(["sharks", gw.key], gw)

    remote.query({
      sharks: {
        [hh.key]: {}
      }
    })
    const batch = await remote.query({
      sharks: {
        [gw.key]: {}
      }
    })
    expect(batch).toEqual({
      sharks: {
        [hh.key]: hh,
        [gw.key]: gw
      }
    })
  })
})
