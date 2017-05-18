$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fancy_gets'

# Listen to stdout, receiving arrow directions, text, newlines, and backspaces.
# Return an array of what each line of the screen would hold.
def fake_terminal(x_size, y_size)
  begin
    allow(IO.console).to receive(:winsize).at_least(:once).and_return([y_size, x_size])

    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    lines = y_size.times.inject([]){|s, v| s << Array.new(x_size, ' ')}
    x = 0
    y = 0
    idx = 0
    while idx < $stdout.string.length
      ch = $stdout.string[idx]
      if ch.ord == 27 # Escape?
        case $stdout.string[idx + 2].ord
        when 65 # Up
          y -= 1
        when 66 # Down
          y += 1
        when 67 # Right
          x += 1
        when 68 # Left
          x -= 1
        end
        idx += 3
      elsif ch == "\b" # Backspace (which really acts mostly like a left arrow)
        x -= 1 unless x == 0
        idx += 1
      elsif ch == "\n" # Newline
        x = 0
        y += 1
        idx += 1
      else
        lines[y][x] = ch
        x += 1
        if x == x_size
          y += 1
          x = 0
        end
        idx += 1
      end
      if y > y_size
        raise RuntimeError, "Went past vertical terminal space for #{x_size} x #{y_size} window.  (And scrolling is not implemented yet)"
      end
    end
    {lines: lines.map(&:join), x: x, y: y, chars: $stdout.string}
  ensure
    $stdout = original_stdout
  end
end
