should           = require 'should'
fs               = require 'fs'
path             = require 'path'
HOMEDIR          = path.join(__dirname,'..')
LIB_DIR          = if fs.existsSync(path.join(HOMEDIR,'lib-cov')) then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
#-------------------------------------------------------------------------------
DOMUtil          = require(path.join(LIB_DIR,'dom-util')).DOMUtil
#-------------------------------------------------------------------------------

HTMLPARSER_OPTIONS =
  ignoreWhitespace:  false
  caseSensitiveTags: false
  caseSensitiveAttr: false

describe "DOMUtil",=>

  beforeEach (done)=>
    @dom_util = new DOMUtil()
    done()

  afterEach (done)=>
    @dom_util = null
    done()

  describe "parse_html",=>
    it "produces a DOM tree for the given HTML string",(done)=>
      @dom_util.parse_html '<html><div>This is an example HTML document</div></html>', (err, dom)=>
        should.not.exist err
        should.exist dom
        dom.type.should.equal 'tag'
        dom.name.should.equal 'html'
        done()
    it "produces an array of DOM trees when the given HTML string has more than one root",(done)=>
      @dom_util.parse_html '<div>First div.</div><span>Second span.</span>', (err, dom)=>
        should.not.exist err
        should.exist dom
        dom.length.should.equal 2
        dom[0].type.should.equal 'tag'
        dom[0].name.should.equal 'div'
        dom[1].type.should.equal 'tag'
        dom[1].name.should.equal 'span'
        done()
    it "allows a map of options to be passed",(done)=>
      @dom_util.parse_html '<html><DIV>This is an example HTML document</div></HTML>', HTMLPARSER_OPTIONS, (err, dom)=>
        should.not.exist err
        should.exist dom
        dom.type.should.equal 'tag'
        dom.name.should.equal 'html'
        done()

  it "as_node converts a nodeset to a single node",(done)=>
    should.not.exist @dom_util.as_node(null)
    should.not.exist @dom_util.as_node([])
    should.not.exist @dom_util.as_node([null])
    nodes = [
      { type:'tag', name:'html' }
      { type:'tag', name:'body' }
      { type:'tag', name:'div' }
      { type:'tag', name:'span' }
    ]
    @dom_util.as_node(nodes).name.should.equal 'html'
    @dom_util.as_node([{ type:'tag', name:'html' }]).name.should.equal 'html'
    @dom_util.as_node({ type:'tag', name:'html' }).name.should.equal 'html'
    done()

  it "as_nodeset converts a node to a nodeset",(done)=>
    @dom_util.as_nodeset(null).length.should.equal 0
    @dom_util.as_nodeset([]).length.should.equal 0
    @dom_util.as_nodeset([null]).length.should.equal 1
    nodes = [
      { type:'tag', name:'html' }
      { type:'tag', name:'body' }
      { type:'tag', name:'div' }
      { type:'tag', name:'span' }
    ]
    @dom_util.as_nodeset(nodes).length.should.equal 4
    @dom_util.as_nodeset(nodes[0]).length.should.equal 1
    done()

  describe "to_text",=>
    it "returns the value of all text descendants",(done)=>
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        text = @dom_util.to_text dom
        text.should.equal 'alphabeta'
        done()

    it "handles whitespace between nodes",(done)=>
      html = '<html><div id="A"> <span>alpha</span></div> <div id="B"><b><i>beta</i> </b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        text = @dom_util.to_text dom
        text.should.equal ' alpha beta '
        done()

    it "supports a `filter` function for excluding nodes",(done)=>
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        text = @dom_util.to_text dom, (node)=>node.attribs?.id isnt 'A'
        text.should.equal 'beta'
        done()

    it "supports a `decode` function for converting HTML to text nodes",(done)=>
      dom_util = new DOMUtil(decode:(str)->str.toUpperCase())
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        text = dom_util.to_text dom
        text.should.equal 'ALPHABETA'
        done()

    it "is also known as `inner_text`",(done)=>
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        text = @dom_util.inner_text dom
        text.should.equal 'alphabeta'
        done()

  describe "inner_html",=>
    it "returns an HTML representation of the children of the given node",(done)=>
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        text = @dom_util.inner_html dom
        text.should.equal '<div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div>'
        done()

    it "handles whitespace between nodes",(done)=>
      html = '<html><div id="A"> <span>alpha</span></div> <div id="B"><b><i>beta</i> </b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        text = @dom_util.inner_html dom
        text.should.equal '<div id="A"> <span>alpha</span></div> <div id="B"><b><i>beta</i> </b></div>'
        done()

  describe "to_html",=>
    it "returns an HTML representation of the given node",(done)=>
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        text = @dom_util.to_html dom
        text.should.equal '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
        done()

    it "handles whitespace between nodes",(done)=>
      html = '<html><div id="A"> <span>alpha</span></div> <div id="B"><b><i>beta</i> </b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        text = @dom_util.to_html dom
        text.should.equal '<html><div id="A"> <span>alpha</span></div> <div id="B"><b><i>beta</i> </b></div></html>'
        done()

  describe "walk_dom",=>

    it "performs a depth-first walk of the dom tree",(done)=>
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        expected = [ 'html', 'div', 'span', 'div', 'b', 'i' ]
        @dom_util.walk_dom dom, (node)=>
          if node.type is 'tag'
            expected_name = expected.shift()
            node.name.should.equal expected_name
          return true
        expected.length.should.equal 0
        done()

    it "passes parent node to visit function",(done)=>
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        expected = [ null, 'html', 'div', 'html', 'div', 'b' ]
        @dom_util.walk_dom dom, (node,node_metadata)=>
          if node.type is 'tag'
            expected_name = expected.shift()
            if expected_name?
              node_metadata.parent.should.exist
              node_metadata.parent.name.should.equal expected_name
            else
              should.not.exist node_metadata.parent
          return true
        expected.length.should.equal 0
        done()

    it "passes path to node to visit function",(done)=>
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        expected = [ [], ['html'], ['html','div'], ['html','div','span'], ['html'], ['html','div'], ['html','div','b'], ['html','div','b','i'] ]
        @dom_util.walk_dom dom, (node,node_metadata)=>
          if node.type is 'tag' or node.type is 'text'
            expected_path = expected.shift()
            expected_path.length.should.equal node_metadata.path.length
            for elt,i in expected_path
              node_metadata.path[i].name.should.equal elt
          return true
        expected.length.should.equal 0
        done()

    it "passes siblings to visit function",(done)=>
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        expected = [ ['html'], ['div','div'], ['span'], ['div','div'],['b'],['i'] ]
        @dom_util.walk_dom dom, (node,node_metadata)=>
          if node.type is 'tag'
            expected_sibs = expected.shift()
            expected_sibs.length.should.equal node_metadata.siblings.length
            for elt,i in expected_sibs
              node_metadata.siblings[i].name.should.equal elt
          return true
        expected.length.should.equal 0
        done()

    it "passes sibling index to visit function",(done)=>
      html = '<html><div id="A"><span>alpha</span></div><div id="B"><b><i>beta</i></b></div></html>'
      @dom_util.parse_html html, HTMLPARSER_OPTIONS, (err, dom)=>
        expected = [ 0, 0, 0, 1, 0, 0 ]
        @dom_util.walk_dom dom, (node,node_metadata)=>
          if node.type is 'tag'
            expected_index = expected.shift()
            node_metadata.sib_index.should.equal expected_index
          return true
        expected.length.should.equal 0
        done()
