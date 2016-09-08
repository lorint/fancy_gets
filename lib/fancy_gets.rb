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
  def gets_list(words, is_multiple = false, chosen = [], prefix = "> ", postfix = " <", info = nil)
    # Trying to supply parameters but left out a "true" for is_multiple?
    if is_multiple.is_a?(Array)
      chosen = is_multiple
      is_multiple = true
    end
    if is_multiple.is_a?(String) || is_multiple.is_a?(Fixnum)
      chosen = is_multiple
      is_multiple = false
    end
    is_multiple = true if chosen.is_a?(Array) && chosen.length > 1
    FancyGets.gets_internal_core(true, is_multiple, words, chosen, prefix, postfix, info)
  end

  # The internal routine that makes all the magic happen
  def self.gets_internal_core(is_list, is_password, words = nil, chosen = [], prefix = "> ", postfix = " <", info = nil)
    # OK -- second parameter, is_password, means is_multiple when is_list is true
    is_multiple = is_list & is_password
    words.sort! unless words.nil? || is_list
    string = chosen if chosen.is_a?(String)
    position = 0
    sugg = ""
    prev_sugg = ""

    # gsub causes any color changes to not offset spacing
    uncolor = lambda { |word| word.gsub(/\033\[[0-9;]+m/, "") }

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

    pre_post_length = uncolor.call(prefix + postfix).length

    # Used for dropdown select / deselect
    clear_dropdown_info = lambda do
      print "\b" * (uncolor.call(words[position]).length + pre_post_length)
      print (27.chr + 91.chr + 66.chr) * (words.length - position)
      info_length = uncolor.call(info).length
      print " " * info_length + "\b" * info_length
    end
    make_select = lambda do |is_select, is_go_to_front = false, is_end_at_front = false|
      word = words[position]
      print "\b" * (uncolor.call(word).length + pre_post_length) if is_go_to_front
      if is_select
        print "#{prefix}#{word}#{postfix}"
      else
        print "#{" " * uncolor.call(prefix).length}#{word}#{" " * uncolor.call(postfix).length}"
      end
      print "\b" * (uncolor.call(word).length + pre_post_length) if is_end_at_front
    end

    if is_list
      # Maybe confirm the height is adequate by checking out IO.console.winsize
      case chosen.class.name
      when "Fixnum"
        chosen = [words[chosen]]
      when "String"
        if words.include?(chosen)
          chosen = [chosen]
        else
          chosen = []
        end
      end
      chosen ||= []
      chosen = [words[0]] if chosen == [] && !is_multiple
      position = words.index(chosen.first) if chosen.length > 0
      words.each { |word| puts chosen.include?(word) ? "#{prefix}#{word}#{postfix}" : "#{" " * uncolor.call(prefix).length}#{word}" }
      info ||= "Use arrow keys#{is_multiple ? ", spacebar to toggle, and ENTER to save" : " and ENTER to make a choice"}"
      print info + (27.chr + 91.chr + 65.chr) * (words.length - position)
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
            if position > 0
              print "\b" # 27.chr + 91.chr + 68.chr
              position -= 1
            end
          when 67 # Arrow right
            if position < string.length
              print 27.chr + 91.chr + 67.chr
              position += 1
            end
          when 66 # - down
            if is_list && position < words.length - 1
              make_select.call(false, true, true) unless is_multiple
              w1 = uncolor.call(words[position]).length
              position += 1
              print 27.chr + 91.chr + 66.chr
              if is_multiple
                w2 = uncolor.call(words[position]).length
                print (w1 > w2 ? "\b" : (27.chr + 91.chr + 67.chr)) * (w1 - w2).abs
              else
                make_select.call(true)
              end
            end
          when 65 # - up
            if is_list && position > 0
              make_select.call(false, true, true) unless is_multiple
              w1 = uncolor.call(words[position]).length
              position -= 1
              print 27.chr + 91.chr + 65.chr
              if is_multiple
                w2 = uncolor.call(words[position]).length
                print (w1 > w2 ? "\b" : (27.chr + 91.chr + 67.chr)) * (w1 - w2).abs
              else
                make_select.call(true)
              end
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
          if is_multiple && ch == " "
            # Toggle this entry
            word = words[position]
            does_include = chosen.include?(word)
            if does_include
              chosen -= [word]
            else
              chosen += [word]
            end
            make_select.call(!does_include, true)
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
      chosen = words.select { |word| chosen.include?(word) }
      is_multiple ? chosen : words[position]
    else
      sugg.empty? ? string : sugg
    end
  end
end
