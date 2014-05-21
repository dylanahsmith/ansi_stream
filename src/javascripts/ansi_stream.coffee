class AnsiStream
  constructor: ->
    @style = new AnsiStyle()
    @span = new AnsiSpan()

  process: (text) ->
    parts = text.split(/\033\[/)
    parts = parts.filter (part) -> part

    spans = for part in parts
      [partText, styles] = @_extractTextAndStyles(part)
      if styles
        @style.apply(styles)
        @span.create(partText, @style)
      else
        partText

    spans

  _extractTextAndStyles: (originalText) ->
    matches = originalText.match(/^([\d;]*)m([^]*)$/m)

    return [originalText, null] unless matches

    [matches, numbers, text] = matches
    [text, numbers.split(";")]

class AnsiStyle
  COLORS =
    0: 'black'
    1: 'red'
    2: 'green'
    3: 'yellow'
    4: 'blue'
    5: 'magenta'
    6: 'cyan'
    7: 'white'
    8: null
    9: 'default'

  constructor: ->
    @reset()

  apply: (newStyles) ->
    return unless newStyles
    for style in newStyles
      style = parseInt(style)
      if style == 0
        @reset()
      else if style == 1
        @bright = true
      else if 30 <= style <= 39 and style != 38
        @_applyStyle('foreground', style)
      else if 40 <= style <= 49 and style != 48
        @_applyStyle('background', style)
      else if style == 4
        @underline = true
      else if style == 24
        @underline = false

  reset: ->
    @background = @foreground = 'default'
    @underline = @bright = false

  toClass: ->
    classes = []
    if @background
      classes.push("ansi-background-#{@background}")
    if @foreground
      classes.push("ansi-foreground-#{@foreground}")
    if @bright
      classes.push("ansi-bright")
    if @underline
      classes.push("ansi-underline")

    classes.join(" ")

  _applyStyle: (layer, number) ->
    this[layer] = COLORS[number % 10]

class AnsiSpan
  ENTITIES =
    '&': '&amp;'
    '<': '&lt;'
    '>': '&gt;'
    "'": '&#x27;'

  ESCAPE_PATTERN = new RegExp("[#{(Object.keys(ENTITIES).join(''))}]", 'g');

  create: (text, style) ->
    "<span class='#{style.toClass()}'>#{@_escapeHTML(text)}</span>"

  _escapeHTML: (text) ->
    text.replace ESCAPE_PATTERN, (char) ->
      ENTITIES[char]
