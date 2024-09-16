# jot_to_lustre

[![Package Version](https://img.shields.io/hexpm/v/jot_to_lustre)](https://hex.pm/packages/jot_to_lustre)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/jot_to_lustre/)

```sh
gleam add jot_to_lustre
```
```gleam
import gleam/io
import lustre/element/html
import jot_to_lustre

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
        html.body([], jot_to_lustre.to_lustre(jot_body)
    )
}
```

Further documentation can be found at <https://hexdocs.pm/jot_to_lustre>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
