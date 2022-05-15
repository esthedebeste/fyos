fun log10(num: uint) {
    let n = num
    let i = 0
    while(n > 0) {
        n /= 10
        i += 1
    }
    i
}

fun(uint) to_strbuf(out: *char): uint {
    if(this == 0) {
        out[0] = '0'
        return 1
    }
    const len = log10(this)
    let n = this
    for(let i = len; i > 0; i -= 1) {
        out[i - 1] = (n % 10) + '0'
        n /= 10
    }
    return len
}