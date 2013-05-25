fs               = require 'fs'
path             = require 'path'
HOMEDIR          = path.join(__dirname,'..')
LIB_DIR          = if fs.existsSync(path.join(HOMEDIR,'lib-cov')) then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
#-------------------------------------------------------------------------------
DOMUtil          = require(path.join(LIB_DIR,'dom-util')).DOMUtil
PredicateFactory = require(path.join(LIB_DIR,'predicate-factory')).PredicateFactory
#-------------------------------------------------------------------------------
#

######################################################################
######################################################################
######################################################################
# TODO: NEXT STEP IS TO CREATE _parse_selectors_2 METHOD AND UPDATE
#       select METHOD TO USE IT.
######################################################################
######################################################################
######################################################################

#
#
class Stew


  constructor:()->
      @factory = new PredicateFactory()

  select:(dom,selector)->
    if typeof selector is 'string'
      selector = @parse_selectors(selector)
    return @_unguarded_select(dom,selector)

  _unguarded_select:(dom,predicates)->
    result = []
    visit = (node,parent,path,siblings,sib_index)->
      if predicates[predicates.length-1](node)
        if predicates.length is 1
          result.push node
        else
          cloned_path = [].concat(path)
          cloned_predicates = [].concat(predicates)
          leaf_predicate = cloned_predicates.pop()
          leaf_node = node
          while cloned_path.length > 0
            node = cloned_path.pop()
            if cloned_predicates[cloned_predicates.length-1](node)
              cloned_predicates.pop()
              if cloned_predicates.length is 0
                result.push leaf_node
                break
      return true
    DOMUtil.walk_dom dom, visit:visit
    return result

  # like selector.split(/\s/), but allows quoted strings
  # via: http://stackoverflow.com/questions/2817646/javascript-split-string-on-space-or-on-quotes-to-array
  SPLIT_ON_WS_REGEXP = /\S+|\"[^\"]+\"/g
  _split_on_unquoted_ws:(selector)->
    result = []
    # in regular JS, this is
    #   while(token = SPLIT_ON_WS_REGEXP.exec(selector) { ... }
    # surely there is a better way to do this in coffeescript
    while true
      token = SPLIT_ON_WS_REGEXP.exec(selector)
      if token?[0]?
        result.push(token[0])
      else
        break
    return result

  # NOTE: ((\/[^\/]*\/[gmi]*)|([\w-]+)) # regexp or word

  #
  #                                                                                         11                  1           1  11                  1        111   2    2     22 2          2                #
  #                     12                  3         4  56                  7          89  01                  2           3  45                  6        789   0    1     23 4          5                #
  CSS_SELECTOR_REGEXP: /((\/[^\/]*\/[gmi]*)|([\w-]+))?(\#((\/[^\/]*\/[gmi]*)|([\w-]+)))?((\.((\/[^\/]*\/[gmi]*)|([\w-]+)))*)(\[((\/[^\/]*\/[gmi]*)|([\w-]+))(((=)|(~=)|(\|=))(("([^\]]*)")|([^\]]+)))?\])?/ #
  #                     \----------------------------/\--------------------------------/\----------------------------------/|  \---------------------------/|\--------------/\---------------------/|    |
  #                     | name                        | id                              | one or more classes               |  | name                       || operator      | value                |    |
  #                                                                                                                         |                               \---------------------------------------/    |
  #                                                                                                                         |                               | operator and value                         |
  #                                                                                                                         \----------------------------------------------------------------------------/
  #                                                                                                                         | `[...]` attribute part
  # "tag#id.class-one.class-two[name~=\"value with spaces\"]".match(CSS_SELECTOR_REGEXP)
  # 1  => element name
  # 4  => id
  # 8  => classes
  # 14  => attribute name
  # 18  => operator
  # 22 => attribute value (optional quotes)
  # 24 => unquoted attribute value2
  # 25 => never-quoted attribute value

  # returns a (possibly compound) predicate that matches the provided `selector`
  _parse_selector_2:(selector)->
    match = @CSS_SELECTOR_REGEXP.exec(selector)
    j = { }

    NAME = 1
    ID = 4
    CLASSES = 8
    ATTR_NAME = 14
    OPERATOR = 18
    DEQUOTED_ATTR_VALUE = 24
    NEVERQUOTED_ATTR_VALUE = 25

    j.name      = match[NAME] if match[NAME]?
    j.id        = match[ID] if match[ID]?
    if match[CLASSES]?.length > 0
     j.classes = match[CLASSES]?.split(/\s+/)
    j.attr_name = match[ATTR_NAME] if match[ATTR_NAME]?
    j.operator  = match[OPERATOR] if match[OPERATOR]?
    j.attr_value = match[DEQUOTED_ATTR_VALUE] if match[DEQUOTED_ATTR_VALUE]?
    j.attr_value = match[15] if match[15]?

    clauses = []
    if match[NAME]?
      clauses.push(@factory.by_tag_predicate(@_to_string_or_regex(match[NAME])))
      # clauses.push(["by_tag",@_to_string_or_regex(match[NAME])])
    if match[ID]?
      clauses.push(@factory.by_id_predicate(@_to_string_or_regex(match[ID].substring(1))))
      # clauses.push(["by_id",@_to_string_or_regex(match[ID].substring(1))])
    if match[CLASSES]?.length > 0
                               # match[CLASSES] contains something like `.foo.bar`
      cs = match[CLASSES].split('.') # split the string into individual class names
      cs.shift()               # and skip the first (empty) token that is included
      for c in cs
        clauses.push(@factory.by_class_predicate(@_to_string_or_regex(c)))
        # clauses.push(["by_class",@_to_string_or_regex(c)])
    if match[ATTR_NAME]? and (not match[OPERATOR]?)
      clauses.push(@factory.by_attr_exists_predicate(@_to_string_or_regex(match[ATTR_NAME])))
      # clauses.push(["by_attr_exists",@_to_string_or_regex(match[ATTR_NAME])])
    if match[ATTR_NAME]? and match[OPERATOR]? and (match[DEQUOTED_ATTR_VALUE]? or match[NEVERQUOTED_ATTR_VALUE]?)
      delim = null
      if match[OPERATOR] is '~='
        delim = /\s+/
      clauses.push(
        @factory.by_attr_value_predicate(
          @_to_string_or_regex(match[ATTR_NAME]),
          @_to_string_or_regex(match[DEQUOTED_ATTR_VALUE] ? match[NEVERQUOTED_ATTR_VALUE]),
          delim
        )
      )
      # clauses.push(["by_attr_value",@_to_string_or_regex(match[ATTR_NAME]),@_to_string_or_regex(match[DEQUOTED_ATTR_VALUE] ? match[NEVERQUOTED_ATTR_VALUE]),delim])

    if clauses.length > 0
      return @factory.and_predicate(clauses)
    else
      return clauses[0]



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

  parse_selectors:(selectors)->
    result = []
    if typeof selectors is 'string'
      selectors = selectors.split(/\s/)
    for selector in selectors
      result.push @_parse_selector(selector)
    return result

  # TODO make parser support whitespace within tokens
  # TODO make parser support quoted strings (attribute values)
  TAG_N_ATTR = /^([A-Z0-9_]+)(\[.+\])/i

  _parse_selector:(selector)->
    if /^\.(.+)$/.test(selector)
      # class
      return @factory.by_class_predicate( @_to_string_or_regex(selector.substring(1)) )
    else  if /^\#/.test(selector)
      # id
      return @factory.by_id_predicate( @_to_string_or_regex(selector.substring(1)) )
    else if /^\[.*\]$/.test(selector)
      # attribute
      selector = selector.substring(1,selector.length-1)
      if selector.indexOf('=') is -1
        return @factory.by_attr_exists_predicate( @_to_string_or_regex(selector) )
      else
        [name,value] = selector.split('=') # TODO handle ~= case
        return @factory.by_attr_value_predicate( @_to_string_or_regex(name), @_to_string_or_regex(value) )
    else if TAG_N_ATTR.test(selector)
      matches = selector.match TAG_N_ATTR
      return @factory.and_predicate([@_parse_selector(matches[1]),@_parse_selector(matches[2])])
    else
      return @factory.by_tag_predicate( @_to_string_or_regex(selector) )


exports = exports ? this
exports.Stew = Stew


  # OLD, DELETE ME
  # #                                                                        1    1     11 1          1
  # #                      1        2          34           5  6       789   0    1     23 4          5
  # CSS_SELECTOR_REGEXP: /([\w-]+)?(\#[\w-]+)?((\.[\w-]+)*)(\[([\w-]+)(((=)|(~=)|(\|=))(("([^\]]*)")|([^\]]+)))?\])?/
  # #                      -------- ---------- ----------      -------- --------------- -----------------------
  # #                      | name | |   id   | |  class |      | name | | operator    | |      value          |
  # #                                                          |       ---------------- ------------------------
  # #                                                          |       | operator-value                        |
  # #                                                       --------------------------------------------------------
  # #                                                       | attribute                                            |
  # #                                                       --------------------------------------------------------
  # # "tag#id.class-one.class-two[name~=\"value with spaces\"]".match(CSS_SELECTOR_REGEXP)
  # # 1  => element name
  # # 2  => id
  # # 3  => classes
  # # 6  => attribute name
  # # 8  => operator
  # # 12 => attribute value (optional quotes)
  # # 14 => unquoted attribute value2
  # # 15 => never-quoted attribute value
