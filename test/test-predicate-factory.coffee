should           = require 'should'
fs               = require 'fs'
path             = require 'path'
HOMEDIR          = path.join(__dirname,'..')
LIB_DIR          = if fs.existsSync(path.join(HOMEDIR,'lib-cov')) then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
#-------------------------------------------------------------------------------
PredicateFactory = require(path.join(LIB_DIR,'predicate-factory')).PredicateFactory
#-------------------------------------------------------------------------------
FACTORY = new PredicateFactory()

describe "PredicateFactory",->

  describe "by_class_predicate",->

    it 'can handle undefined nodes and other edge cases',(done)->
      FACTORY.by_class_predicate('x')(null).should.not.be.ok
      FACTORY.by_class_predicate('x')({}).should.not.be.ok
      FACTORY.by_class_predicate('x')({ attribs:[]}).should.not.be.ok
      FACTORY.by_class_predicate('x')({ attribs:{}}).should.not.be.ok
      FACTORY.by_class_predicate('x')({ attribs:{class:null}}).should.not.be.ok
      done()

    it 'is case sensitive',(done)->
      node = { attribs: { class: 'FOO' } }
      FACTORY.by_class_predicate('foo')(node).should.not.be.ok
      FACTORY.by_class_predicate('FOO')(node).should.be.ok
      done()

    it 'returns true if the given string is an exact match for the node\'s class',(done)->
      node = { attribs: { class: 'foo' } }
      FACTORY.by_class_predicate('foo')(node).should.be.ok
      FACTORY.by_class_predicate('bar')(node).should.not.be.ok
      FACTORY.by_class_predicate('food')(node).should.not.be.ok
      done()

    it 'returns true if the given string is an exact match to one of the node\'s many classes',(done)->
      node = { attribs: { class: 'foo bar' } }
      FACTORY.by_class_predicate('foo')(node).should.be.ok
      FACTORY.by_class_predicate('bar')(node).should.be.ok
      FACTORY.by_class_predicate('food')(node).should.not.be.ok
      FACTORY.by_class_predicate('oo')(node).should.not.be.ok
      FACTORY.by_class_predicate('o b')(node).should.not.be.ok
      FACTORY.by_class_predicate('o ba')(node).should.not.be.ok
      FACTORY.by_class_predicate('foo bar')(node).should.not.be.ok
      done()

    it 'returns true if the given regex matches the node\'s class',(done)->
      node = { attribs: { class: 'foo' } }
      FACTORY.by_class_predicate(/foo/)(node).should.be.ok
      FACTORY.by_class_predicate(/^foo$/)(node).should.be.ok
      FACTORY.by_class_predicate(/fo+/)(node).should.be.ok
      FACTORY.by_class_predicate(/o/)(node).should.be.ok
      FACTORY.by_class_predicate(/^f/)(node).should.be.ok
      FACTORY.by_class_predicate(/f$/)(node).should.not.be.ok
      FACTORY.by_class_predicate(/f[aeiou]{2}$/)(node).should.be.ok
      FACTORY.by_class_predicate(/f[aeiou]{3}$/)(node).should.not.be.ok
      FACTORY.by_class_predicate(/FOO/i)(node).should.be.ok
      done()

    it 'returns true if the given regex matches one of the node\'s class',(done)->
      node = { attribs: { class: 'x foo bar' } }
      FACTORY.by_class_predicate(/foo/)(node).should.be.ok
      FACTORY.by_class_predicate(/^foo$/)(node).should.be.ok
      FACTORY.by_class_predicate(/fo+/)(node).should.be.ok
      FACTORY.by_class_predicate(/o/)(node).should.be.ok
      FACTORY.by_class_predicate(/^f/)(node).should.be.ok
      FACTORY.by_class_predicate(/f$/)(node).should.not.be.ok
      FACTORY.by_class_predicate(/f[aeiou]{2}$/)(node).should.be.ok
      FACTORY.by_class_predicate(/f[aeiou]{3}$/)(node).should.not.be.ok
      FACTORY.by_class_predicate(/FOO/i)(node).should.be.ok
      FACTORY.by_class_predicate(/bar/)(node).should.be.ok
      done()

  describe "by_attr_value_predicate",->

    it 'returns true if the value of the given attribute name matches the given string',(done)->
      node = { attribs: { foo: 'bar qux' } }
      FACTORY.by_attr_value_predicate('foo','bar qux')(node).should.be.ok
      FACTORY.by_attr_value_predicate('foo','bar')(node).should.not.be.ok
      FACTORY.by_attr_value_predicate('bar','bar qux')(node).should.not.be.ok
      done()

    it 'returns true if the value of the given attribute name matches the given regex',(done)->
      node = { attribs: { foo: 'bar qux' } }
      FACTORY.by_attr_value_predicate('foo',/bar qux/)(node).should.be.ok
      FACTORY.by_attr_value_predicate('foo',/^BAR\squx$/i)(node).should.be.ok
      FACTORY.by_attr_value_predicate('foo',/bar/)(node).should.be.ok
      done()

    it 'can be used with the class attribute',(done)->
      node = { attribs: { class: 'foo' } }
      FACTORY.by_attr_value_predicate('class','foo')(node).should.be.ok
      FACTORY.by_attr_value_predicate('class','fo')(node).should.not.be.ok
      FACTORY.by_attr_value_predicate('class','bar')(node).should.not.be.ok
      FACTORY.by_attr_value_predicate('class','food')(node).should.not.be.ok
      node = { attribs: { class: 'foo bar' } }
      FACTORY.by_attr_value_predicate('class','foo bar')(node).should.be.ok
      FACTORY.by_attr_value_predicate('class','foo')(node).should.not.be.ok
      FACTORY.by_attr_value_predicate('class','bar')(node).should.not.be.ok
      FACTORY.by_attr_value_predicate('class',/foo/)(node).should.be.ok
      FACTORY.by_attr_value_predicate('class',/bar/)(node).should.be.ok
      FACTORY.by_attr_value_predicate('class',/^foo b/)(node).should.be.ok
      FACTORY.by_attr_value_predicate('class',/^foo$/)(node).should.not.be.ok
      done()

  describe "by_attr_exists_predicate",->

    it 'returns true if the given attribute exists',(done)->
      node = { attribs: { foo: 'bar' } }
      FACTORY.by_attr_exists_predicate('foo')(node).should.be.ok
      FACTORY.by_attr_exists_predicate(/^fO{2}$/i)(node).should.be.ok
      FACTORY.by_attr_exists_predicate('bar')(node).should.not.be.ok
      FACTORY.by_attr_exists_predicate(/bar/)(node).should.not.be.ok
      done()
