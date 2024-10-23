// Fork code derived from https://github.com/lustre-labs/ssg/blob/main/src/lustre/ssg/djot.gleam

// IMPORTS ---------------------------------------------------------------------

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import jot
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html

// TYPES -----------------------------------------------------------------------

/// A renderer for a djot document, knows how to turn each block or inline element
/// into some custom view. That view could be anything, but it's typically a
/// Lustre element.
///
/// Some ideas for other renderers include:
///
/// - A renderer that turns a djot document into a JSON object
/// - A renderer that generates a table of contents
/// - A renderer that generates Nakai elements instead of Lustre ones
///
///
/// This renderer is compatible with **v1.0.2** of the [jot](https://hexdocs.pm/jot/jot.html)
/// package.
/// 
/// For more advanced usage check examples implementing context aware renderers
///
pub type Renderer(view, context) {
  Renderer(
    codeblock: fn(Dict(String, String), Option(String), String, context) -> view,
    emphasis: fn(List(view), context) -> view,
    heading: fn(Dict(String, String), Int, List(view), context) -> view,
    link: fn(jot.Destination, Dict(String, String), List(view), context) -> view,
    paragraph: fn(Dict(String, String), List(view), context) -> view,
    strong: fn(List(view), context) -> view,
    text: fn(String, context) -> view,
    code: fn(String, context) -> view,
    image: fn(jot.Destination, String, context) -> view,
    linebreak: fn(context) -> view,
  )
}

// CONSTRUCTORS ----------------------------------------------------------------

/// The default renderer generates some sensible Lustre elements from a djot
/// document. You can use this if you need a quick drop-in renderer for some
/// markup in a Lustre project.
///
pub fn default_renderer() -> Renderer(Element(msg), context) {
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
    paragraph: fn(attrs, content, _context) {
      html.p(to_attributes(attrs), content)
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

// CONVERSIONS -----------------------------------------------------------------

/// Render a djot document using the given renderer.
///
pub fn render(
  document: jot.Document,
  renderer: Renderer(view, context),
  context: context,
) -> List(view) {
  document.content
  |> list.map(render_block(_, document.references, renderer, context))
}

fn render_block(
  block: jot.Container,
  references: Dict(String, String),
  renderer: Renderer(view, context),
  context: context,
) -> view {
  case block {
    jot.Paragraph(attrs, inline) -> {
      renderer.paragraph(
        attrs,
        list.map(inline, render_inline(_, references, renderer, context)),
        context,
      )
    }

    jot.Heading(attrs, level, inline) -> {
      renderer.heading(
        attrs,
        level,
        list.map(inline, render_inline(_, references, renderer, context)),
        context,
      )
    }

    jot.Codeblock(attrs, language, code) -> {
      renderer.codeblock(attrs, language, code, context)
    }
  }
}

fn render_inline(
  inline: jot.Inline,
  references: Dict(String, String),
  renderer: Renderer(view, context),
  context: context,
) -> view {
  case inline {
    jot.Text(text) -> {
      renderer.text(text, context)
    }

    jot.Link(content, destination) -> {
      renderer.link(
        destination,
        references,
        list.map(content, render_inline(_, references, renderer, context)),
        context,
      )
    }

    jot.Emphasis(content) -> {
      renderer.emphasis(
        list.map(content, render_inline(_, references, renderer, context)),
        context,
      )
    }

    jot.Strong(content) -> {
      renderer.strong(
        list.map(content, render_inline(_, references, renderer, context)),
        context,
      )
    }

    jot.Code(content) -> {
      renderer.code(content, context)
    }

    jot.Image(alt, destination) -> {
      renderer.image(destination, text_content(alt), context)
    }

    jot.Linebreak -> {
      renderer.linebreak(context)
    }
  }
}

// UTILS -----------------------------------------------------------------------

fn text_content(segments: List(jot.Inline)) -> String {
  use text, inline <- list.fold(segments, "")

  case inline {
    jot.Text(content) -> text <> content
    jot.Link(content, _) -> text <> text_content(content)
    jot.Emphasis(content) -> text <> text_content(content)
    jot.Strong(content) -> text <> text_content(content)
    jot.Code(content) -> text <> content
    jot.Image(_, _) -> text
    jot.Linebreak -> text
  }
}
