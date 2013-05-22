fs               = require 'fs'
path             = require 'path'
HOMEDIR          = path.join(__dirname,'..')
LIB_DIR          = if fs.existsSync(path.join(HOMEDIR,'lib-cov')) then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
#-------------------------------------------------------------------------------
DOMUtil          = require(path.join(LIB_DIR,'dom-util')).DOMUtil
PredicateFactory = require(path.join(LIB_DIR,'predicate-factory')).PredicateFactory
#-------------------------------------------------------------------------------
#                                                                        1    1     11 1          1
#                      1        2          34           5  6       789   0    1     23 4          5
CSS_SELECTOR_REGEXP = /([\w-]+)?(\#[\w-]+)?((\.[\w-]+)*)(\[([\w-]+)(((=)|(~=)|(\|=))(("([^\]]*)")|([^\]]+)))?\])?/
#                      -------- ---------- ----------      -------- --------------- -----------------------
#                      | name | |   id   | |  class |      | name | | operator    | |      value          |
#                                                          |       ---------------- ------------------------
#                                                          |       | operator-value                        |
#                                                       --------------------------------------------------------
#                                                       | attribute                                            |
#                                                       --------------------------------------------------------
# "tag#id.class-one.class-two[name~=\"value with spaces\"]".match(CSS_SELECTOR_REGEXP)
# 1  => element name
# 2  => id
# 3  => classes
# 6  => attribute name
# 8  => operator
# 12 => attribute value (optional quotes)
# 14 => unquoted attribute value
# 15 => never-quoted attribute value
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
