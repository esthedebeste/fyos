include "std/types"
include "std/utils"
struct VMem {
    ch: char,
    style: uint8
}
const video_memory: *VMem = 753664 // 0xb8000

fun main(): int {
    let str = "Kernel Loaded!"
    for(let i = 0; i < len(str); i += 1)
        video_memory[i].ch = str[i]
    0
}