# jotkey

[![Package Version](https://img.shields.io/hexpm/v/jotkey)](https://hex.pm/packages/jotkey)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/jotkey/)

Tiny library for "translating" djot syntax to lustre elements. Can covnert to other renderers

> [!TIP]
>
> This is a fork from (https://hexdocs.pm/lustre_ssg/lustre/ssg/djot.html). If using lustre ssg 
> I'll recommend to not use this library if context aware systems are not needed.

```sh
gleam add jotkey
```
```gleam
import gleam/io
import lustre/element/html
import jotkey
import jot

pub fn main() {
    let jot_body = "
# A heading that
# takes up
# three lines

{.important .large}
A paragraph, finally

[My link text](http://example.com)
    "

    io.debug(
        html.body([], 
            jot_body 
            |> jot.parse
            |> jotkey.render(jotkey.default_renderer(), [])
    )

}
```

Further documentation can be found at <https://hexdocs.pm/jotkey>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
