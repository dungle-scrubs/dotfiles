let colors = ['red', 'blue']

colors.push('green')

// let stuff = colors.watch(


import { watch } from 'watch'

let colors = ['red', 'blue']
    
let stuff = watch(colors, (prop, value) => {
    console.log(prop, value)
}
