#!/bin/node
const fs = require('fs')
const path = require('path')


function execute(root) {
    function walk(dir = '') {
        return fs
            .readdirSync(path.join(root, dir))
            .map(item => {
                const full = path.join(root, dir, item)
                const relative = path.join(dir, item)
                const stat = fs.statSync(full)
                if (stat.isDirectory()) return walk(relative)
                return [relative]
            })
            .reduce((collect, item) => [...collect, ...item], [])
    }
    const imports = walk()
        .filter(item => item.endsWith("md"))
        .reduce((collect, item) => {
            const route = item.substring(0, item.length - 3)
            collect.push(`"${route}": require("bundle-text:./${item}"),`)
            return collect
        }, [])

    fs.writeFileSync(path.join(root, 'index.js'), ['export default {', ...imports, '}'].join('\n'))
}

const [_a, _b, dir, watch] = process.argv
execute(dir)

if (watch === '--watch') {
    fs.watch(dir, (a, b) => {
        if (a === 'change' && b.endsWith('.md'))
            execute(dir)
    })
}
