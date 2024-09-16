import gleam/io
import gleeunit
import gleeunit/should
import lustre/attribute
import lustre/element/html

import jot_to_lustre.{to_lustre}

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
"
  io.debug(to_lustre(jot_body))
  to_lustre(jot_body)
  |> should.equal([
    html.text(""),
    html.h1([attribute.id("A-heading-that-takes-up-three-lines")], [
      html.text("A heading that\ntakes up\nthree lines"),
    ]),
    html.p([attribute.class("important large")], [
      html.text("A paragraph, finally"),
    ]),
    html.p([], [
      html.a([attribute.href("http://example.com")], [html.text("My link text")]),
    ]),
  ])
}
