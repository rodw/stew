fs               = require 'fs'
path             = require 'path'
HOMEDIR          = path.join(__dirname,'..')
LIB_DIR          = if fs.existsSync(path.join(HOMEDIR,'lib-cov')) then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
#-------------------------------------------------------------------------------
DOMUtil          = require(path.join(LIB_DIR,'dom-util')).DOMUtil
PredicateFactory = require(path.join(LIB_DIR,'predicate-factory')).PredicateFactory
#-------------------------------------------------------------------------------


################################################################################
################################################################################
## NEXT STEP: ADD FIRST-CHILD PREDICATE                                       ##
################################################################################
################################################################################

#
# TODO clean up tests
# TODO support `|=` operator
# TODO: fix handing of escaped quotes in the big ugly regexp
class Stew

  constructor:()->
      @factory = new PredicateFactory()

  select:(dom,selector)->
    if typeof selector is 'string'
      selector = @_parse_selectors(selector)
    return @_unguarded_select(dom,selector)

  _unguarded_select:(dom,predicate)->
    result = []
    visit = (node,parent,path,siblings,sib_index)->
      if predicate(node,parent,path,siblings,sib_index)
        result.push node
      return true
    DOMUtil.walk_dom dom, visit:visit
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
        predicate = @_parse_selector_2(selector)
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
  # TODO: support escaped chars, notably `\/` in regexps
  #
  #
  #                                                                                            11                  1           1  11                  1        111   2    2     22 22      2           22                  2                3 3             #
  #                     12                  3            4  56                  7          89  01                  2           3  45                  6        789   0    1     23 45      6           78                  9                0 1             #
  CSS_SELECTOR_REGEXP: /((\/[^\/]*\/[gmi]*)|(\*|[\w-]+))?(\#((\/[^\/]*\/[gmi]*)|([\w-]+)))?((\.((\/[^\/]*\/[gmi]*)|([\w-]+)))*)(\[((\/[^\/]*\/[gmi]*)|([\w-]+))(((=)|(~=)|(\|=))(("(([^\\"]|(\\"))*)")|((\/[^\/]*\/[gmi]*)|([\w- ]+))))?\])?(:([\w-]+))?/   #
  #                     \-------------------------------/\--------------------------------/\----------------------------------/|  \---------------------------/|\--------------/\----------------------------------------------------/|    |\----------/
  #                     | name                           | id                              | one or more classes               |  | name                       || operator      | value                                               |    | | :pseudo-class
  #                                                                                                                            |                               \----------------------------------------------------------------------/    |
  #                                                                                                                            |                               | operator and value                                                        |
  #                                                                                                                            \-----------------------------------------------------------------------------------------------------------/
  #                                                                                                                            | `[...]` attribute part
  NAME = 1
  ID = 4
  CLASSES = 8
  ATTR_NAME = 14
  OPERATOR = 18
  DEQUOTED_ATTR_VALUE = 24
  NEVERQUOTED_ATTR_VALUE = 27
  PSEUDO_CLASS = 31
  # "tag#id.class-one.class-two[name~=\"value with spaces\"]".match(CSS_SELECTOR_REGEXP)

  # returns a (possibly compound) predicate that matches the provided `selector`
  _parse_selector_2:(selector)->
    match = @CSS_SELECTOR_REGEXP.exec(selector)
    clauses = []
    if match[NAME]?
      if match[NAME] is '*'
        clauses.push(@factory.any_tag_predicate())
      else
        clauses.push(@factory.by_tag_predicate(@_to_string_or_regex(match[NAME])))
    if match[ID]?
      clauses.push(@factory.by_id_predicate(@_to_string_or_regex(match[ID].substring(1))))
    if match[CLASSES]?.length > 0
                                     # match[CLASSES] contains something like `.foo.bar`
      cs = match[CLASSES].split('.') # split the string into individual class names
      cs.shift()                     # and skip the first (empty) token that is included
      for c in cs
        clauses.push(@factory.by_class_predicate(@_to_string_or_regex(c)))
    if match[ATTR_NAME]? and (not match[OPERATOR]?)
      clauses.push(@factory.by_attr_exists_predicate(@_to_string_or_regex(match[ATTR_NAME])))
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
    if match[PSEUDO_CLASS]?
      if match[PSEUDO_CLASS] is 'first-child'
        clauses.push(@factory.first_child_predicate())
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
