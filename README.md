# jotkey

[![Package Version](https://img.shields.io/hexpm/v/jotkey)](https://hex.pm/packages/jotkey)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/jotkey/)

Tiny library for "translating" djot syntax to lustre elements. Can convert to other renderers

> [!TIP]
> This is a fork from https://hexdocs.pm/lustre_ssg/lustre/ssg/djot.html. If using lustre ssg 
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

## Advanced usage


```gleam
import gleam/io
import lustre/element/html
import jotkey
import jot

pub fn main() {
    let jot_body = "

{slug=Esoteric-programming-language title=\"Esoteric programming languages\"}
view:wikipedia

{slug=Esoteric-programming-language}
view:wikipedia

{slug=Not-Found}
view:wikipedia

    "

    io.debug(
        html.body([], 
            jot_body 
            |> jot.parse
            |> jotkey.render(context_aware_lustre_renderer(), [
                WikipediaDocument("Esoteric-programming-language"),
                WikipediaDocument("Shakespeare-Programming-Language"),
            ])
    )
}


type TestContextItem {
  WikipediaDocument(slug: String)
}

fn context_aware_lustre_renderer() {
  let to_attributes = fn(attrs) {
    use attrs, key, val <- dict.fold(attrs, [])
    [attribute(key, val), ..attrs]
  }

  Renderer(
    codeblock: fn(attrs, lang, code, _context) {
      let lang = option.unwrap(lang, "text")
      html.pre(to_attributes(attrs), [
        html.code([attribute("data-lang", lang)], [element.text(code)]),
      ])
    },
    emphasis: fn(content, _context) { html.em([], content) },
    heading: fn(attrs, level, content, _context) {
      case level {
        1 -> html.h1(to_attributes(attrs), content)
        2 -> html.h2(to_attributes(attrs), content)
        3 -> html.h3(to_attributes(attrs), content)
        4 -> html.h4(to_attributes(attrs), content)
        5 -> html.h5(to_attributes(attrs), content)
        6 -> html.h6(to_attributes(attrs), content)
        _ -> html.p(to_attributes(attrs), content)
      }
    },
    link: fn(destination, references, content, _context) {
      case destination {
        jot.Reference(ref) ->
          case dict.get(references, ref) {
            Ok(url) -> html.a([attribute.href(url)], content)
            Error(_) -> html.a([attribute.href(ref)], content)
          }
        jot.Url(url) -> html.a([attribute("href", url)], content)
      }
    },
    paragraph: fn(attrs, content, context) {
      case content {
        [vdom.Text("view:wikipedia")] -> {
          let wiki_slug = result.unwrap(dict.get(attrs, "slug"), "none")
          case
            list.find(context, fn(context_item) {
              case context_item {
                WikipediaDocument(slug) if slug == wiki_slug -> True
                _ -> False
              }
            })
          {
            Ok(_) ->
              html.div([], [
                html.text(result.unwrap(dict.get(attrs, "title"), "No title")),
              ])
            _ -> element.none()
          }
        }
        _ -> html.p(to_attributes(attrs), content)
      }
    },
    strong: fn(content, _context) { html.strong([], content) },
    text: fn(text, _context) { element.text(text) },
    code: fn(content, _context) { html.code([], [element.text(content)]) },
    image: fn(destination, alt, _context) {
      case destination {
        jot.Reference(ref) -> html.img([attribute.src(ref), attribute.alt(alt)])
        jot.Url(url) -> html.img([attribute.src(url), attribute.alt(alt)])
      }
    },
    linebreak: fn(_context) { html.br([]) },
  )
}

```

Further documentation can be found at <https://hexdocs.pm/jotkey>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
