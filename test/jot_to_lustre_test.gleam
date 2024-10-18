import birdie
import gleam/list
import gleam/string
import gleeunit
import jot_to_lustre.{to_lustre}
import lustre/element

pub fn main() {
  gleeunit.main()
}

pub fn jot_to_lustre_test() {
  let jot_body =
    "
# A heading that
# takes up
# three lines

{.important .large}
A paragraph, finally

[My link text](http://example.com)

[foo bar]: http://example.com?foo_bar=1

[My link text 2][foo bar]

"

  jot_body
  |> to_lustre
  |> list.map(fn(element) { element.to_string(element) })
  |> list.fold("", string.append)
  |> birdie.snap(title: "jot_to_lustre_test_djot")
}
