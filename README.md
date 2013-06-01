# Stew

[Stew](https://github.com/rodw/stew) is a JavaScript library that is used to select elements from a DOM structure using a beefed-up version of the [CSS selector](http://www.w3.org/TR/CSS2/selector.html) syntax that allows the use of regular expressions anywhere (tag names, class names, ids and  attributes names and values).

Stew is often used as a toolkit for "screen-scrapting" web pages (extracting data from HTML and XML documents).

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

(The name "stew" is inspired by the Python library [BeautifulSoup](http://www.crummy.com/software/BeautifulSoup/), Simon Willison's [soupselect](http://code.google.com/p/soupselect/) extension of *BeautifulSoup*, and Harry Fuecks' [Node.js port](https://github.com/harryf/node-soupselect) of *soupselect*. [Stew](https://github.com/rodw/stew) is a meatier soup.)

## Installing

Stew is deployed as an [npm module](https://npmjs.org/) under the name [`stew-select`](https://npmjs.org/package/stew-select). Hence you can install a pre-packaged version with the command:

```console
npm install stew-select
```

and you can add it to your project as a dependency by adding a line like:

```json
"soup-select": "latest"
```

to the `dependencies` or `devDependencies` part of your `package.json` file.

## Features

### Core CSS Selectors

Stew supports essentially all of the [CSS selector](http://www.w3.org/TR/CSS2/selector.html) syntax, including

  * The universal selector (`*`).

      E.g., `stew.select( dom, '*' )` selects all the tags in the document.

  * Type selectors (`E`).

      E.g., `stew.select( dom, 'h2' )` selects all the `h2` tags in the document.

  * Class selectors (`E.foo`).

      E.g., `stew.select( dom, '.foo' )` selects all tags in the document with the class `foo`.

  * ID selectors (`E#foo`).

      E.g., `stew.select( dom, '#foo' )` selects all tags in the document with the id `foo`.

  * Descendent selectors (`E F`).

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

  * Adjacent selectors (`E + F`).

      E.g., `stew.select( dom, 'h1 + p')` selects all `p` tags that immediately follow an `h1` tag.

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
// etc.
```

### Regular Expressions

Stew extends the CSS selector syntax by allowing the use of regular expressions to specify tag names, class names, ids, and attributes (both name and value).

For example,

```javascript
var metadata = stew.select(dom,'a[href=/^https?:/i]');
```

will select all anchor (`<a>`)tags with an `href` attribute that starts with `http:` or `https:` (with a case-insensitive comparison).

Another example:

```javascript
var metadata = stew.select(dom,'[/^data-/]');
```

selects all tags with an attribute whose name starts with `data-`.

Any name or value that starts and ends with `/` will be treated as a regular expression. (Or, more accurately, any name or value that starts with `/` and ends with `/` with an optional suffix of any combination of the letters `g`, `m` and `i`.  E.g., `/example/gi`.)

The regular expression is processed using JavaScript's standard regular expression syntax, including support for `\b` and other special class markers.

Here are some example CSS selectors using regular expressions:

  * Tag names: `/^d[aeiou]ve?$/` matches `div`, but also `dove`, `dave`, etc.
  * Class names: `./^nav/` matches any tag with a class name that starts with the string `nav`.
  * IDs: `#/^main$/i` matches any tag with the id `main`, using a case insensitive comparision (so it also matches `MAIN`, `Main` and other variants.
  * Attribute names: As above, `[/^data-/]` matches any tag with an attribute whose name starts with `data-`.
  * Attribute values: As above, `[href=/^https?:/i]` matches any tag with an `href` attribute whose value starts with `http:` or `https:` (case-insensitive).

These may be used in any combination, and freely mixed with "regular" CSS selectors.

## Licensing

The Stew library and related documentation are made available under an [MIT License](http://opensource.org/licenses/MIT).  For details, please see the file [MIT-LICENSE.txt](MIT-LICENSE.txt) in the root directory of the repository.
