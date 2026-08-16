```sh
fd -e lua . ~/.config/nvim -0 | xargs -0 awk '
function pcount(s,    t, n1, n2) { t = s; n1 = gsub(/\(/, "(", t); t = s; n2 = gsub(/\)/, ")", t); return n1 - n2 }
/vim\.keymap\.set\(|(^|[^.])map\(/ {
    buf = $0
    depth = pcount($0)
    if (depth <= 0) { print buf "\n"; next }
    collecting = 1
    next
}
collecting {
    buf = buf "\n" $0
    depth += pcount($0)
    if (depth <= 0) { collecting = 0; print buf "\n" }
}
' > ~/keys.txt
```
