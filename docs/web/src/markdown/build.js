const fs = require('fs')
const path = require('path')

const DIR = './src/markdown'

function process(root) {
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

    fs.writeFileSync(path.join(DIR, 'index.js'), ['export default {', ...imports, '}'].join('\n'))
}

process(DIR)