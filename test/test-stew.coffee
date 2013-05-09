should           = require 'should'
fs               = require 'fs'
path             = require 'path'
HOMEDIR          = path.join(__dirname,'..')
LIB_DIR          = if fs.existsSync(path.join(HOMEDIR,'lib-cov')) then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
#-------------------------------------------------------------------------------
htmlparser       = require 'htmlparser'
Stew             = require(path.join(LIB_DIR,'stew')).Stew
PredicateFactory = require(path.join(LIB_DIR,'stew')).PredicateFactory
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# *                 Matches any element.                                                                                                                      Universal selector
# E                 Matches any E element (i.e., an element of type E).                                                                                       Type selectors
# E F               Matches any F element that is a descendant of an E element.                                                                               Descendant selectors
# E > F             Matches any F element that is a child of an element E.                                                                                    Child selectors
# E:first-child     Matches element E when E is the first child of its parent.                                                                                The :first-child pseudo-class
# E:link
# E:visited         Matches element E if E is the source anchor of a hyperlink of which the target is not yet visited (:link) 	                              The link pseudo-classes
# E:active	         or already visited (:visited).
# E:hover           Matches E during certain user actions.
# E:focus           Matches E during certain user actions.                                                                                                    The dynamic pseudo-classes
# E:lang(c)         Matches element of type E if it is in (human) language c (the document language specifies how language is determined).                    The :lang() pseudo-class
# E + F             Matches any F element immediately preceded by a sibling element E.                                                                        Adjacent selectors
# E[foo]            Matches any E element with the "foo" attribute set (whatever the value).                                                                  Attribute selectors
# E[foo="warning"]	Matches any E element whose "foo" attribute value is exactly equal to "warning".                                                          Attribute selectors
# E[foo~="warning"]	Matches any E element whose "foo" attribute value is a list of space-separated values, one of which is exactly equal to "warning".        Attribute selectors
# E[lang|="en"]     Matches any E element whose "lang" attribute has a hyphen-separated list of values beginning (from the left) with "en".                   Attribute selectors
# DIV.warning       Language specific. (In HTML, the same as DIV[class~="warning"].)                                                                          Class selectors
# E#myid            Matches any E element with ID equal to "myid".                                                                                            ID selectors
#-------------------------------------------------------------------------------

HTMLPARSER_OPTIONS =
  ignoreWhitespace:  false
  caseSensitiveTags: false
  caseSensitiveAttr: false

