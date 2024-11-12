// Element function for sequences
#let sequence = [].func()

// Convert content to an array of its children
#let to-children(content) = {
  if type(content) in (str, symbol) {
    str(content).clusters().map(char => [#char])
  } else if content.func() == sequence {
    content.children
  } else if content.func() == text {
    to-children(content.text)
  } else if content.func() == math.equation {
    to-children(content.body)
  } else {
    (content,)
  }
}

// Convert shorthands in the given sequence to their respective replacements.
#let convert-sequence(seq, shorthands) = {
  let is-sequence = type(seq) == content and seq.func() == sequence
  if not is-sequence or seq.children.len() == 0 {
    return seq
  }
  
  let children = seq.children.map(c => convert-sequence(c, shorthands))
  for shorthand in shorthands {
    let components = to-children(shorthand.first())
    let start = 0
    
    while start < children.len() {
      let pos = children.slice(start).position(c => c == components.first())
      if pos == none {
        break
      }

      pos = start + pos // Position of first matching character
      start = pos + 1 // Start index for finding next match 

      // Check whether all components of the shorthand match
      let matches = true
      let attachments = none
      for i in range(components.len()) {
        let child = children.at(pos+i, default: none)
        if child == components.at(i) {
          continue
        }

        // Try last one without attachments, as they can be added back later.
        let is-last = i == components.len() - 1
        if is-last and child != none and child.func() == math.attach {
          let fields = child.fields()
          let base = fields.remove("base")
          child = child.base
          attachments = fields
        }

        if child != components.at(i) {
          matches = false
          break
        }
      }
      
      if matches {
        // Remove shorthand and insert replacement
        for i in range(components.len()) { children.remove(pos) }

        // Add back attachments.
        let replacement = shorthand.last()
        if attachments != none {
          replacement = math.attach(replacement, ..attachments)
        }

        children.insert(pos, replacement)
      }
    }
  }
  
  return children.join()
}

// A template that converts the given shorthands to their respective replacement.
//
// Parameters:
// - shorthands: One or more tuples of the form `(shorthand, replacement)`.
// - body: The body to apply the template on.
//
// Returns: The body with evaluated shorthands. 
#let shorthands(..shorthands, body) = {
  let shorthands = shorthands.pos()

  show math.equation: eq => {
    show sequence: seq => {
      let new = convert-sequence(seq, shorthands)
      if new != seq { new } else { seq }
    }

    // Apply single-element shorthands as show rules, so that they are also
    // applied to non-sequence elements.
    shorthands.fold(eq, (acc, (shorthand, replacement)) => {
      let string = if type(shorthand) in (str, symbol) {
        str(shorthand)
      } else if type(shorthand) != content {
        return acc
      } else if shorthand.func() == text {
        shorthand.text
      } else if shorthand.func() == math.equation and shorthand.body.func() == text {
        shorthand.body.text
      } else if shorthand.func() == sequence {
        return acc
      }

      if string == none {
        // Shorthand cannot be converted to a string, so try to match it directly.
        if shorthand.func() == math.equation and shorthand.body.func() != sequence {
          let func = shorthand.body.func()
          let filter = shorthand.body.fields()

          show func.where(..filter): it => {
            // If the element contains more content that was needed for the
            // match (e.g. attachments), it should be added back to the
            // replacement.
            let fields = it.fields()
            let remaining = fields.pairs()
              .filter(((key, val)) => key not in filter)
              .fold((:), (acc, (key, val)) => acc + ((key): val))

            if remaining.values().any(v => type(v) == content) {
              func(replacement, ..remaining)
            } else {
              replacement
            }
          }

          acc
        } else {
          acc
        }
      } else {
        // Escape regex special characters.
        string = string.replace(regex("[-\[\]{}()*+?.,\\\\^$|#\\s]"), it => "\\" + it.text)

        show regex("^" + string + "$"): replacement
        acc
      }
    })
  }

  body
}
