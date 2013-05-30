should           = require 'should'
fs               = require 'fs'
path             = require 'path'
HOMEDIR          = path.join(__dirname,'..')
LIB_DIR          = if fs.existsSync(path.join(HOMEDIR,'lib-cov')) then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
#-------------------------------------------------------------------------------
htmlparser       = require 'htmlparser'
Stew             = require(path.join(LIB_DIR,'stew')).Stew
#-------------------------------------------------------------------------------

HTMLPARSER_OPTIONS =
  ignoreWhitespace:  false
  caseSensitiveTags: false
  caseSensitiveAttr: false

TEST_HTML = """
<html>
  <body>
    <div class="outer odd" id="outer-1">
      <div class="inner odd" id="inner-1-1"><span width=17>A</span></div>
      <div class="inner even" id="inner-1-2"><b foo="bar">B</b></div>
    </div>
    <div class="outer even" id="outer-2">
      <div class="inner odd" id="inner-2-1"><b fact="white space is ok here"><i>C</i></b></div>
      <div class="inner even" id="inner-2-2"><em>D</em></div>
    </div>
    <section>
      <span id="escaped-quote-test" label="this label includes \\\"escaped\\\" quotes"></span>
    </section>
  </body>
</html>
"""

describe "Stew",->

  beforeEach (done)->
    @stew = new Stew()
    handler = new htmlparser.DefaultHandler (err, dom)=>
      @DOM = dom
      done()
    parser = new htmlparser.Parser(handler,HTMLPARSER_OPTIONS)
    parser.parseComplete(TEST_HTML)

  afterEach (done)=>
    @stew = null
    @DOM = null
    done()

  it 'can parse a selector string into a list of predictes ',(done)->
    selector = @stew._parse_selectors('tag .foo #bar [/x/i] [y=/z/]')
    # _parse_selectors now returns a single function rather than array of them
    (typeof selector).should.equal 'function'
    done()

  describe "select()",->

    # * - Matches any tag
    it 'supports the any-tag selector (`*`)',(done)->
      # `div *`
      nodeset = @stew.select(@DOM,'div *')
      nodeset.length.should.equal 9
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-1-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'span'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'div'
      nodeset[2].attribs.id.should.equal 'inner-1-2'
      nodeset[3].type.should.equal 'tag'
      nodeset[3].name.should.equal 'b'
      nodeset[4].type.should.equal 'tag'
      nodeset[4].name.should.equal 'div'
      nodeset[4].attribs.id.should.equal 'inner-2-1'
      nodeset[5].type.should.equal 'tag'
      nodeset[5].name.should.equal 'b'
      nodeset[6].type.should.equal 'tag'
      nodeset[6].name.should.equal 'i'
      nodeset[7].type.should.equal 'tag'
      nodeset[7].name.should.equal 'div'
      nodeset[7].attribs.id.should.equal 'inner-2-2'
      nodeset[8].type.should.equal 'tag'
      nodeset[8].name.should.equal 'em'
      done()

    # E - Matches any E element (i.e., an element of type E). - Type selectors
    it 'supports the type selector (`E`) (string case)',(done)->
      # `em`
      nodeset = @stew.select(@DOM,'em')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'em'
      # `div`
      nodeset = @stew.select(@DOM,'div')
      nodeset.length.should.equal 6
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      # done
      done()

    it 'supports the type selector (`E`)  (regexp case)',(done)->
      nodeset = @stew.select(@DOM,'/E*x?M/i')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'html'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'em'
      done()

    # E F -  any F element that is a descendant of an E element. - Descendant selectors
    it 'supports the descendant selector (`E F`) (string case)',(done)->
      # `div span`
      nodeset = @stew.select(@DOM,'div span')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      # `html span`
      nodeset = @stew.select(@DOM,'html span')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      # `html body div span`
      nodeset = @stew.select(@DOM,'html body div span')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      # `div div`
      nodeset = @stew.select(@DOM,'div div')
      nodeset.length.should.equal 4
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      # `body div`
      nodeset = @stew.select(@DOM,'body div')
      nodeset.length.should.equal 6
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      # done
      done()

    it 'supports the descendant selector (`E F`) (regexp case)',(done)->
      nodeset = @stew.select(@DOM,'div /s[tp][aeiou]+n/') # select `div span` or `div stan` or `div spin`, etc,
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      done()

    # E > F -  any F element that is a child of an E element. - Child selectors
    it 'supports the child selector (`E > F`) (string case)',(done)->
      # `body > div`
      nodeset = @stew.select(@DOM,'body div')
      nodeset.length.should.equal 6
      nodeset = @stew.select(@DOM,'body > div')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'outer-2'
      #
      done()

    it 'supports the child selector (`E > F`) (regexp case)',(done)->
      # `body > /d[aeiou]ve?/`
      nodeset = @stew.select(@DOM,'body /d[aeiou]ve?/')
      nodeset.length.should.equal 6
      nodeset = @stew.select(@DOM,'body > /d[aeiou]ve?/')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'outer-2'
      #
      done()

    # E[foo] - Matches any E element with the "foo" attribute set (whatever the value). - Attribute selectors
    it 'supports the attribute selector (`E[foo]`) (string case)',(done)->
      #
      nodeset = @stew.select(@DOM,'b[foo]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      #
      nodeset = @stew.select(@DOM,'div b[foo]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      done()

    it 'supports the attribute selector (`E[foo]`) (regexp case)',(done)->
      nodeset = @stew.select(@DOM,'b[/fo+/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      #
      done()


    # E[foo="warning"] - Matches any E element whose "foo" attribute value is exactly equal to "warning". - Attribute selectors
    it 'supports the attribute-value selector (`E[foo="bar"]`) (unquoted string case)',(done)->
      #
      nodeset = @stew.select(@DOM,'[width=17]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      #
      nodeset = @stew.select(@DOM,'b[foo=bar]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      #
      nodeset = @stew.select(@DOM,'div [foo=bar]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      #
      nodeset = @stew.select(@DOM,'div b[foo=foo]')
      nodeset.length.should.equal 0
      #
      nodeset = @stew.select(@DOM,'div[id=inner-1-1]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      #
      done()

    it 'supports the attribute-value selector (`E[foo="bar"]`) (quoted string case)',(done)->
      #
      nodeset = @stew.select(@DOM,'b[foo="bar"]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      #
      nodeset = @stew.select(@DOM,'div[id="inner-1-1"]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      #
      done()

    it 'supports the attribute-value selector (`E[foo="bar"]`) (regexp case)',(done)->
      #
      nodeset = @stew.select(@DOM,'b[/fo+/=/ba?r/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      #
      nodeset = @stew.select(@DOM,'div[id=/inner-1/]')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      #
      nodeset = @stew.select(@DOM,'div[class=inner]')
      nodeset.length.should.equal 0
      nodeset = @stew.select(@DOM,'div[class=/inner/]')
      nodeset.length.should.equal 4
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      #
      done()

    # E[foo~="warning"] - Matches any E element whose "foo" attribute value is a list of space-separated values, one of which is exactly equal to "warning".
    it 'supports the ~= operator in the attribute-value selector (`E[foo~="bar"]`) (string case)',(done)->
      #
      nodeset = @stew.select(@DOM,'div[class~=inner]')
      nodeset.length.should.equal 4
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      #
      nodeset = @stew.select(@DOM,'div[class~=odd]')
      nodeset.length.should.equal 3
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      #
      nodeset = @stew.select(@DOM,'[fact~=space]')
      nodeset.length.should.equal 1
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'b'
      #
      nodeset = @stew.select(@DOM,'[foo~=bar]')
      nodeset.length.should.equal 1
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'b'
      #
      nodeset = @stew.select(@DOM,'[zzz~=in]')
      nodeset.length.should.equal 0
      #
      done()

    it 'supports the ~= operator in the attribute-value selector (`E[foo~="bar"]`) (regex case)',(done)->
      #
      nodeset = @stew.select(@DOM,'div[class~=/inn/]')
      nodeset.length.should.equal 4
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      #
      nodeset = @stew.select(@DOM,'div[class~=/inner/]')
      nodeset.length.should.equal 4
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      #
      nodeset = @stew.select(@DOM,'div[id~=/(1|2)-1/]')
      nodeset.length.should.equal 2
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      #
      nodeset = @stew.select(@DOM,'[fact~=/space/]')
      nodeset.length.should.equal 1
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'b'
      #
      nodeset = @stew.select(@DOM,'[class~=/..t.r/]')
      nodeset.length.should.equal 2
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      #
      nodeset = @stew.select(@DOM,'[foo~=/^bar$/]')
      nodeset.length.should.equal 1
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'b'
      #
      nodeset = @stew.select(@DOM,'[foo~=/^car$/]')
      nodeset.length.should.equal 0
      #
      done()

    # TODO - handle escaping better (at all?)
    # it 'supports escaped quotation marks within quoted strings',(done)->
    #   nodeset = @stew.select(@DOM,'[label="this label includes \\"escaped\\" text]')
    #   nodeset.length.should.equal 1
    #   for node in nodeset
    #     node.type.should.equal 'tag'
    #     node.name.should.equal 'span'
    #     node.attribs.id.should.equal 'escaped-quote-test'
    #   done()

    # E:first-child     Matches element E when E is the first child of its parent.                                                                                The :first-child pseudo-class
    it 'supports the :first-child pseudo class (`E:first-child`) (string case)',(done)->
      nodeset = @stew.select(@DOM,'div:first-child')
      nodeset.length.should.equal 3
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'inner-1-1'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'div'
      nodeset[2].attribs.id.should.equal 'inner-2-1'
      #
      nodeset = @stew.select(@DOM,'section:first-child')
      nodeset.length.should.equal 0
      #
      nodeset = @stew.select(@DOM,'body section span:first-child')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      nodeset[0].attribs.id.should.equal 'escaped-quote-test'
      #
      done()


    # E + F - any F element immediately preceded by a sibling element E - Adjacent selectors
    it 'supports the adjacent selector (`E + F`) (string case)',(done)->
      nodeset = @stew.select(@DOM,'div div')
      nodeset.length.should.equal 4
      nodeset = @stew.select(@DOM,'div + div')
      nodeset.length.should.equal 3
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-1-2'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'outer-2'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'div'
      nodeset[2].attribs.id.should.equal 'inner-2-2'
      #
      done()

    # E + F - any F element immediately preceded by a sibling element E - Adjacent selectors
    it 'supports the adjacent selector (`E + F`) (reg case)',(done)->
      nodeset = @stew.select(@DOM,'/(div)|(dove)/ /(div)|(dave)/')
      nodeset.length.should.equal 4
      nodeset = @stew.select(@DOM,'/(div)|(dove)/ + /(div)|(dave)/')
      nodeset.length.should.equal 3
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-1-2'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'outer-2'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'div'
      nodeset[2].attribs.id.should.equal 'inner-2-2'
      #
      done()

#-------------------------------------------------------------------------------
# E:link
# E:visited         Matches element E if E is the source anchor of a hyperlink of which the target is not yet visited (:link) 	                              The link pseudo-classes
# E:active	         or already visited (:visited).
# E:hover           Matches E during certain user actions.
# E:focus           Matches E during certain user actions.                                                                                                    The dynamic pseudo-classes
# E:lang(c)         Matches element of type E if it is in (human) language c (the document language specifies how language is determined).                    The :lang() pseudo-class

# E + F             Matches any F element immediately preceded by a sibling element E.                                                                        Adjacent selectors
# DIV.warning       Language specific. (In HTML, the same as DIV[class~="warning"].)                                                                          Class selectors
# E#myid            Matches any E element with ID equal to "myid".                                                                                            ID selectors
#-------------------------------------------------------------------------------
