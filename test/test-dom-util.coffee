should           = require 'should'
fs               = require 'fs'
path             = require 'path'
HOMEDIR          = path.join(__dirname,'..')
LIB_DIR          = if fs.existsSync(path.join(HOMEDIR,'lib-cov')) then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
#-------------------------------------------------------------------------------
htmlparser       = require 'htmlparser'
DOMUtil          = require(path.join(LIB_DIR,'dom-util')).DOMUtil
#-------------------------------------------------------------------------------

HTMLPARSER_OPTIONS =
  ignoreWhitespace:  false
  caseSensitiveTags: false
  caseSensitiveAttr: false

describe "DOMUtil",->

  it "as_node converts a nodeset to a single node",(done)->
    should.not.exist DOMUtil.as_node(null)
    should.not.exist DOMUtil.as_node([])
    should.not.exist DOMUtil.as_node([null])
    nodes = [
      { type:'tag', name:'html' }
      { type:'tag', name:'body' }
      { type:'tag', name:'div' }
      { type:'tag', name:'span' }
    ]
    DOMUtil.as_node(nodes).name.should.equal 'html'
    DOMUtil.as_node([{ type:'tag', name:'html' }]).name.should.equal 'html'
    DOMUtil.as_node({ type:'tag', name:'html' }).name.should.equal 'html'
    done()

  it "as_nodeset converts a node to a nodeset",(done)->
    DOMUtil.as_nodeset(null).length.should.equal 0
    DOMUtil.as_nodeset([]).length.should.equal 0
    DOMUtil.as_nodeset([null]).length.should.equal 1
    nodes = [
      { type:'tag', name:'html' }
      { type:'tag', name:'body' }
      { type:'tag', name:'div' }
      { type:'tag', name:'span' }
    ]
    DOMUtil.as_nodeset(nodes).length.should.equal 4
    DOMUtil.as_nodeset(nodes[0]).length.should.equal 1
    done()


  describe "walk_dom",->

    it "performs a depth-first walk of the dom tree",(done)=>
      handler = new htmlparser.DefaultHandler (err, dom)=>
        expected = [ 'html', 'div', 'span', 'div', 'b', 'i' ]
        DOMUtil.walk_dom dom, (node)=>
          if node.type is 'tag'
            expected_name = expected.shift()
            node.name.should.equal expected_name
          return true
        expected.length.should.equal 0
        done()
      parser = new htmlparser.Parser(handler,HTMLPARSER_OPTIONS)
      parser.parseComplete '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'

    it "passes parent node to visit function",(done)=>
      handler = new htmlparser.DefaultHandler (err, dom)=>
        expected = [ null, 'html', 'div', 'html', 'div', 'b' ]
        DOMUtil.walk_dom dom, (node,parent)=>
          if node.type is 'tag'
            expected_name = expected.shift()
            if expected_name?
              parent.should.exist
              parent.name.should.equal expected_name
            else
              should.not.exist parent
          return true
        expected.length.should.equal 0
        done()
      parser = new htmlparser.Parser(handler,HTMLPARSER_OPTIONS)
      parser.parseComplete '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'

    it "passes path to node to visit function",(done)=>
      handler = new htmlparser.DefaultHandler (err, dom)=>
        expected = [ [], ['html'], ['html','div'], ['html','div','span'], ['html'], ['html','div'], ['html','div','b'], ['html','div','b','i'] ]
        DOMUtil.walk_dom dom, (node,parent,path)=>
          if node.type is 'tag' or node.type is 'text'
            expected_path = expected.shift()
            expected_path.length.should.equal path.length
            for elt,i in expected_path
              path[i].name.should.equal elt
          return true
        expected.length.should.equal 0
        done()
      parser = new htmlparser.Parser(handler,HTMLPARSER_OPTIONS)
      parser.parseComplete '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'

    it "passes siblings to visit function",(done)=>
      handler = new htmlparser.DefaultHandler (err, dom)=>
        expected = [ ['html'], ['div','div'], ['span'], ['div','div'],['b'],['i'] ]
        DOMUtil.walk_dom dom, (node,parent,path,siblings)=>
          if node.type is 'tag'
            expected_sibs = expected.shift()
            expected_sibs.length.should.equal siblings.length
            for elt,i in expected_sibs
              siblings[i].name.should.equal elt
          return true
        expected.length.should.equal 0
        done()
      parser = new htmlparser.Parser(handler,HTMLPARSER_OPTIONS)
      parser.parseComplete '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'

    it "passes sibling index to visit function",(done)=>
      handler = new htmlparser.DefaultHandler (err, dom)=>
        expected = [ 0, 0, 0, 1, 0, 0 ]
        DOMUtil.walk_dom dom, (node,parent,path,siblings,sib_index)=>
          if node.type is 'tag'
            expected_index = expected.shift()
            sib_index.should.equal expected_index
          return true
        expected.length.should.equal 0
        done()
      parser = new htmlparser.Parser(handler,HTMLPARSER_OPTIONS)
      parser.parseComplete '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
