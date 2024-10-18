import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import jot.{
  type Container, type Destination, type Document, type Inline, Code, Codeblock,
  Emphasis, Heading, Image, Linebreak, Link, Paragraph, Reference, Strong, Text,
  Url, parse,
}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

type Refs =
  Dict(String, String)

/// Convert a string of Djot into lustre html elements.
pub fn to_lustre(djot: String) {
  djot
  |> parse
  |> document_to_lustre
}

/// Convert a Djot document (normally comes from the parse fn)
/// into lustre html elements.
pub fn document_to_lustre(document: Document) {
  list.reverse(
    containers_to_lustre(document.content, document.references, [element.none()]),
  )
}

fn containers_to_lustre(
  containers: List(Container),
  refs: Refs,
  elements: List(Element(msg)),
) {
  case containers {
    [] -> elements
    [container, ..rest] -> {
      let elements = container_to_lustre(elements, container, refs)
      containers_to_lustre(rest, refs, elements)
    }
  }
}

fn container_to_lustre(
  elements: List(Element(msg)),
  container: Container,
  refs: Refs,
) {
  let element = case container {
    Paragraph(attrs, inlines) -> {
      html.p(
        attributes_to_lustre(attrs, []),
        inlines_to_lustre([], inlines, refs),
      )
    }
    Heading(attrs, level, inlines) -> {
      case level {
        1 ->
          html.h1(
            attributes_to_lustre(attrs, []),
            inlines_to_lustre([], inlines, refs),
          )
        2 ->
          html.h2(
            attributes_to_lustre(attrs, []),
            inlines_to_lustre([], inlines, refs),
          )
        3 ->
          html.h3(
            attributes_to_lustre(attrs, []),
            inlines_to_lustre([], inlines, refs),
          )
        4 ->
          html.h4(
            attributes_to_lustre(attrs, []),
            inlines_to_lustre([], inlines, refs),
          )
        5 ->
          html.h5(
            attributes_to_lustre(attrs, []),
            inlines_to_lustre([], inlines, refs),
          )
        _ ->
          html.h6(
            attributes_to_lustre(attrs, []),
            inlines_to_lustre([], inlines, refs),
          )
      }
    }
    Codeblock(attrs, language, content) -> {
      html.pre(attributes_to_lustre(attrs, []), [
        html.code(
          case language {
            Some(lang) -> [attribute.class("language-" <> lang)]
            None -> []
          },
          [html.text(content)],
        ),
      ])
    }
  }
  [element, ..elements]
}

fn inlines_to_lustre(
  elements: List(Element(msg)),
  inlines: List(Inline),
  refs: Refs,
) {
  case inlines {
    [] -> elements
    [inline, ..rest] -> {
      elements
      |> inline_to_lustre(inline, refs)
      |> inlines_to_lustre(rest, refs)
    }
  }
}

fn inline_to_lustre(
  elements: List(Element(msg)),
  inline: Inline,
  refs: Dict(String, String),
) {
  case inline {
    Linebreak -> [html.br([])]
    Text(text) -> [html.text(text)]
    Strong(inlines) -> {
      [html.strong([], inlines_to_lustre(elements, inlines, refs))]
    }
    Emphasis(inlines) -> {
      [html.em([], inlines_to_lustre(elements, inlines, refs))]
    }
    Link(text, destination) -> {
      [
        html.a(
          [attribute.href(destination_attribute(destination, refs))],
          inlines_to_lustre(elements, text, refs),
        ),
      ]
    }
    Image(text, destination) -> {
      [
        html.img([
          attribute.src(destination_attribute(destination, refs)),
          attribute.alt(take_inline_text(text, "")),
        ]),
      ]
    }
    Code(content) -> {
      [html.code([], [html.text(content)])]
    }
  }
}

fn destination_attribute(destination: Destination, refs: Refs) {
  case destination {
    Url(url) -> url
    Reference(id) ->
      case dict.get(refs, id) {
        Ok(url) -> url
        Error(Nil) -> ""
      }
  }
}

fn take_inline_text(inlines: List(Inline), acc: String) -> String {
  case inlines {
    [] -> acc
    [first, ..rest] ->
      case first {
        Text(text) | Code(text) -> take_inline_text(rest, acc <> text)
        Strong(inlines) | Emphasis(inlines) ->
          take_inline_text(list.append(inlines, rest), acc)
        Link(nested, _) | Image(nested, _) -> {
          let acc = take_inline_text(nested, acc)
          take_inline_text(rest, acc)
        }
        Linebreak -> {
          take_inline_text(rest, acc)
        }
      }
  }
}

fn attributes_to_lustre(attributes: Dict(String, String), lustre_attributes) {
  attributes
  |> dict.to_list
  |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
  |> list.fold(lustre_attributes, fn(lustre_attributes, pair) {
    [attribute.attribute(pair.0, pair.1), ..lustre_attributes]
  })
}
