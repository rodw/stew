# Stew

**[Stew](https://github.com/rodw/stew)** is a JavaScript library that implements the [CSS selector](http://www.w3.org/TR/CSS2/selector.html) syntax, and extends it with regular expression tag names, class names, ids, attribute names and attribute values.

For example, given a variable `dom` containing a document tree, the JavaScript snippet:

```javascript
var links = stew.select(dom,'a[href]');
```

will return an array of all the anchor tags (`<a>`) found in `dom` that include an `href` attribute.

While the JavaScript snippet:

```javascript
var metadata = stew.select(dom,'head meta[name=/^dc\.|:/i]');
```

will extract the [Dublin Core metadata](http://dublincore.org/documents/dcq-html/) from a document by selecting every `<meta>` tag found in the `<head>` that has a `name` attribute that starts with `DC.` or `DC:` (ignoring case).

Stew is often used as a toolkit for "screen-scraping" web pages (extracting data from HTML and XML documents).

(The name "stew" is inspired by the Python library [BeautifulSoup](http://www.crummy.com/software/BeautifulSoup/), Simon Willison's [soupselect](http://code.google.com/p/soupselect/) extension of *BeautifulSoup*, and Harry Fuecks' [Node.js port](https://github.com/harryf/node-soupselect) of *soupselect*. [Stew](https://github.com/rodw/stew) is a meatier soup.)

## Links

Read on for more information, or:

 - [visit the repository on GitHub.](https://github.com/rodw/stew)
 - [review the API.](./docs/using.html)
 - [see a complete example of using Stew (in a "literate CoffeeScript" format).](./docs/example.html)
 - [browse the annotated source code](./docs/docco/stew.html) or [test coverage report](/docs/coverage.html).
 - [learn how to contribute to Stew.](./docs/hacking.html)
 - [see the version history and release notes.](./docs/version-history.html)

(Links not working? Try it from [heyrod.com/stew](http://heyrod.com/stew).)

## Installing

The source code and documentation for Stew is available on GitHub at [rodw/stew](https://github.com/rodw/stew).  You can clone the repository via:

```console
git clone git@github.com:rodw/stew.git
```

Stew is deployed as an [npm module](https://npmjs.org/) under the name [`stew-select`](https://npmjs.org/package/stew-select). Hence you can install a pre-packaged version with the command:

```console
npm install stew-select
```

and you can add it to your project as a dependency by adding a line like:

```javascript
"stew-select": "latest"
```

to the `dependencies` or `devDependencies` part of your `package.json` file.

## Features

### Core CSS Selectors

Stew supports the full [Version 2.1 CSS selector syntax](http://www.w3.org/TR/CSS2/selector.html) and much of [Version 3](http://www.w3.org/TR/css3-selectors/), including

  * The universal selector (`*`).

      E.g., `stew.select( dom, '*' )` selects all the tags in the document.

  * Type selectors (`E`).

      E.g., `stew.select( dom, 'h2' )` selects all the `h2` tags in the document.

  * Class selectors (`E.foo`).

      E.g., `stew.select( dom, '.foo' )` selects all tags in the document with the class `foo`.

  * ID selectors (`E#foo`).

      E.g., `stew.select( dom, '#foo' )` selects all tags in the document with the id `foo`.

  * Descendant selectors (`E F`).

      E.g., `stew.select( dom, 'div h2 a' )` selects all `a` tags with an `h2` ancestor that has a `div` ancestor.

  * Child selectors (`E > F`).

      E.g., `stew.select( dom, 'div > h2 > a')` selects all `a` tags with an `h2` *parent* that has a `div` *parent*.

  * Attribute name selectors (`E[foo]`).

      E.g., `stew.select( dom, 'a[href]')` selects all `a` tags with an `href` attribute (and `stew.select( dom, '[href]')` selects *all* tags with an `href` attribute).

  * Attribute value selectors (`E[foo="bar"]`).

      E.g., `stew.select( dom, 'a[rel="author"]')` selects all `a` tags with a `rel` attribute set to the value `author`.

  * The `~=` operator  (`E[foo~="bar"]`).

      E.g., `stew.select( dom, 'a[class~="author"]')` selects all `a` tags with the `class` `author`, whether or not that tag has other classes as well.  More generally `~=` treats the attribute
      value as a white-space delimited list of values (to which the given value is compared).

  * The `|=` operator (`E[foo|="bar"]`).

      E.g., `stew.select( dom, 'div[lang|="en"]')` selects all `div` tags with a `lang` attribute whose value is *exactly* `en` or whose value starts with `en-`.

  * The starts-with `^=` operator  (`E[foo^="bar"]`). ***NEW, UNRELEASED***

      E.g., `stew.select( dom, 'a[href^="https://"]')` selects all `a` tags with an `href` attribute value that starts with `https://`.

  * The ends-with `$=` operator  (`E[foo$="bar"]`). ***NEW, UNRELEASED***

      E.g., `stew.select( dom, 'a[href$=".html"]')` selects all `a` tags with an `href` attribute value that ends with `.html`.

  * The contains `*=` operator  (`E[foo*="bar"]`). ***NEW, UNRELEASED***

      E.g., `stew.select( dom, 'a[href*="://heyrod.com/"]')` selects all `a` tags with an `href` attribute value that contains with `://heyrod.com/`.

  * Adjacent selectors (`E + F`).

      E.g., `stew.select( dom, 'h1 + p')` selects all `p` tags that immediately follow an `h1` tag.

  * Preceeding sibling selectors (`E ~ F`). ***NEW, UNRELEASED***

      E.g., `stew.select( dom, 'h1 ~ p')` selects all `p` tags that follow an `h1` tag (even if there are other tags between the `h1` and `p`.

  * The "or" conjunction (`E, F`).

      E.g., `stew.select( dom, 'h1, h2')` selects all `h1` and `h2` tags.

  * The :first-child pseudo-class (`E:first-child`).

      E.g., `stew.select( dom, 'li:first-child' )` selects all `li` tags that happen to be the first tag among its siblings.

And of course, you can use arbitrary combinations of these selectors:

```javascript
stew.select( dom, 'article div.credits > a[rel=license]' );
stew.select( dom, 'h1, h2, h3, h4, h5, h6, .heading' );
stew.select( dom, 'h1.title + h2.subtitle' );
stew.select( dom, 'ul > li > a[rel=author][href]' );
```

### Regular Expressions

Stew extends the CSS selector syntax by allowing the use of regular expressions to specify tag names, class names, ids, and attributes (both name and value).

For example,

```javascript
var metadata = stew.select(dom,'a[href=/^https?:/i]');
```

will select all anchor (`<a>`) tags with an `href` attribute that starts with `http:` or `https:` (with a case-insensitive comparison).

Another example, the snippet:

```javascript
var metadata = stew.select(dom,'[/^data-/]');
```

selects all tags with an attribute whose name starts with `data-`.

Any name or value that starts and ends with `/` will be treated as a regular expression. (Or, more accurately, any name or value that starts with `/` and ends with `/` with an optional suffix of any combination of the letters `g`, `m` and `i`.  E.g., `/example/gi`.)

The regular expression is processed using JavaScript's standard regular expression syntax, including support for `\b` and other special class markers.

Here are some example CSS selectors using regular expressions:

  * Tag names: `/^d[aeiou]ve?$/` matches `div`, but also `dove`, `dave`, etc.
  * Class names: `./^nav/` matches any tag with a class name that starts with the string `nav`.
  * IDs: `#/^main$/i` matches any tag with the id `main`, using a case insensitive comparison (so it also matches `MAIN`, `Main` and other variants.
  * Attribute names: As above, `[/^data-/]` matches any tag with an attribute whose name starts with `data-`.
  * Attribute values: As above, `[href=/^https?:/i]` matches any tag with an `href` attribute whose value starts with `http:` or `https:` (case-insensitive).

These may be used in any combination, and freely mixed with "regular" CSS selectors.

## Current Limitations

Stew currently has a couple of known issues that crop up during specific (and rare) edge-cases. We intend to eliminate these in future releases, but want to make you aware of them so that you're not surprised.

(Developers: If you'd like to help address these issues, we'd love your help. Feel free to submit a pull request or reach out for more information.)

### CSS 3 Selectors aren't (yet) fully supported.

Our intention is to fully support the most recent CSS selector syntax.

Stew supports all of the [CSS 2.1 Selectors](http://www.w3.org/TR/CSS2/selector.html). (To the extent that it makes sense to do so. It's hard to see how to interpret `:hover` and `:visited` and so on when looking at static-HTML from the server side, although `:first-child` is supported.)

Not quite all of the [CSS 3 Selectors](http://www.w3.org/TR/css3-selectors/) are supported. Currently certain  [structural pseudo-classes](http://www.w3.org/TR/css3-selectors/#structural-pseudos) and [pseduo-elements](http://www.w3.org/TR/css3-selectors/#pseudo-elements) are not supported (*yet*).

### Stew may not report all syntax errors.

Stew will accept and properly parse any *valid* CSS selectors (unless listed as limitation elsewhere in this section).

However, (currently) Stew does not always *reject* every *invalid* selector.  In particular, Stew's parser *may* ignore the invalid parts of improperly formed selectors, which can lead to unexpected results.

### Stew requires white-space around the "generalized sibling" operator: `E ~ F` works, but `E~F` doesn't.

Stew parsers most operators (including `+`, `>` and `,`) with or without white-space.  In other words, Stew treats the following selectors as equivalent:

 * `E + F`, `E+F`, `E+ F` and `E +F`
 * `E , F`, `E,F`, `E, F` and `E ,F`
 * `E > F`, `E>F`, `E> F` and `E >F`

Unfortantely, due to a quirk of Stew's current parser, the same is not true for the "preceeding sibling" operator (`~`).  That is, Stew supports `E ~ F` but does not properly parse `E~F`.  Currently the `~` character must be surrounded by white-space.

(If you're curious, the `~=` operator is the complicating factor for `~` right now. The same patterns we use for `+`, `,` and `>` don't quite work for `~`.)

## Licensing

The Stew library and related documentation are made available under an [MIT License](http://opensource.org/licenses/MIT).  For details, please see the file [MIT-LICENSE.txt](MIT-LICENSE.txt) in the root directory of the repository.
