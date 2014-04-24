describe('Document', ->
  beforeEach( ->
    @container = $('#editor-container').html('').get(0)
  )

  describe('constructor', ->
    tests =
      'blank':
        initial:  ''
        expected: ''
      'no change':
        initial:  '<div><span>Test</span></div>'
        expected: '<div><span>Test</span></div>'
      'text':
        initial:  'Test'
        expected: '<div><span>Test</span></div>'
      'inline':
        initial:  '<span>Test</span>'
        expected: '<div><span>Test</span></div>'
      'block pulling':
        initial:  '<div><div><div><div><span>Test</span><div>Test</div></div></div></div></div>'
        expected: '<div><span>Test</span></div><div><span>Test</span></div>'
      'with blocks':
        initial:  '<div><span>A</span><br><span>B</span><br><span>C</span></div>'
        expected: '<div><span>A</span><br></div><div><span>B</span><br></div><div><span>C</span></div>'
      'pull and break':
        initial:  '<div><div><div><span>A</span></div><span>B</span><br><span>C</span></div></div>'
        expected: '<div><span>A</span></div><div><span>B</span><br></div><div><span>C</span></div>'

    _.each(tests, (test, name) ->
      it(name, ->
        @container.innerHTML = "<div>#{test.initial}</div>"
        doc = new Quill.Document(@container.firstChild, { formats: Quill.DEFAULTS.formats })
        expect(@container.firstChild).toEqualHTML(test.expected, true)
      )
    )
  )

  describe('search', ->
    beforeEach( ->
      @container.innerHTML = '
        <div>
          <div><span>0123</span></div>
          <div><br></div>
          <div><b>6789</b></div>
        </div>
      '
      @doc = new Quill.Document(@container.firstChild, { formats: Quill.DEFAULTS.formats })
    )

    it('findLine() lineNode', ->
      line = @doc.findLine(@doc.root.firstChild)
      expect(line).toEqual(@doc.lines.first)
    )

    it('findLine() not a line', ->
      node = @doc.root.ownerDocument.createElement('i')
      node.innerHTML = '<span>Test</span>'
      @doc.root.appendChild(node)
      line = @doc.findLine(node)
      expect(line).toBe(null)
    )

    it('findLine() not in doc', ->
      line = @doc.findLine($('#toolbar-container').get(0))
      expect(line).toBe(null)
    )

    it('findLine() id false positive', ->
      clone = @doc.root.firstChild.cloneNode(true)
      @doc.root.appendChild(clone)
      line = @doc.findLine(clone)
      expect(line).toBe(null)
    )

    it('findLine() leaf node', ->
      line = @doc.findLine(@doc.root.querySelector('b'))
      expect(line).toEqual(@doc.lines.last)
    )

    it('findLineAt() middle of line', ->
      [line, offset] = @doc.findLineAt(2)
      expect(line).toEqual(@doc.lines.first)
      expect(offset).toEqual(2)
    )

    it('findLineAt() last line', ->
      [line, offset] = @doc.findLineAt(8)
      expect(line).toEqual(@doc.lines.last)
      expect(offset).toEqual(2)
    )

    it('findLineAt() end of line', ->
      [line, offset] = @doc.findLineAt(4)
      expect(line).toEqual(@doc.lines.first)
      expect(offset).toEqual(4)
    )

    it('findLineAt() newline', ->
      [line, offset] = @doc.findLineAt(5)
      expect(line).toEqual(@doc.lines.first.next)
      expect(offset).toEqual(0)
    )

    it('findLineAt() end of document', ->
      [line, offset] = @doc.findLineAt(11)
      expect(line).toBe(@doc.lines.last)
      expect(offset).toEqual(5)
    )

    # TODO add test where finding line beyond last line (when line level format is present)

    it('findLineAt() beyond document', ->
      [line, offset] = @doc.findLineAt(12)
      expect(line).toBe(null)
      expect(offset).toEqual(1)
    )
  )

  describe('manipulation', ->
    beforeEach( ->
      @container.innerHTML = Quill.Normalizer.stripWhitespace('
        <div>
          <div><span>Test</span></div>
          <div><i>Test</i></div>
          <div><br></div>
          <div><br></div>
          <div><b>Test</b></div>
        </div>
      ')
      @doc = new Quill.Document(@container.firstChild, { formats: Quill.DEFAULTS.formats })
      @lines = @doc.lines.toArray()
    )

    it('mergeLines() normal', ->
      @doc.mergeLines(@lines[0], @lines[1])
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span><i>Test</i></div>
        <div><br></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length - 1)
    )

    it('mergeLines() with newline', ->
      @doc.mergeLines(@lines[1], @lines[2])
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span></div>
        <div><i>Test</i></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length - 1)
    )

    it('mergeLines() from newline', ->
      @doc.mergeLines(@lines[3], @lines[4])
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span></div>
        <div><i>Test</i></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length - 1)
    )

    it('mergeLines() two newlines', ->
      @doc.mergeLines(@lines[2], @lines[3])
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span></div>
        <div><i>Test</i></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length - 1)
    )

    it('removeLine() existing', ->
      @doc.removeLine(@lines[1])
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span></div>
        <div><br></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length - 1)
    )

    it('removeLine() lineNode missing', ->
      Quill.DOM.removeNode(@lines[1].node)
      @doc.removeLine(@lines[1])
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span></div>
        <div><br></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length - 1)
    )

    it('splitLine() middle', ->
      @doc.splitLine(@lines[1], 2)
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span></div>
        <div><i>Te</i></div>
        <div><i>st</i></div>
        <div><br></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length + 1)
    )

    it('splitLine() beginning', ->
      @doc.splitLine(@lines[1], 0)
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span></div>
        <div><br></div>
        <div><i>Test</i></div>
        <div><br></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length + 1)
    )

    it('splitLine() end', ->
      @doc.splitLine(@lines[1], 4)
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span></div>
        <div><i>Test</i></div>
        <div><br></div>
        <div><br></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length + 1)
    )

    it('splitLine() beyond end', ->
      @doc.splitLine(@lines[1], 5)
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span></div>
        <div><i>Test</i></div>
        <div><br></div>
        <div><br></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length + 1)
    )

    it('splitLine() split break', ->
      @doc.splitLine(@lines[2], 0)
      expect(@doc.root).toEqualHTML('
        <div><span>Test</span></div>
        <div><i>Test</i></div>
        <div><br></div>
        <div><br></div>
        <div><br></div>
        <div><b>Test</b></div>
      ', true)
      expect(@doc.lines.length).toEqual(@lines.length + 1)
    )

    it('setHTML() valid', ->
      html = '<div><span>Test</span></div>'
      @doc.setHTML(html)
      expect(@doc.root).toEqualHTML(html, true)
    )

    it('setHTML() invalid', ->
      @doc.setHTML('
        <div>
          <div>
            <div>
              <span>A</span>
            </div>
            <span>B</span>
            <br>
            <span>C</span>
          </div>
        </div>
        <div>
          <b></b>
        </div>
      ')
      expect(@doc.root).toEqualHTML('
        <div>
          <span>A</span>
        </div>
        <div>
          <span>B</span><br>
        </div>
        <div>
          <span>C</span>
        </div>
        <div>
          <b><br></b>
        </div>
      ', true)
    )
  )

  describe('toDelta()', ->
    tests =
      'blank':
        initial:  ['']
        expected: Tandem.Delta.getInitial('')
      'single line':
        initial:  ['<div><span>0123</span></div>']
        expected: Tandem.Delta.getInitial('0123\n')
      'single newline':
        initial:  ['<div><br></div>']
        expected: Tandem.Delta.getInitial('\n')
      'preceding newline':
        initial:  ['<div><br></div>', '<div><span>0</span></div>']
        expected: Tandem.Delta.getInitial('\n0\n')
      'explicit trailing newline':
        initial:  ['<div><span>0</span></div>', '<div><br></div>']
        expected: Tandem.Delta.getInitial('0\n\n')
      'multiple lines':
        initial:  ['<div><span>0</span></div>', '<div><span>1</span></div>']
        expected: Tandem.Delta.getInitial('0\n1\n')
      'multiple newlines':
        initial:  ['<div><br></div>', '<div><br></div>']
        expected: Tandem.Delta.getInitial('\n\n')
      'multiple preceding newlines':
        initial:  ['<div><br></div>', '<div><br></div>', '<div><span>0</span></div>']
        expected: Tandem.Delta.getInitial('\n\n0\n')
      'multiple explicit trailing newlines':
        initial:  ['<div><span>0</span></div>', '<div><br></div>', '<div><br></div>']
        expected: Tandem.Delta.getInitial('0\n\n\n')
      'lines separated by multiple newlines':
        initial:  ['<div><span>0</span></div>', '<div><br></div>', '<div><span>1</span></div>']
        expected: Tandem.Delta.getInitial('0\n\n1\n')
      'tag format':
        initial:  ['<div><b>0123</b></div>']
        expected: Tandem.Delta.makeDelta({ startLength: 0, endLength: 5, ops: [
          { value: '0123', attributes: { bold: true } }
          { value: '\n' }
        ]})
      'style format':
        initial:  ['<div><span style="color: teal;">0123</span></div>']
        expected: Tandem.Delta.makeDelta({ startLength: 0, endLength: 5, ops: [
          { value: '0123', attributes: { color: 'teal' } }
          { value: '\n' }
        ]})

    _.each(tests, (test, name) ->
      it(name, ->
        @container.innerHTML = test.initial.join('')
        doc = new Quill.Document(@container, { formats: Quill.DEFAULTS.formats })
        expect(doc.toDelta()).toEqualDelta(test.expected)
      )
    )
  )
)
