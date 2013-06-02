# Stew's Version History and Release Notes


## Version 0.0.3 - Sunday 2-June-2013

 * Added support for the `|=` attribute-comparision-operator.

 * Added `select_first` method to `Stew`.

 * Exported `DOMUtil` class to the public. (`require('stew-select').DOMUtil`).

 * Added `to_html` and `inner_html` methods to `DOMUtil`.

 * Added `to_text` and `inner_text` methods to `DOMUtil`.

 * Added `parse_html` convenience method to `DOMUtil`.

 * Added variants of `Stew.select` and `Stew.select_first` that accept an HTML string (and invoke a callback).

 * Extended `Stew.select` and `Stew.select_first` to invoke a callback method if one is provided.

 * Documentation updated.

## Version 0.0.2 - Friday 31-May-2013

 * Additional documention.

 * Minor cleanup of the release package.

## Version 0.0.1 - Friday 31-May-2013

 * Initial release, includes `stew.select` with a nearly complete CSS selector syntax and regular expressions.
