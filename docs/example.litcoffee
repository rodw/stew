# Scraping Headlines Using Stew
*This is a complete (but simple) example of using [Stew](https://github.com/rodw/stew) to extract content from the web.*

In this example, we'll extract headlines from the venerable social-tech-news site [Slashdot](http://slashdot.org/).

    URL = 'http://slashdot.org/'

If you examine the HTML of the Slashdot homepage carefully, you'll find that each headline is contained in an `h2` tag with the class `story`, and that within this heading there is an anchor (`a`) tag that contains the link.  As a CSS selector, that looks like:

    SELECTOR = 'h2.story a'

We'll use that selector to extract the headlines and links from the HTML, and print them to the console with the following function:

    print_headline = (node)->
      headline = node.children[0].raw
      link = "http:#{node.attribs.href}"
      console.log "#{headline} <#{link}>"

Now, given a DOM object, extracting the headlines and printing them out is as simple as this:

    select_and_print_headlines = (dom)->
      nodeset = stew.select( dom, SELECTOR )
      for node in nodeset
        print_headline(node)

but we'll need to jump through some hoops to download the page and parse it into a DOM structure..

## Importing the Library

When using Stew, you'll typically import the library using something like this:

    # This is what you'll typically do:
    # stew = new (require('stew')).Stew()

but since this file is found *within* the Stew repository itself, we'll do things a little differently.  Most readers can safely ignore these next few lines and use the simple `require` statement above instead.

    # You WON'T do the following. We're only doing it here because we
    # want to use the "local" implementation of Stew.
    fs          = require 'fs'
    path        = require 'path'
    HOMEDIR     = path.join(__dirname,'..')
    LIB_COV_DIR = path.join(HOMEDIR,'lib-cov')
    LIB_DIR     = if fs.existsSync(LIB_COV_DIR) then LIB_COV_DIR else path.join(HOMEDIR,'lib')
    Stew        = require(path.join(LIB_DIR,'stew')).Stew
    stew        = new Stew()

## Setting up the HTML Parser

Stew doesn't do any HTML parsing directly so we'll use [Chris Winberry's htmlparser](https://github.com/tautologistics/node-htmlparser/) to parse the source HTML into a DOM structure.

    htmlparser       = require 'htmlparser'

And we'll configure `htmlparser` as follows:

    HTMLPARSER_OPTIONS =
      ignoreWhitespace:  false
      caseSensitiveTags: false
      caseSensitiveAttr: false


## Setting up the HTTP "Fetcher"

Let's define a function that will fetch a web page, parse it and then pass the resulting DOM to a callback function.  We'll use the Node.js `http` library for this.

    http = require 'http'

Our function will accept the `url` for the document to download and a `callback` function to invoke once the document is parsed.

Following Node.js convention, we'll use the signature `callback(err,dom)` for the callback function.

    fetch = (url,callback)->

First we'll set up an `htmlparser.Parser` instance to parse the HTML content and pass the resulting DOM to the callback function.

      html_handler = new htmlparser.DefaultHandler(callback)
      parser = new htmlparser.Parser(html_handler,HTMLPARSER_OPTIONS)

Next, we'll create an callback function to buffer the HTTP response:

      http_callback = (response)->
        unless 200 <= response.statusCode <= 299
          callback "Unexpected status code #{response.statusCode}"
        else
          buffer = ""
          response.setEncoding 'utf8'
          response.on 'data', (chunk)->buffer += chunk

and, when the full response body has been recieved, invoke our HTML parser:

          response.on 'end', ()-> parser.parseComplete(buffer)

Finally, we can trigger the actual request:

      http.get(url, http_callback).on('error', callback)

Now our `fetch` method will download content from the URL, parse it, and pass the resulting DOM object to our callback function.

## DOM Processing

Now we can fetch the document and process the resulting DOM object.

    fetch URL, (err,dom)->
      if err?
        console.error "Error:", err
      else
        select_and_print_headlines dom

## Running this script

Now we can run this script by typing:

    coffee docs/example.litcoffee

and see output like the following:

    DRM: How Book Publishers Failed To Learn From the Music Industry <http://news.slashdot.org/story/13/05/31/2045211/drm-how-book-publishers-failed-to-learn-from-the-music-industry>
    Small Black Holes: Cloudy With a Chance of Better Visibility <http://science.slashdot.org/story/13/05/31/214224/small-black-holes-cloudy-with-a-chance-of-better-visibility>
    No, the Tesla Model S Doesn't Pollute More Than an SUV <http://tech.slashdot.org/story/13/05/31/1955214/no-the-tesla-model-s-doesnt-pollute-more-than-an-suv>
    The Case For a Government Bug Bounty Program <http://it.slashdot.org/story/13/05/31/1933231/the-case-for-a-government-bug-bounty-program>
    When Smart Developers Generate Crappy Code <http://developers.slashdot.org/story/13/05/31/1854203/when-smart-developers-generate-crappy-code>
    New York City Wants To Revive Old Voting Machines <http://tech.slashdot.org/story/13/05/31/1748201/new-york-city-wants-to-revive-old-voting-machines>
    Big Asteroid (With Its Own Moon) To Have Closest Approach With Earth Today <http://science.slashdot.org/story/13/05/31/1727256/big-asteroid-with-its-own-moon-to-have-closest-approach-with-earth-today>
    Google Maps Used To Find Tax Cheats <http://tech.slashdot.org/story/13/05/31/1721232/google-maps-used-to-find-tax-cheats>
    Judge Orders Google To Comply With FBI's Warrantless NSL Requests <http://yro.slashdot.org/story/13/05/31/1633209/judge-orders-google-to-comply-with-fbis-warrantless-nsl-requests>
    Ask Slashdot: How Important Is Advanced Math In a CS Degree? <http://ask.slashdot.org/story/13/05/31/1546253/ask-slashdot-how-important-is-advanced-math-in-a-cs-degree>
    Badgers Block British Broadband Buildout <http://news.slashdot.org/story/13/05/31/1530227/badgers-block-british-broadband-buildout>
    Confirmed: Water Once Flowed On Mars <http://science.slashdot.org/story/13/05/31/1523245/confirmed-water-once-flowed-on-mars>
    Motorola Developing Pill and Tattoo Authentication Methods <http://it.slashdot.org/story/13/05/31/1414210/motorola-developing-pill-and-tattoo-authentication-methods>
    Seeing Atomic Bonds Before and After Reactions <http://science.slashdot.org/story/13/05/31/1353241/seeing-atomic-bonds-before-and-after-reactions>
    U.S. Authorizes Sales of American Communication Tech To Iran <http://news.slashdot.org/story/13/05/31/145229/us-authorizes-sales-of-american-communication-tech-to-iran>
