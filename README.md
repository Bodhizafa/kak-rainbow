# kak-rainbow
A cursor-centered rainbow highlighter for kakoune. 

Handles different styles of enclosing characters independently, so adding parens doesn't change the colors of braces, etc.
Fast enough to use in idle hooks, on my machine highlighting an 80 column by 80 line block of solid parentheses took ~70ms to compute.

![kak-rainbow demo](https://raw.githubusercontent.com/Bodhizafa/kak-rainbow/master/demo.gif)

## Installation
Install by putting rainbow.kak into your autoload folder (by default, `~/.config/kak/autoload/`).

You'll also likely want to add 'rainbow-enable-window' to run when certain filetypes are opened by adding something like this to kakrc:

```
hook global WinSetOption filetype=(rust|python|c|c++|scheme|lisp|clojure|javascript|json) %{
        rainbow-enable-window
}
```

## Configuration
use `set-option rainbow_colors <space separated list of colors>` to customize colors. 
The first one is the one the cursor is currently on, 
surrounding levels get the next color in the list, 
surrounded ones get the previous (wrapping if necessary).

## Limitations
Because this is language-agnostic, < and > aren't supported (knowing when to ignore their use as comparisons requires parsing).
For the same reason, comments are highlighted just like anything else. So far this hasn't been an issue

## Similar projects
These other rainbow highlighters have somewhat different behaviors, and were very helpful in learning how to construct this one.
- https://github.com/listentolist/kakoune-rainbow
- https://github.com/JJK96/kakoune-rainbow

