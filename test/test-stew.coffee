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
    selector = @stew.parse_selectors('tag .foo #bar [/x/i] [y=/z/]')
    selector.length.should.equal 5
    selector[0]({name:'tag'}).should.be.ok
    selector[0]({name:'zzz'}).should.not.be.ok
    selector[1]({name:'tag',attribs:{class:'foo'}}).should.be.ok
    selector[2]({name:'tag',attribs:{id:'bar'}}).should.be.ok
    selector[3]({name:'tag',attribs:{X:null}}).should.be.ok
    selector[3]({name:'tag',attribs:{x:'foo'}}).should.be.ok
    selector[3]({name:'tag',attribs:{x:'z'}}).should.be.ok
    selector[3]({name:'tag',attribs:{y:'foo'}}).should.not.be.ok
    selector[4]({name:'tag',attribs:{y:'z'}}).should.be.ok
    selector[4]({name:'tag',attribs:{y:null}}).should.not.be.ok
    done()

  describe "Selectors",->

    # E - Matches any E element (i.e., an element of type E). - Type selectors
    it 'support the type selector',(done)->
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

    it 'support the type selector with regexp',(done)->
      nodeset = @stew.select(@DOM,'/E*x?M/i')
      nodeset.length.should.equal 2
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'html'
      nodeset[1].type.should.equal 'tag'
      nodeset[1].name.should.equal 'em'
      done()

    # E F -  any F element that is a descendant of an E element. - Descendant selectors
    it 'support the descendant selector',(done)->
      # `div span`
      nodeset = @stew.select(@DOM,'div span')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      # `html span`
      nodeset = @stew.select(@DOM,'html span')
      nodeset.length.should.equal 1
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

    # E F -  any F element that is a descendant of an E element. - Descendant selectors
    it 'support the descendant selector with regexp',(done)->
      nodeset = @stew.select(@DOM,'div /s[tp][aeiou]+n/')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'span'
      done()

    # E[foo] - Matches any E element with the "foo" attribute set (whatever the value). - Attribute selectors
    it 'support the attribute selector',(done)->
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
      #
      nodeset = @stew.select(@DOM,'b[/fo+/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      #
      done()


    # E[foo="warning"] - Matches any E element whose "foo" attribute value is exactly equal to "warning". - Attribute selectors
    it 'support the attribute-value selector',(done)->
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
      nodeset = @stew.select(@DOM,'b[/fo+/=/ba?r/]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'b'
      #
      nodeset = @stew.select(@DOM,'div[id=inner-1-1]')
      nodeset.length.should.equal 1
      nodeset[0].type.should.equal 'tag'
      nodeset[0].name.should.equal 'div'
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
      nodeset = @stew.select(@DOM,'div[class~=inner]')
      nodeset.length.should.equal 4
      for node in nodeset
        node.type.should.equal 'tag'
        node.name.should.equal 'div'
      #
      done()


#-------------------------------------------------------------------------------
# *                 Matches any element.                                                                                                                      Universal selector
# E > F             Matches any F element that is a child of an element E.                                                                                    Child selectors
# E:first-child     Matches element E when E is the first child of its parent.                                                                                The :first-child pseudo-class
# E:link
# E:visited         Matches element E if E is the source anchor of a hyperlink of which the target is not yet visited (:link) 	                              The link pseudo-classes
# E:active	         or already visited (:visited).
# E:hover           Matches E during certain user actions.
# E:focus           Matches E during certain user actions.                                                                                                    The dynamic pseudo-classes
# E:lang(c)         Matches element of type E if it is in (human) language c (the document language specifies how language is determined).                    The :lang() pseudo-class
# E + F             Matches any F element immediately preceded by a sibling element E.                                                                        Adjacent selectors
# E[foo~="warning"]	Matches any E element whose "foo" attribute value is a list of space-separated values, one of which is exactly equal to "warning".        Attribute selectors
# E[lang|="en"]     Matches any E element whose "lang" attribute has a hyphen-separated list of values beginning (from the left) with "en".                   Attribute selectors
# DIV.warning       Language specific. (In HTML, the same as DIV[class~="warning"].)                                                                          Class selectors
# E#myid            Matches any E element with ID equal to "myid".                                                                                            ID selectors
#-------------------------------------------------------------------------------

TEST_HTML = """
<html>
  <body>
    <div class="outer odd" id="outer-1">
      <div class="inner odd" id="inner-1-1"><span width=17>A</span></div>
      <div class="inner even" id="inner-1-2"><b foo="bar">B</b></div>
    </div>
    <div class="outer even" id="outer-2">
      <div class="inner odd" id="inner-2-1"><b><i>C<i></b></div>
      <div class="inner even" id="inner-2-2"><em>D</em></div>
    </div>
  </body>
</html>
"""
