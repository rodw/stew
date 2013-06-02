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
      <div class="inner odd" id="inner-1-1" lang="en-gb"><span width=17>A</span></div>
      <div class="inner even" id="inner-1-2" lang="en"><b foo="bar">B</b></div>
    </div>
    <div class="outer even" id="outer-2">
      <div class="inner odd" id="inner-2-1" lang="en-us"><b fact="white space is ok here"><i>C</i></b></div>
      <div class="inner even" id="inner-2-2"><em extra="contains spaces, commas and symbols like + and /">D</em></div>
    </div>
    <section>
      <span id="escaped-quote-test" label='this label includes "quote" marks'></span>
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

  describe "select_first()",->
    it 'supports the any-tag selector (`*`)',(done)->
      node = @stew.select_first(@DOM,'div *')
      node.type.should.equal 'tag'
      node.name.should.equal 'div'
      node.attribs.id.should.equal 'inner-1-1'
      done()

    it 'supports the type selector (`E`)',(done)->
      node = @stew.select_first(@DOM,'em')
      node.type.should.equal 'tag'
      node.name.should.equal 'em'
      #
      node = @stew.select_first(@DOM,'div')
      node.type.should.equal 'tag'
      node.name.should.equal 'div'
      node.attribs.id.should.equal 'outer-1'
      # done
      done()

    it 'can also parse a string into a DOM automatically, if given a callback',(done)->
      @stew.select_first TEST_HTML,'em',(err,node)->
        node.type.should.equal 'tag'
        node.name.should.equal 'em'
        done()

    it 'throws an exception when given an HTML string but no callback',(done)->
      (()=>@stew.select_first(TEST_HTML, 'em')).should.throw(/callback/)
      done()

  describe "select()",->

    it 'can also parse a string into a DOM automatically, if given a callback',(done)->
      @stew.select TEST_HTML, 'em', (err,nodeset)->
        nodeset.length.should.equal 1
        nodeset[0].type.should.equal 'tag'
        nodeset[0].name.should.equal 'em'
        done()

    it 'throws an exception when given an HTML string but no callback',(done)->
      (()=>@stew.select(TEST_HTML, 'em')).should.throw(/callback/)
      done()

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

    # DIV.warning - Language specific. (In HTML, the same as DIV[class~="warning"].) - Class Selector
    it 'supports the class selector (`.warning`) (string case)',(done)->
      # `div.outer`
      nodeset = @stew.select(@DOM,'div.outer')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'outer-2'
      # `.outer`
      nodeset = @stew.select(@DOM,'.outer')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'outer-2'
      # `div.outer.odd`
      nodeset = @stew.select(@DOM,'div.outer.odd')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      # `.outer.odd`
      nodeset = @stew.select(@DOM,'.outer.odd')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      # `.outer.odd`
      nodeset = @stew.select(@DOM,'.odd.outer')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      # `.inner.even`
      nodeset = @stew.select(@DOM,'.inner.even')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-1-2'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'inner-2-2'
      # `*.odd *.even`
      nodeset = @stew.select(@DOM,'*.odd *.even')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-1-2'
      done()

    it 'supports the class selector (`.warning`) (regex case)',(done)->
      # `div.outer`
      nodeset = @stew.select(@DOM,'div./[ou]+ter/')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'outer-2'
      # `.outer`
      nodeset = @stew.select(@DOM,'./[ou]+ter/')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'outer-2'
      # `div./er$/`
      nodeset = @stew.select(@DOM,'div./er$/')
      nodeset.length.should.equal 6
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'inner-1-1'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'div'
      nodeset[2].attribs.id.should.equal 'inner-1-2'
      nodeset[3].type.should.equal 'tag'
      nodeset[3].name.should.equal 'div'
      nodeset[3].attribs.id.should.equal 'outer-2'
      nodeset[4].type.should.equal 'tag'
      nodeset[4].name.should.equal 'div'
      nodeset[4].attribs.id.should.equal 'inner-2-1'
      nodeset[5].type.should.equal 'tag'
      nodeset[5].name.should.equal 'div'
      nodeset[5].attribs.id.should.equal 'inner-2-2'
      # `div./er$/.odd`
      nodeset = @stew.select(@DOM,'div./er$/.odd')
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
      nodeset[2].type.should.equal 'tag'
      done()

    # E#myid - Matches any E element with ID equal to "myid" - ID selector
    it 'supports the id selector (`E#myid`) (string case)',(done)->
      # `div#outer-2`
      nodeset = @stew.select(@DOM,'div#outer-2')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-2'
      # `#outer-2`
      nodeset = @stew.select(@DOM,'#outer-2')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-2'
      # `div#outer-2.even`
      nodeset = @stew.select(@DOM,'div#outer-2.even')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-2'
      # `div#outer-2.odd`
      nodeset = @stew.select(@DOM,'div#outer-2.odd')
      nodeset.length.should.equal 0
      done()

    it 'supports the id selector (`E#myid`) (regex case)',(done)->
      # `div#/outer-[0-9]/`
      nodeset = @stew.select(@DOM,'div#/outer-[0-9]/')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'outer-2'
      # `#/outer-[0-9]/`
      nodeset = @stew.select(@DOM,'#/outer-[0-9]/')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'outer-2'
      # `#/outer-[0-9]/ b`
      nodeset = @stew.select(@DOM,'#/outer-[0-9]/ b')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      nodeset[0].attribs.foo.should.equal 'bar'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'b'
      nodeset[1].attribs.fact.should.equal 'white space is ok here'
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

    # E > F -  any F element that is a child of an E element. - Child selectors
    it 'supports the child selector without whitespace (`E>F`) (string case)',(done)->
      nodeset = @stew.select(@DOM,'body>div')
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

    it 'supports the attribute-value selector (`E[foo="bar"]`) (quoted string containing whitespace case)',(done)->
      nodeset = @stew.select(@DOM,'b[fact="white space is ok here"]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      nodeset[0].attribs.fact.should.equal 'white space is ok here'
      done()

    it 'supports the attribute-value selector (`E[foo="bar"]`) (regexp containing whitespace case)',(done)->
      nodeset = @stew.select(@DOM,'b[fact=/white space is ok here/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      nodeset[0].attribs.fact.should.equal 'white space is ok here'
      nodeset = @stew.select(@DOM,'b[fact=/white space/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      nodeset[0].attribs.fact.should.equal 'white space is ok here'
      nodeset = @stew.select(@DOM,'b[fact=/^white space.*ok here$/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      nodeset[0].attribs.fact.should.equal 'white space is ok here'
      nodeset = @stew.select(@DOM,'b[fact=/"?white\\s*space"? is ok\\s+here/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      nodeset[0].attribs.fact.should.equal 'white space is ok here'
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

    it 'supports the attribute-value selector (`E[foo="bar"]`) (extra symbols case)',(done)->
      nodeset = @stew.select(@DOM,'[extra="contains spaces, commas and symbols like + and /"]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'em'
      nodeset[0].attribs.extra.should.equal 'contains spaces, commas and symbols like + and /'
      nodeset = @stew.select(@DOM,'[extra=/contains spaces, commas and symbols like \\+/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'em'
      nodeset[0].attribs.extra.should.equal 'contains spaces, commas and symbols like + and /'

      nodeset = @stew.select(@DOM,'[extra=/^contains spaces, commas and symbols like \\+ and .$/]') # TODO support `\/` as a way to escape `/` in regexp patterns (replacing `.` here)
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'em'
      nodeset[0].attribs.extra.should.equal 'contains spaces, commas and symbols like + and /'
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

    it 'supports the |= operator in the attribute-value selector (`E[lang|="en"]`) (string case)',(done)->
      #
      nodeset = @stew.select(@DOM,'div[lang|="en"]')
      nodeset.length.should.equal 3
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-1-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'inner-1-2'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'div'
      nodeset[2].attribs.id.should.equal 'inner-2-1'
      #
      nodeset = @stew.select(@DOM,'div[lang|="en-us"]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-2-1'
      #
      done()

    it 'supports the |= operator in the attribute-value selector (`E[lang|="en"]`) (regexp case)',(done)->
      #
      nodeset = @stew.select(@DOM,'div[lang|=/EN/i]')
      nodeset.length.should.equal 3
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-1-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'inner-1-2'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'div'
      nodeset[2].attribs.id.should.equal 'inner-2-1'
      #
      nodeset = @stew.select(@DOM,'div[lang|=/en?/]')
      nodeset.length.should.equal 3
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-1-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'inner-1-2'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'div'
      nodeset[2].attribs.id.should.equal 'inner-2-1'
      #
      nodeset = @stew.select(@DOM,'div[lang|=/^en/]')
      nodeset.length.should.equal 3
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-1-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'inner-1-2'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'div'
      nodeset[2].attribs.id.should.equal 'inner-2-1'
      #
      nodeset = @stew.select(@DOM,'div[lang|=/[aeiou]n-[aeioug][sb]/]')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'inner-1-1'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'div'
      nodeset[1].attribs.id.should.equal 'inner-2-1'
      #
      done()

    # E:first-child - Matches element E when E is the first child of its parent. - The :first-child pseudo-class
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

    it 'supports the adjacent selector without whitespace (`E+F`) (string case)',(done)->
      nodeset = @stew.select(@DOM,'div+div')
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
    it 'supports the adjacent selector (`E + F`) (regexp case)',(done)->
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


    # E , F - all nodes matching E or F
    it 'supports the comma (or) operator (`E , F`) (string case)',(done)->
      nodeset = @stew.select(@DOM,'b , span')
      nodeset.length.should.equal 4
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      nodeset[0].attribs.width.should.equal '17'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'b'
      nodeset[1].attribs.foo.should.equal 'bar'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'b'
      nodeset[2].attribs.fact.should.equal 'white space is ok here'
      nodeset[3].type.should.equal 'tag'
      nodeset[3].name.should.equal 'span'
      nodeset[3].attribs.id.should.equal 'escaped-quote-test'
      #
      done()

    it 'supports the comma (or) operator without spaces (`E,F`) (string case)',(done)->
      nodeset = @stew.select(@DOM,'b,span')
      nodeset.length.should.equal 4
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      nodeset[0].attribs.width.should.equal '17'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'b'
      nodeset[1].attribs.foo.should.equal 'bar'
      nodeset[2].type.should.equal 'tag'
      nodeset[2].name.should.equal 'b'
      nodeset[2].attribs.fact.should.equal 'white space is ok here'
      nodeset[3].type.should.equal 'tag'
      nodeset[3].name.should.equal 'span'
      nodeset[3].attribs.id.should.equal 'escaped-quote-test'
      #
      done()

    it 'supports escaped quotation marks within quoted strings',(done)->
      nodeset = @stew.select(@DOM,'[label="this label includes \\"quote\\" marks"]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      nodeset[0].attribs.id.should.equal 'escaped-quote-test'
      #
      nodeset = @stew.select(@DOM,'[label=/^this label includes "quote" marks$/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      nodeset[0].attribs.id.should.equal 'escaped-quote-test'
      #
      done()

    it 'supports multiple attribute-based selectors in series (`E[a=b][c=d]`)',(done)->
      #
      nodeset = @stew.select(@DOM,'[class~="outer"][class~="odd"]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      #
      nodeset = @stew.select(@DOM,'[class=/outer/][class=/odd/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
      nodeset[0].attribs.id.should.equal 'outer-1'
      done()