describe "Stew",->

  beforeEach (done)->
    @stew = new Stew()
    @factory = new PredicateFactory()
    handler = new htmlparser.DefaultHandler (err, dom)=>
      @DOM = dom
      done()
    parser = new htmlparser.Parser(handler,HTMLPARSER_OPTIONS)
    parser.parseComplete(TEST_HTML)

  afterEach (done)=>
    @stew = null
    @factory = null
    @DOM = null
    done()

  describe "PredicateFactory",->

    describe "by_class_predicate",->

      it 'can handle undefined nodes and other edge cases',(done)->
        @factory.make_by_class_predicate('x')(null).should.not.be.ok
        @factory.make_by_class_predicate('x')({}).should.not.be.ok
        @factory.make_by_class_predicate('x')({ attribs:[]}).should.not.be.ok
        @factory.make_by_class_predicate('x')({ attribs:{}}).should.not.be.ok
        @factory.make_by_class_predicate('x')({ attribs:{class:null}}).should.not.be.ok
        done()

      it 'is case sensitive',(done)->
        node = { attribs: { class: 'FOO' } }
        @factory.make_by_class_predicate('foo')(node).should.not.be.ok
        @factory.make_by_class_predicate('FOO')(node).should.be.ok
        done()

      it 'returns true if the given string is an exact match for the node\'s class',(done)->
        node = { attribs: { class: 'foo' } }
        @factory.make_by_class_predicate('foo')(node).should.be.ok
        @factory.make_by_class_predicate('bar')(node).should.not.be.ok
        @factory.make_by_class_predicate('food')(node).should.not.be.ok
        done()

      it 'returns true if the given string is an exact match to one of the node\'s many classes',(done)->
        node = { attribs: { class: 'foo bar' } }
        @factory.make_by_class_predicate('foo')(node).should.be.ok
        @factory.make_by_class_predicate('bar')(node).should.be.ok
        @factory.make_by_class_predicate('food')(node).should.not.be.ok
        @factory.make_by_class_predicate('oo')(node).should.not.be.ok
        @factory.make_by_class_predicate('o b')(node).should.not.be.ok
        @factory.make_by_class_predicate('o ba')(node).should.not.be.ok
        @factory.make_by_class_predicate('foo bar')(node).should.not.be.ok
        done()

      it 'returns true if the given regex matches the node\'s class',(done)->
        node = { attribs: { class: 'foo' } }
        @factory.make_by_class_predicate(/foo/)(node).should.be.ok
        @factory.make_by_class_predicate(/^foo$/)(node).should.be.ok
        @factory.make_by_class_predicate(/fo+/)(node).should.be.ok
        @factory.make_by_class_predicate(/o/)(node).should.be.ok
        @factory.make_by_class_predicate(/^f/)(node).should.be.ok
        @factory.make_by_class_predicate(/f$/)(node).should.not.be.ok
        @factory.make_by_class_predicate(/f[aeiou]{2}$/)(node).should.be.ok
        @factory.make_by_class_predicate(/f[aeiou]{3}$/)(node).should.not.be.ok
        @factory.make_by_class_predicate(/FOO/i)(node).should.be.ok
        done()

      it 'returns true if the given regex matches one of the node\'s class',(done)->
        node = { attribs: { class: 'x foo bar' } }
        @factory.make_by_class_predicate(/foo/)(node).should.be.ok
        @factory.make_by_class_predicate(/^foo$/)(node).should.be.ok
        @factory.make_by_class_predicate(/fo+/)(node).should.be.ok
        @factory.make_by_class_predicate(/o/)(node).should.be.ok
        @factory.make_by_class_predicate(/^f/)(node).should.be.ok
        @factory.make_by_class_predicate(/f$/)(node).should.not.be.ok
        @factory.make_by_class_predicate(/f[aeiou]{2}$/)(node).should.be.ok
        @factory.make_by_class_predicate(/f[aeiou]{3}$/)(node).should.not.be.ok
        @factory.make_by_class_predicate(/FOO/i)(node).should.be.ok
        @factory.make_by_class_predicate(/bar/)(node).should.be.ok
        done()

    describe "by_attr_value_predicate",->

      it 'returns true if the value of the given attribute name matches the given string',(done)->
        node = { attribs: { foo: 'bar qux' } }
        @factory.make_by_attr_value_predicate('foo','bar qux')(node).should.be.ok
        @factory.make_by_attr_value_predicate('foo','bar')(node).should.not.be.ok
        @factory.make_by_attr_value_predicate('bar','bar qux')(node).should.not.be.ok
        done()

      it 'returns true if the value of the given attribute name matches the given regex',(done)->
        node = { attribs: { foo: 'bar qux' } }
        @factory.make_by_attr_value_predicate('foo',/bar qux/)(node).should.be.ok
        @factory.make_by_attr_value_predicate('foo',/^BAR\squx$/i)(node).should.be.ok
        @factory.make_by_attr_value_predicate('foo',/bar/)(node).should.be.ok
        done()

      it 'can be used with the class attribute',(done)->
        node = { attribs: { class: 'foo' } }
        @factory.make_by_attr_value_predicate('class','foo')(node).should.be.ok
        @factory.make_by_attr_value_predicate('class','fo')(node).should.not.be.ok
        @factory.make_by_attr_value_predicate('class','bar')(node).should.not.be.ok
        @factory.make_by_attr_value_predicate('class','food')(node).should.not.be.ok
        node = { attribs: { class: 'foo bar' } }
        @factory.make_by_attr_value_predicate('class','foo bar')(node).should.be.ok
        @factory.make_by_attr_value_predicate('class','foo')(node).should.not.be.ok
        @factory.make_by_attr_value_predicate('class','bar')(node).should.not.be.ok
        @factory.make_by_attr_value_predicate('class',/foo/)(node).should.be.ok
        @factory.make_by_attr_value_predicate('class',/bar/)(node).should.be.ok
        @factory.make_by_attr_value_predicate('class',/^foo b/)(node).should.be.ok
        @factory.make_by_attr_value_predicate('class',/^foo$/)(node).should.not.be.ok
        done()

    describe "by_attr_exists_predicate",->

      it 'returns true if the given attribute exists',(done)->
        node = { attribs: { foo: 'bar' } }
        @factory.make_by_attr_exists_predicate('foo')(node).should.be.ok
        @factory.make_by_attr_exists_predicate(/^fO{2}$/i)(node).should.be.ok
        @factory.make_by_attr_exists_predicate('bar')(node).should.not.be.ok
        @factory.make_by_attr_exists_predicate(/bar/)(node).should.not.be.ok
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

TEST_HTML = """
<html>
  <body>
    <div class="outer odd" id="outer-1">
      <div class="inner odd" id="inner-1-1">A</div>
      <div class="inner even" id="inner-1-2">B</div>
    </div>
    <div class="outer even" id="outer-2">
      <div class="inner odd" id="inner-2-1">C</div>
      <div class="inner even" id="inner-2-2">D</div>
    </div>
  </body>
</html>
"""
