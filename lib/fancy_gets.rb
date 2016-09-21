require "fancy_gets/version"
require 'io/console'

module FancyGets
  def gets_auto_suggest(words = nil, default = "")
    FancyGets.gets_internal_core(false, false, words, default)
  end

  def gets_password(default = "")
    FancyGets.gets_internal_core(false, true, nil, default)
  end

  # Show a list of stuff, potentially some highlighted, and allow people to up-down arrow around and pick stuff
  def gets_list(words, is_multiple = false, chosen = nil, prefix = "> ", postfix = " <", info = nil, height = nil)
    on_change = nil
    on_select = nil
    if words.is_a? Hash
      is_multiple = words[:is_multiple] || false
      chosen = words[:chosen]
      prefix = words[:prefix] || "> "
      postfix = words[:postfix] || " <"
      info = words[:info]
      height = words[:height] || nil
      on_change = words[:on_change]
      on_select = words[:on_select]
      words = words[:list]
    else
      # Trying to supply parameters but left out a "true" for is_multiple?
      if is_multiple.is_a?(Enumerable) || is_multiple.is_a?(String) || is_multiple.is_a?(Fixnum)
        chosen = is_multiple
        is_multiple = false
      end
    end
    # Slightly inclined to ditch this in case the things they're choosing really are Enumerable
    is_multiple = true if chosen.is_a?(Enumerable)
    FancyGets.gets_internal_core(true, is_multiple, words, chosen, prefix, postfix, info, height, on_change, on_select)
  end

  # The internal routine that makes all the magic happen
  def self.gets_internal_core(is_list, is_password, word_objects = nil, chosen = nil, prefix = "> ", postfix = " <", info = nil, height = nil, on_change = nil, on_select = nil)
    # OK -- second parameter, is_password, means is_multiple when is_list is true
    is_multiple = is_list & is_password
    unless word_objects.nil? || is_list
      word_objects.sort! {|wo1, wo2| wo1.to_s <=> wo2.to_s}
    end
    words = word_objects.map(&:to_s)
    if is_multiple
      chosen ||= [0] unless is_multiple
    else
      if chosen.is_a?(Enumerable)
        # Maybe find first string or object that matches the stuff they have sequenced in the chosen array
        string = chosen.first.to_s
      else
        string = chosen.to_s
      end
    end
    position = 0
    # After tweaking the down arrow code, might work OK with 3 things
    height = words.length unless !height.nil? && height.is_a?(Numeric) && height >= 4
    winheight = IO.console.winsize.first - 3
    height = words.length if height > words.length
    height = winheight if height > winheight
    offset = 0
    sugg = ""
    prev_sugg = ""

    # gsub causes any color changes to not offset spacing
    uncolor = lambda { |word| word.gsub(/\033\[[0-9;]+m/, "") }

    max_word_length = words.map{|word| uncolor.call(word).length}.max

    write_sugg = lambda do
      # Find first word that case-insensitive matches what they've typed
      if string.empty?
        sugg = ""
      else
        sugg = words.select { |word| uncolor.call(word).downcase.start_with? string.downcase }.first || ""
      end
      extra_spaces = uncolor.call(prev_sugg).length - uncolor.call(sugg).length
      extra_spaces = 0 if extra_spaces < 0
      " - #{sugg}#{" " * extra_spaces} #{"\b" * ((uncolor.call(sugg).length + 4 + extra_spaces) + string.length - position)}"
    end

    pre_length = uncolor.call(prefix).length
    post_length = uncolor.call(postfix).length
    pre_post_length = pre_length + post_length

    # Used for dropdown select / deselect
    clear_dropdown_info = lambda do
      print "\b" * (uncolor.call(words[position]).length + pre_post_length)
      print (27.chr + 91.chr + 66.chr) * ((height + offset) - position)
      info_length = uncolor.call(info).length
      print " " * info_length + "\b" * info_length
    end
    make_select = lambda do |is_select, is_go_to_front = false, is_end_at_front = false|
      word = words[position]
      print "\b" * (uncolor.call(word).length + pre_post_length) if is_go_to_front
      if is_select
        print "#{prefix}#{word}#{postfix}"
      else
        print "#{" " * pre_length}#{word}#{" " * post_length}"
      end
      print " " * (max_word_length - uncolor.call(words[position]).length)
      print "\b" * (max_word_length - uncolor.call(words[position]).length)
      print "\b" * (uncolor.call(word).length + pre_post_length) if is_end_at_front
    end

    write_info = lambda do |new_info|
      # Put the response into the info line, as long as it's short enough!
      new_info.gsub!("\n", " ")
      new_info_length = uncolor.call(new_info).length
      console_width = IO.console.winsize.last
      # Might have to trim if it's a little too wide
      new_info = new_info[0...console_width] if console_width < new_info_length
      # Arrow down to the info line
      distance_down = (height + offset) - position
      print (27.chr + 91.chr + 66.chr) * distance_down
      # To start of info line
      word_length = uncolor.call(words[position]).length + pre_post_length
      print "\b" * word_length
      # Write out the new response
      prev_info_length = uncolor.call(info).length
      difference = prev_info_length - new_info_length
      difference = 0 if difference < 0
      print new_info + " " * difference
      info = new_info
      # Go up to where we originated
      print (27.chr + 91.chr + 65.chr) * distance_down
      # Arrow left or right to get to the right spot again
      new_info_length += difference
      print (new_info_length > word_length ? "\b" : (27.chr + 91.chr + 67.chr)) * (new_info_length - word_length).abs
    end

    handle_on_select = lambda do |focused|
      if on_select.is_a? Proc
        response = on_select.call({chosen: chosen, focused: focused})
        new_info = nil
        if response.is_a? Hash
          chosen = response[:chosen] || chosen
          new_info = response[:info]
        elsif response.is_a? String
          new_info = response
        end
        unless new_info.nil?
          write_info.call(new_info)
        end
      end
    end

    # **********************************************
    # ******************** DOWN ********************
    # Doesn't work with a height of 3 when there's more than 3 in the list
    # (somehow up arrow can work OK with this)
    arrow_down = lambda do
      if position < words.length - 1
        is_shift = false
        handle_on_select.call(word_objects[position + 1])
        # Now moving down past the bottom of the shown window?
        is_before_end = height + offset < words.length
        if is_before_end && position == (height - 2) + offset
          print "\b" * (uncolor.call(words[position]).length + pre_post_length)
          print (27.chr + 91.chr + 65.chr) * (height - 3)
          if offset == 0
            print (27.chr + 91.chr + 65.chr)
            puts "#{" " * pre_length}#{"↑" * max_word_length}"
          end
          offset += 1
          ((offset + 1)..(offset + (height - 4))).each do |i|
            end_fill = max_word_length - uncolor.call(words[i]).length
            puts (is_multiple && chosen.include?(i)) ? "#{prefix}#{words[i]}#{postfix}#{" " * end_fill}" : "#{" " * pre_length}#{words[i]}#{" " * (end_fill + post_length)}"
          end
          is_shift = true
        end
        make_select.call(chosen.include?(position) && is_shift && is_multiple, true, true) if is_shift || !is_multiple
        w1 = uncolor.call(words[position]).length
        position += 1
        print 27.chr + 91.chr + 66.chr
        if is_shift || !is_multiple
          if is_shift && height + offset == words.length  # Go down and write the last one
            print 27.chr + 91.chr + 66.chr
            position += 1
            make_select.call(is_shift && chosen.include?(position), false, true)
            print 27.chr + 91.chr + 65.chr  # And back up
            position -= 1
          end
          make_select.call((chosen.include?(position) && is_shift) || !is_multiple)
        else
          w2 = uncolor.call(words[position]).length
          print (w1 > w2 ? "\b" : (27.chr + 91.chr + 67.chr)) * (w1 - w2).abs
        end
      end
    end

    # **********************************************
    # ********************** UP ********************
    arrow_up = lambda do
      if position > 0
        is_shift = false
        handle_on_select.call(word_objects[position - 1])
        # Now moving up past the top of the shown window?
        if position > 1 && position <= offset + 1 # - (offset > 1 ? 0 : -1)
          print "\b" * (uncolor.call(words[position]).length + pre_post_length)
          offset -= 1
          # Up next to the top, and write the first word over the up arrows
          if offset == 0
            print (27.chr + 91.chr + 65.chr)
            end_fill = max_word_length - uncolor.call(words[0]).length
            puts (is_multiple && chosen.include?(0)) ? "#{prefix}#{words[0]}#{postfix}#{" " * end_fill}" : "#{" " * pre_length}#{words[0]}#{" " * (end_fill + post_length)}"
          end
          ((offset + 1)..(offset + height - 2)).each do |i|
            end_fill = max_word_length - uncolor.call(words[i]).length
            puts ((!is_multiple && i == (offset + 1)) || (is_multiple && chosen.include?(i))) ? "#{prefix}#{words[i]}#{postfix}#{" " * end_fill}" : "#{" " * pre_length}#{words[i]}#{" " * (end_fill + post_length)}"
          end
          if offset == words.length - height - 1
            puts "#{" " * pre_length}#{"↓" * max_word_length}"
            print (27.chr + 91.chr + 65.chr)
          end
          print (27.chr + 91.chr + 65.chr) * (height - 2)
          is_shift = true
          position -= 1
          w1 = -pre_post_length
        else
          make_select.call(chosen.include?(position) && is_shift && is_multiple, true, true) if is_shift || !is_multiple
          w1 = uncolor.call(words[position]).length
          position -= 1
          print 27.chr + 91.chr + 65.chr
        end
        if !is_shift && !is_multiple
          make_select.call(chosen.include?(position) || !is_multiple)
        else
          w2 = uncolor.call(words[position]).length
          print (w1 > w2 ? "\b" : (27.chr + 91.chr + 67.chr)) * (w1 - w2).abs
        end
      end
    end

    # Initialize everything
    if is_list
      # Maybe confirm the height is adequate by checking out IO.console.winsize
      case chosen.class.name
      when "Fixnum"
        chosen = [chosen]
      when "String"
        if words.include?(chosen)
          chosen = [words.index(chosen)]
        else
          chosen = []
        end
      when "Array"
        chosen.each_with_index do |item, i|
          case item.class.name
          when "String"
            chosen[i] = words.index(item)
          when "Fixnum"
            chosen[i] = nil if item < 0 || item >= words.length
          else
            chosen[i] = word_objects.index(item)
          end
        end
        chosen.select{|item| !item.nil?}.uniq
      else
        if word_objects.include?(chosen)
          chosen = [word_objects.index(chosen)]
        else
          chosen = []
        end
      end
      chosen ||= []
      chosen = [0] if chosen == [] && !is_multiple
      position = chosen.first if chosen.length > 0
      # If there's more options than we can fit at once
      if height < words.length
        # ... put the chosen one a third of the way down the screen
        offset = position - (height / 3)
        offset = words.length - height if offset > words.length - height
      end

      # **********************************************
      # **********************************************
      # **********************************************
      # **********************************************
      # **********************************************

      # Scrolled any amount downwards?
      #   was: if height < words.length
      puts "#{" " * pre_length}#{"↑" * max_word_length}" if offset > 0
      last_word = (height - 2) + offset + (height + offset < words.length ? 0 : 1)
      # Write all the visible words
      ((offset + (offset > 0 ? 1 : 0))..last_word).each { |i| puts chosen.include?(i) ? "#{prefix}#{words[i]}#{postfix}" : "#{" " * pre_length}#{words[i]}" }
      # Can't fit it all?
      puts "#{" " * pre_length}#{"↓" * max_word_length}" if height + offset < words.length

      info ||= "Use arrow keys#{is_multiple ? ", spacebar to toggle, and ENTER to save" : " and ENTER to make a choice"}"
      print info + (27.chr + 91.chr + 65.chr) * ((last_word - position) + (height + offset < words.length ? 2 : 1))
      # To end of text on starting line
      info_length = uncolor.call(info).length
      word_length = uncolor.call(words[position]).length + pre_post_length
      print (info_length > word_length ? "\b" : (27.chr + 91.chr + 67.chr)) * (info_length - word_length).abs
    else
      position = string.length
      if is_password
        print "*" * string.length
      else
        print string + write_sugg.call
      end
    end
    loop do
      ch = STDIN.getch
      code = ch.ord
      case code
      when 3 # CTRL-C
        clear_dropdown_info.call if is_list
        # puts "o: #{offset} p: #{position} h: #{height} wl: #{words.length}"
        exit
      when 13 # ENTER
        if is_list
          clear_dropdown_info.call
        else
          print "\n"
        end
        break
      when 27  # ESC -- which means lots of special stuff
        case ch = STDIN.getch.ord
        when 79  # Function keys
          # puts "ESC 79"
          case ch = STDIN.getch.ord
          when 80 #F1
            # puts "F1"
          when 81 #F2
          when 82 #F3
          when 83 #F4
          when 84 #F5
          when 85 #F6
          when 86 #F7
          when 87 #F8
          when 88 #F9
          when 89 #F10
          when 90 #F11
          when 91 #F12
            # puts "F12"
          when 92 #F13
          end
        when 91 # Arrow keys
          case ch = STDIN.getch.ord
          when 68 # Arrow left
            if !is_list && position > 0
              print "\b" # 27.chr + 91.chr + 68.chr
              position -= 1
            end
          when 67 # Arrow right
            if !is_list && position < string.length
              print 27.chr + 91.chr + 67.chr
              position += 1
            end
          when 66 # - down
            if is_list
              arrow_down.call
            end
          when 65 # - up
            if is_list
              arrow_up.call
            end
          when 51 # - Delete forwards?
          else
            # puts "ESC 91 #{ch}"
          end
        else
          # Something wacky?
          # puts "code #{ch} #{STDIN.getch.ord} #{STDIN.getch.ord} #{STDIN.getch.ord} #{STDIN.getch.ord}"
        end
      when 127 # Backspace
        if !is_list && position > 0
          string = string[0...position - 1] + string[position..-1]
          if words.nil?
            position -= 1
            print "\b#{is_password ? "*" * (string.length - position) : string[position..-1]} #{"\b" * (string.length - position + 1)}"
          else
            prev_sugg = sugg
            position -= 1
            print "\b#{string[position..-1]}#{write_sugg.call}"
          end
        end
      when 126 # Delete (forwards)
        if !is_list && position < string.length
          string = string[0...position] + string[position + 1..-1]
          if words.nil?
            print "#{is_password ? "*" * (string.length - position) : string[position..-1]} #{"\b" * (string.length - position + 1)}"
          else
            prev_sugg = sugg
            print "#{string[position..-1]}#{write_sugg.call}"
          end
        end
      else # Insert character
        if is_list
          case ch
          when " "
            if is_multiple
              # Toggle this entry
              does_include = chosen.include?(position)
              is_rejected = false
              if on_change.is_a? Proc
                # Generate what would happen if this change goes through
                if does_include
                  new_chosen = chosen - [position]
                else
                  new_chosen = chosen + [position]
                end
                chosen_objects = new_chosen.sort.map{|choice| word_objects[choice]}
                response = on_change.call({chosen: chosen_objects, changed: word_objects[position], is_chosen: !does_include})
                new_info = nil
                if response.is_a? Hash
                  is_rejected = response[:is_rejected]
                  # If they told us exactly what the choices should now be, make that happen
                  if !response.nil? && response[:chosen].is_a?(Enumerable)
                    chosen = response[:chosen].map {|choice| word_objects.index(choice)}
                    is_rejected = true
                  end
                  new_info = response[:info]
                elsif response.is_a? String
                  new_info = response
                end
                unless new_info.nil?
                  write_info.call(new_info)
                end
              end
              unless is_rejected
                if does_include
                  chosen -= [position]
                else
                  chosen += [position]
                end
                make_select.call(!does_include, true)
              end
            else
              # Allows Windows to have a way to at least use single-select lists
              clear_dropdown_info.call
              break
            end
          when "j"  # Down
            arrow_down.call
          when "k"  # Up
            arrow_up.call
          end
        else
          string = string[0...position] + ch + string[position..-1]
          if words.nil?
            ch = "*" if is_password
            position += 1
            print "#{ch}#{is_password ? "*" * (string.length - position) : string[position..-1]}#{"\b" * (string.length - position)}"
          else
            prev_sugg = sugg
            position += 1
            print "#{ch}#{string[position..-1]}#{write_sugg.call}"
          end
        end
      end
    end

    if is_list
      # Put chosen stuff in same order as it's listed in the words array
      is_multiple ? chosen.sort.map {|c| word_objects[c] } : word_objects[position]
    else
      sugg.empty? ? string : word_objects[words.index(sugg)]
    end
  end
end
