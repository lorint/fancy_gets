require 'spec_helper'
include FancyGets

describe FancyGets do
  before do
    @list = ["Skimboard", "Volleyball", "Kite", "Beach Ball", "Water Gun", "Frisbee"]
  end

  it 'should have a version number' do
    expect(FancyGets::VERSION).to_not be nil
  end

  describe "When using gets_list" do
    describe "Keyboard interaction with single select" do
      it 'should allow the ENTER key to choose a list item' do
        # Just press ENTER
        expect(STDIN).to receive(:getch).and_return(13.chr)
        term = fake_terminal(80, 10) do
          expect(gets_list(@list)).to eq("Skimboard")
        end
        expect(term[:lines][0][0..12]).to eq("> Skimboard <")
        expect(term[:x]).to eq(0)
        expect(term[:y]).to eq(6)
      end

      it 'should allow the down arrow to access a second item' do
        expect(STDIN).to receive(:getch).and_return(
          27.chr, 91.chr, 66.chr, # Down arrow
          13.chr)                 # Enter
        term = fake_terminal(80, 10) do
          expect(gets_list(@list)).to eq("Volleyball")
        end
        expect(term[:lines][0][0..12]).to eq("  Skimboard  ")
        expect(term[:lines][1][0..13]).to eq("> Volleyball <")
        expect(term[:x]).to eq(0)
        expect(term[:y]).to eq(6)
      end

      it 'should allow the down arrow and up arrow to be used' do
        expect(STDIN).to receive(:getch).and_return(
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 65.chr, # Up arrow
          13.chr)                 # Enter
        term = fake_terminal(80, 10) do
          expect(gets_list(@list)).to eq("Skimboard")
        end
        expect(term[:lines][0][0..12]).to eq("> Skimboard <")
        expect(term[:lines][1][0..13]).to eq("  Volleyball  ")
        expect(term[:x]).to eq(0)
        expect(term[:y]).to eq(6)
      end

      it 'should not wrap around when the selection is already at the top and the up arrow is used' do
        expect(STDIN).to receive(:getch).and_return(
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 65.chr, # Up arrow
          27.chr, 91.chr, 65.chr, # Up arrow
          13.chr)                 # Enter
        term = fake_terminal(80, 10) do
          expect(gets_list(@list)).to eq("Skimboard")
        end
        expect(term[:lines][0][0..12]).to eq("> Skimboard <")
        expect(term[:x]).to eq(0)
        expect(term[:y]).to eq(6)
      end

      it 'should not wrap around when the selection is already at the bottom and the down arrow is used' do
        expect(STDIN).to receive(:getch).and_return(
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 66.chr, # Down arrow
          13.chr)                 # Enter
        term = fake_terminal(80, 10) do
          expect(gets_list(@list)).to eq("Frisbee")
        end
        expect(term[:lines][5][0..10]).to eq("> Frisbee <")
        expect(term[:x]).to eq(0)
        expect(term[:y]).to eq(6)
      end

      it 'should accommodate shorter windows by having arrows to show continuation' do
        expect(STDIN).to receive(:getch).and_return(
          13.chr)                 # Enter
        term = fake_terminal(80, 7) do
          expect(gets_list(list: @list)).to eq("Skimboard")
        end
        expect(term[:lines].map{|line| line[0..12]}).to include("> Skimboard <")
        # Not enough room to show the last one
        expect(term[:lines].map{|line| line[0..10]}).to_not include("  Frisbee  ")
        expect(term[:lines][3..-1].map{|line| line[0..13]}).to include("  ↓↓↓↓↓↓↓↓↓↓  ")

        expect(STDIN).to receive(:getch).and_return(
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 66.chr, # Down arrow
          13.chr)                 # Enter
        term = fake_terminal(80, 7) do
          expect(gets_list(list: @list)).to eq("Water Gun")
        end
        expect(term[:lines].map{|line| line[0..12]}).to include("> Water Gun <")
        # We've already scrolled past the first one
        expect(term[:lines].map{|line| line[0..12]}).to_not include("  Skimboard  ")
        expect(term[:lines][0][0..13]).to eq("  ↑↑↑↑↑↑↑↑↑↑  ")
      end
    end

    describe "Keyboard interaction with multiple select" do
      it 'should allow the SPACE BAR to choose a list item' do
        # Just press SPACE and ENTER
        expect(STDIN).to receive(:getch).and_return(" ", 13.chr)
        term = fake_terminal(80, 10) do
          expect(gets_list(@list, true)).to eq(["Skimboard"])
        end
        expect(term[:lines][0][0..12]).to eq("> Skimboard <")
        expect(term[:x]).to eq(0)
        expect(term[:y]).to eq(6)
      end

      it 'should allow multiple items to be chosen' do
        expect(STDIN).to receive(:getch).and_return(
          27.chr, 91.chr, 66.chr, # Down arrow
          " ",                    # Space
          27.chr, 91.chr, 66.chr, # Down arrow
          " ",                    # Space
          13.chr)                 # Enter
        term = fake_terminal(80, 10) do
          expect(gets_list(@list, true)).to eq(["Volleyball", "Kite"])
        end
        expect(term[:lines][0][0..12]).to eq("  Skimboard  ")
        expect(term[:lines][1][0..13]).to eq("> Volleyball <")
        expect(term[:lines][2][0..7]).to eq("> Kite <")
        expect(term[:x]).to eq(0)
        expect(term[:y]).to eq(6)
      end
    end
  end

  describe "When using gets_password, it:" do
    it 'should mask the typed characters with asterisks' do
      expect(STDIN).to receive(:getch).and_return(
        "C", "o", "o", "l", "B", "e", "a", "n", "s", "~", 13.chr)
      term = fake_terminal(80, 10) do
        expect(gets_password()).to eq("CoolBeans~")
      end
      expect(term[:lines][0][0..11]).to eq("**********  ")
    end

    it 'should allow arrow keys to edit the text' do
      expect(STDIN).to receive(:getch).and_return(
        "a",
        27.chr, 91.chr, 68.chr, # Left arrow
        "C",
        27.chr, 91.chr, 67.chr, # Right arrow
        "t",
        13.chr)                 # Enter
      term = fake_terminal(80, 10) do
        expect(gets_password()).to eq("Cat")
      end
      expect(term[:lines][0][0..5]).to eq("***   ")
    end

    it 'should allow backspace and delete keys to edit the text' do
      expect(STDIN).to receive(:getch).and_return(
        "X",
        "P",
        "a",
        "X",
        127.chr,                         # Backspace
        "s",
        "s",
        27.chr, 91.chr, 68.chr,          # Left arrow
        27.chr, 91.chr, 68.chr,          # Left arrow
        27.chr, 91.chr, 68.chr,          # Left arrow
        27.chr, 91.chr, 68.chr,          # Left arrow
        27.chr, 91.chr, 68.chr,          # Left arrow
        27.chr, 91.chr, 51.chr, 126.chr, # Delete
        13.chr)                          # Enter
      term = fake_terminal(80, 10) do
        expect(gets_password()).to eq("Pass")
      end
      expect(term[:lines][0][0..5]).to eq("****  ")
    end
  end

  describe "When using gets_auto_suggest, it:" do
    it 'should pick a list item with just a few keystrokes' do
      expect(STDIN).to receive(:getch).and_return(
        "B", "e", 13.chr)
      term = fake_terminal(80, 10) do
        expect(gets_auto_suggest(@list)).to eq("Beach Ball")
      end
      expect(term[:lines][0][0..14]).to eq("Be - Beach Ball")
    end

    it 'should be case-insensitive' do
      expect(STDIN).to receive(:getch).and_return(
        "b", "E", "A", 13.chr)   # Enter
      term = fake_terminal(80, 10) do
        expect(gets_auto_suggest(@list)).to eq("Beach Ball")
      end
      expect(term[:lines][0][0..15]).to eq("bEA - Beach Ball")
    end

    it 'should just return the typed text when the first few letters match but not the whole thing' do
      expect(STDIN).to receive(:getch).and_return(
        "B", "e", "a", "X", 13.chr)   # Enter
      term = fake_terminal(80, 10) do
        expect(gets_auto_suggest(@list)).to eq("BeaX")
      end
      expect(term[:lines][0][0..16]).to eq("BeaX -           ")
    end

    it 'should allow arrow keys to edit the text' do
      expect(STDIN).to receive(:getch).and_return(
        "e",
        27.chr, 91.chr, 68.chr, # Left arrow
        "B",
        27.chr, 91.chr, 67.chr, # Right arrow
        "a",
        13.chr)                 # Enter
      term = fake_terminal(80, 10) do
        expect(gets_auto_suggest(@list)).to eq("Beach Ball")
      end
      expect(term[:lines][0][0..15]).to eq("Bea - Beach Ball")
    end

    it 'should allow backspace and delete keys to edit the text' do
      expect(STDIN).to receive(:getch).and_return(
        "X",
        "B",
        "e",
        "X",
        127.chr,                         # Backspace
        "a",
        "c",
        27.chr, 91.chr, 68.chr,          # Left arrow
        27.chr, 91.chr, 68.chr,          # Left arrow
        27.chr, 91.chr, 68.chr,          # Left arrow
        27.chr, 91.chr, 68.chr,          # Left arrow
        27.chr, 91.chr, 68.chr,          # Left arrow
        27.chr, 91.chr, 51.chr, 126.chr, # Delete
        13.chr)                          # Enter
      term = fake_terminal(80, 10) do
        expect(gets_auto_suggest(@list)).to eq("Beach Ball")
      end
      expect(term[:lines][0][0..16]).to eq("Beac - Beach Ball")
    end
  end
end
