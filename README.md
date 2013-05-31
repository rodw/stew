# Stew

[Stew](https://github.com/rodw/stew) is a meatier soup.

[Stew](https://github.com/rodw/stew) is a JavaScript library that is used to select elements from a DOM structure using a beefed-up version the (CSS selector)[http://www.w3.org/TR/CSS2/selector.html] syntax. Stew often used as a toolkit for "screen-scrapting" web pages (extracting data from HTML and XML documents).

For example, given a variable `dom` containing a document tree, the JavaScript snippet:

```javascript
var links = stew.select(dom,'a[href]');
```

will return an array of all the anchor tags (`<a>`) found in `dom` that include an `href` attribute.

(The name "stew" is inspired by the Python library [BeautifulSoup](http://www.crummy.com/software/BeautifulSoup/), Simon Willison's [soupselect](http://code.google.com/p/soupselect/) extension of *BeautifulSoup*, and and Harry Fuecks' [Node.js port](https://github.com/harryf/node-soupselect) of *soupselect*.)
