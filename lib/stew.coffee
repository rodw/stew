fs               = require 'fs'
path             = require 'path'
HOMEDIR          = path.join(__dirname,'..')
LIB_DIR          = if fs.existsSync(path.join(HOMEDIR,'lib-cov')) then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
#-------------------------------------------------------------------------------
DOMUtil          = require(path.join(LIB_DIR,'dom-util')).DOMUtil
PredicateFactory = require(path.join(LIB_DIR,'predicate-factory')).PredicateFactory
#-------------------------------------------------------------------------------

# TODO support `\/` as escaped `/` in regexp
class Stew

  constructor:(dom_util)->
      @factory = new PredicateFactory()
      @dom_util = dom_util ? new DOMUtil()

  select:(dom,selector,callback)->
    if typeof selector is 'string'
      selector = @_parse_selectors(selector)
    if typeof dom is 'string'
      if callback?
        @dom_util.parse_html dom, (err, dom)=>
          if err?
            callback(err)
          else
            callback(null,@_unguarded_select(dom,selector))
      else
        throw new Error('When select is invoked on a string object, the `callback(err,nodeset)` parameter is required.')
    else
      nodeset = @_unguarded_select(dom,selector)
      callback?(null,nodeset)
      return nodeset

  _unguarded_select:(dom,predicate)->
    result = []
    visit = (node,parent,path,siblings,sib_index)->
      if predicate(node,parent,path,siblings,sib_index)
        result.push node
      return { 'continue':true, 'visit_children':true }
    @dom_util.walk_dom dom, visit:visit
    return result

  select_first:(dom,selector,callback)->
    if typeof selector is 'string'
      selector = @_parse_selectors(selector)
    if typeof dom is 'string'
      if callback?
        @dom_util.parse_html dom, (err, dom)=>
          if err?
            callback(err)
          else
            callback(null,@_unguarded_select_first(dom,selector))
      else
        throw new Error('When select_first is invoked on a string object, the `callback(err,node)` parameter is required.')
    else
      node = @_unguarded_select_first(dom,selector)
      callback?(null,node)
      return node

  _unguarded_select_first:(dom,predicate)->
    result = null
    visit = (node,parent,path,siblings,sib_index)->
      if predicate(node,parent,path,siblings,sib_index)
        result = node
        return { 'continue':false, 'visit_children':false }
      else
        return { 'continue':true, 'visit_children':true }
    @dom_util.walk_dom dom, visit:visit
    return result

  # similiar to str.split(/\s/), but:
  #  - treats "quoted phrases" (and `/regular expressions/`) as a single token
  #  - also splits on the CSS "operators" of `>`, `+` and `,`
  # derived from : http://stackoverflow.com/questions/2817646/javascript-split-string-on-space-or-on-quotes-to-array
  SPLIT_ON_WS_REGEXP = /([^\"\/\s,\+>]|(\"[^\"]+\")|(\/[^\/]+\/))+|[,\+>]/g
  _split_on_ws_respecting_quotes:(selector)->
    result = []
    while true
      token = SPLIT_ON_WS_REGEXP.exec(selector)
      if token?[0]?
        result.push(token[0])
      else
        break
    # console.log "SELECTOR",selector,"RESULT",result
    return result

  # returns a predicate that evaluates a sequence of one or more css selectors
  _parse_selectors:(selectors)->
    result = []
    if typeof selectors is 'string'
      selectors = @_split_on_ws_respecting_quotes(selectors)
    # TODO should probably clean up the boolean-operator handling here; there is probably a more elegant way to do this
    child_operator = false
    adjacent_operator = false
    or_operator = false
    for selector in selectors
      if selector is '>'
        child_operator = true
      else if selector is '+'
        adjacent_operator = true
      else if selector is ','
        or_operator = true
      else
        predicate = @_parse_selector(selector)
        if child_operator
          result.push( @factory.direct_descendant_predicate( result.pop(), predicate ) )
          child_operator = false
        else if adjacent_operator
          result.push( @factory.adjacent_sibling_predicate( result.pop(), predicate  ) )
          adjacent_operator = false
        else if or_operator
          result.push( @factory.or_predicate( [ result.pop(), predicate ] ) )
          or_operator = false
        else
          result.push( predicate )
    if result.length > 0
      result = @factory.descendant_predicate(result)
    return result

  # NOTE: ((\/[^\/]*\/[gmi]*)|([\w-]+)) # matches regexp or word (incl. `-`)
  # TODO: Combine the `id` and `class` rules to make them order-indepedent? (I think CSS specifies the order, but still.)
  #
  #
  #                                                                                            11                  1           11  11                  1        112   2    2     22 22       2           22                  3                3 3             #
  #                     12                  3            4  56                  7          89  01                  2           34  56                  7        890   1    2     34 56       7           89                  0                1 2             #
  CSS_SELECTOR_REGEXP: /((\/[^\/]*\/[gmi]*)|(\*|[\w-]+))?(\#((\/[^\/]*\/[gmi]*)|([\w-]+)))?((\.((\/[^\/]*\/[gmi]*)|([\w-]+)))*)((\[((\/[^\/]*\/[gmi]*)|([\w-]+))(((=)|(~=)|(\|=))(("(([^\\"]|(\\"))*)")|((\/[^\/]*\/[gmi]*)|([\w- ]+))))?\])*)(:([\w-]+))?/   #
  #                     \-------------------------------/\--------------------------------/\----------------------------------/||  \---------------------------/|\--------------/\----------------------------------------------------/|   | |\----------/
  #                     | name                           | id                              | one or more classes               ||  | name                       || operator      | value                                               |   | || :pseudo-class
  #                                                                                                                            ||                               \----------------------------------------------------------------------/   | |
  #                                                                                                                            ||                               | operator and value                                                       | |
  #                                                                                                                            |\----------------------------------------------------------------------------------------------------------/ |
  #                                                                                                                            || `[...]` attribute part                                                                                     |
  #                                                                                                                            \-------------------------------------------------------------------------------------------------------------/
  #                                                                                                                            | `[...]*` attribute part
  NAME = 1
  ID = 4
  CLASSES = 8
  ATTRIBUTES = 13
  # ATTR_NAME = 15
  # OPERATOR = 19
  # DEQUOTED_ATTR_VALUE = 25
  # NEVERQUOTED_ATTR_VALUE = 28
  PSEUDO_CLASS = 32
  # "tag#id.class-one.class-two[name~=\"value with spaces\"]".match(CSS_SELECTOR_REGEXP)

  #                                                                          11 11       1          11                  1
  #                         1  23                  4        567   8    9     01 23       4          56                  7
  ATTRIBUTE_CLAUSE_REGEXP: /(\[((\/[^\/]*\/[gmi]*)|([\w-]+))(((=)|(~=)|(\|=))(("(([^\\"]|(\\"))*)")|((\/[^\/]*\/[gmi]*)|([\w- ]+))))?\])/g #
  #                            \---------------------------/|\--------------/\----------------------------------------------------/|
  #                            | name                       || operator      | value                                               |
  SUB_ATTR_NAME = 2
  SUB_OPERATOR = 6
  SUB_DEQUOTED_ATTR_VALUE = 12
  SUB_NEVERQUOTED_ATTR_VALUE = 15

  # returns a (possibly compound) predicate that matches the provided `selector`
  _parse_selector:(selector)->
    match = @CSS_SELECTOR_REGEXP.exec(selector)
    clauses = []

    # NAME PART
    if match[NAME]?
      if match[NAME] is '*'
        clauses.push(@factory.any_tag_predicate())
      else
        clauses.push(@factory.by_tag_predicate(@_to_string_or_regex(match[NAME])))

    # ID PART
    if match[ID]?
      clauses.push(@factory.by_id_predicate(@_to_string_or_regex(match[ID].substring(1))))

    # CLASS PART
    if match[CLASSES]?.length > 0    # match[CLASSES] contains something like `.foo.bar`
      cs = match[CLASSES].split('.') # split the string into individual class names
      cs.shift()                     # and skip the first (empty) token that is included
      for c in cs
        clauses.push(@factory.by_class_predicate(@_to_string_or_regex(c)))

    # ATTRIBUTE PART
    if match[ATTRIBUTES]?.length > 0 # match[ATTRIBUTES] contains one or more `[name=value]` (or `[name]`) strings
      attr_match = @ATTRIBUTE_CLAUSE_REGEXP.exec(match[ATTRIBUTES])
      while attr_match?
        if attr_match[SUB_ATTR_NAME]? and (not attr_match[SUB_OPERATOR]?)
          clauses.push(@factory.by_attr_exists_predicate(@_to_string_or_regex(attr_match[SUB_ATTR_NAME])))
        if attr_match[SUB_ATTR_NAME]? and attr_match[SUB_OPERATOR]? and (attr_match[SUB_DEQUOTED_ATTR_VALUE]? or attr_match[SUB_NEVERQUOTED_ATTR_VALUE]?)
          delim = null
          if attr_match[SUB_OPERATOR] is '~='
            delim = /\s+/
          if attr_match[SUB_OPERATOR] is '|='
            clauses.push(
              @factory.by_attr_value_pipe_equals(
                @_to_string_or_regex(attr_match[SUB_ATTR_NAME]),
                @_to_string_or_regex(attr_match[SUB_DEQUOTED_ATTR_VALUE] ? attr_match[SUB_NEVERQUOTED_ATTR_VALUE])
              )
            )
          else
            clauses.push(
              @factory.by_attr_value_predicate(
                @_to_string_or_regex(attr_match[SUB_ATTR_NAME]),
                @_to_string_or_regex(attr_match[SUB_DEQUOTED_ATTR_VALUE] ? attr_match[SUB_NEVERQUOTED_ATTR_VALUE]),
                delim
              )
            )
        attr_match = @ATTRIBUTE_CLAUSE_REGEXP.exec(match[ATTRIBUTES])

    # PSEUDO CLASS PART
    if match[PSEUDO_CLASS]?
      if match[PSEUDO_CLASS] is 'first-child'
        clauses.push(@factory.first_child_predicate())

    # COMBINE THEM
    if clauses.length > 0
      clauses = @factory.and_predicate(clauses)

    return clauses

  # If `str` is a string that starts and ends with `/`
  # (or an optional `g`, `m` or `i` suffix, it is
  # converted to the corresponding RegExp. Else the
  # original `str` value is returned.
  _to_string_or_regex:(str)->
    match = str.match /^\/(.*)\/([gmi]*)$/
    if match?[1]?
      return new RegExp(match[1],match[2])
    else
      return str

exports = exports ? this
exports.Stew = Stew
exports.DOMUtil = DOMUtil
