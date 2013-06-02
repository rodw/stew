# Scraping Headlines Using Stew

*This is a complete (but simple) example of using [Stew](https://github.com/rodw/stew) to extract content from the web.*

In this example, we'll extract headlines from the venerable social-tech-news site [Slashdot](http://slashdot.org/).

    URL = 'http://slashdot.org/'

If you examine the HTML of the Slashdot homepage carefully, you'll find that each headline is contained in an `h2` tag with the class `story`, and that within this heading there is an anchor (`a`) tag that contains the link.  As a CSS selector, that looks like:

    SELECTOR = 'h2.story a'

We'll use that selector to extract the headlines and links from the HTML print them to the console with the following function:

    print_headline = (node)->
      headline = domutil.to_text(node)
      link = "http:#{node.attribs.href}"
      console.log "#{headline} <#{link}>"

(`domutil` is an instance of Stew's `DOMUtil` type, which is imported below.)

Now, given an `html` string, selecting and printing the headlines is as simple as this:

    select_and_print_headlines = (html)->
      stew.select html, SELECTOR, (err,nodeset)->
        for node in nodeset
          print_headline node

but we'll need to jump through some hoops to download that HTML document.

## Importing the Library

When using Stew, you'll typically import the library using something like this:

    # This is what you'll typically do:
    # stew = new (require('stew-select')).Stew()
    # and/or
    # domutil = new (require('stew-select')).DOMUtil()

but since this file is found *within* the Stew repository itself, we'll do things a little differently.  Most readers can safely ignore these next few lines and use the simple `require` statement above instead.

    # You WON'T do the following. We're only doing it here because we
    # want to use the "local" implementation of Stew.
    fs          = require 'fs'
    path        = require 'path'
    HOMEDIR     = path.join(__dirname,'..')
    LIB_COV_DIR = path.join(HOMEDIR,'lib-cov')
    LIB_DIR     = if fs.existsSync(LIB_COV_DIR) then LIB_COV_DIR else path.join(HOMEDIR,'lib')
    stew        = new (require(path.join(LIB_DIR,'stew'))).Stew()
    domutil     = new (require(path.join(LIB_DIR,'stew'))).DOMUtil()

## Setting up the HTTP "Fetcher"

Let's define a function that will fetch a web page and pass the resulting content to a callback function.  We'll use the Node.js `http` library for this.

    http = require 'http'

Our function will accept the `url` for the document to download and a `callback` function to invoke once the document is parsed.

Following Node.js convention, we'll use the signature `callback(err,body)` for the callback function.

    fetch = (url,callback)->

Using `http`, we'll create an callback function to buffer the HTTP response:

      http_callback = (response)->
        unless 200 <= response.statusCode <= 299
          callback "Unexpected status code #{response.statusCode}"
        else
          buffer = ""
          response.setEncoding 'utf8'
          response.on 'data', (chunk)->buffer += chunk

and, when the full response body has been recieved, pass it to the callback:

          response.on 'end', ()-> callback(null,buffer)

Finally, we can trigger the actual request:

      http.get(url, http_callback).on('error', callback)

Now our `fetch` method will download content from the URL and pass it to a callback function.

## Actual processing

Now we can fetch the document and print the result using our `select_and_print` method:

    fetch URL, (err,body)->
      if err?
        console.error "Error:", err
      else
        console.log '-----------------------------------------'
        console.log "CURRENT HEADLINES AT #{URL}"
        console.log '-----------------------------------------'
        select_and_print_headlines body
        console.log '-----------------------------------------'

## Running this script

Now we can run this script by typing:

```console
coffee docs/example.litcoffee
```

and see output like the following:

```console
-----------------------------------------
CURRENT HEADLINES AT http://slashdot.org/
-----------------------------------------
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
-----------------------------------------
```
