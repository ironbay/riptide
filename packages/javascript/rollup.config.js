import typescript from 'rollup-plugin-typescript2'
import pkg from './package.json'

// delete old typings to avoid issues
require('fs').rmdir('dist', { recursive: true }, () => { })

export default {
    input: 'src/index.ts',
    output: [
        {
            file: pkg.main,
            format: 'cjs'
        },
        // {
        //     file: pkg.module,
        //     format: 'es'
        // },
        // {
        //     file: pkg.browser,
        //     format: 'iife',
        //     name: 'Riptide'
        // }
    ],
    external: [
        ...Object.keys(pkg.dependencies || {})
    ],
    plugins: [
        typescript({
            typescript: require('typescript'),
        }),
    ]
};