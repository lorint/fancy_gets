require 'spec_helper'
include FancyGets

describe FancyGets do
  before do
    @list = ["Skimboard", "Volleyball", "Kite", "Beach Ball", "Water Gun", "Frisbee"]
    # Fake out a 80x10 window
    allow(IO.console).to receive(:winsize).at_least(:once).and_return([10, 80])
  end

  it 'should have a version number' do
    expect(FancyGets::VERSION).to_not be nil
  end

  describe "when using gets_list" do
    describe "keyboard interaction with single select" do
      it 'should allow the ENTER key to choose a list item' do
        # Just press ENTER
        expect(STDIN).to receive(:getch).and_return(13.chr)
        expect(gets_list(@list)).to eq("Skimboard")
      end

      it 'should allow the down arrow to access a second item' do
        expect(STDIN).to receive(:getch).and_return(
          27.chr, 91.chr, 66.chr, # Down arrow
          13.chr)                 # Enter
        expect(gets_list(@list)).to eq("Volleyball")
      end

      it 'should allow the down arrow and up arrow to be used' do
        expect(STDIN).to receive(:getch).and_return(
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 65.chr, # Up arrow
          13.chr)                 # Enter
        expect(gets_list(@list)).to eq("Skimboard")
      end

      it 'should not wrap around when the selection is already at the top and the up arrow is used' do
        expect(STDIN).to receive(:getch).and_return(
          27.chr, 91.chr, 66.chr, # Down arrow
          27.chr, 91.chr, 65.chr, # Up arrow
          27.chr, 91.chr, 65.chr, # Up arrow
          13.chr)                 # Enter
        expect(gets_list(@list)).to eq("Skimboard")
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
        expect(gets_list(@list)).to eq("Frisbee")
      end
    end

    describe "keyboard interaction with multiple select" do
      it 'should allow the SPACE BAR to choose a list item' do
        # Just press SPACE and ENTER
        expect(STDIN).to receive(:getch).and_return(" ", 13.chr)
        expect(gets_list(@list, true)).to eq(["Skimboard"])
      end

      it 'should allow multiple items to be chosen' do
        expect(STDIN).to receive(:getch).and_return(
          27.chr, 91.chr, 66.chr, # Down arrow
          " ",                    # Space
          27.chr, 91.chr, 66.chr, # Down arrow
          " ",                    # Space
          13.chr)                 # Enter
        expect(gets_list(@list, true)).to eq(["Volleyball", "Kite"])
      end
    end
  end

  describe "when using gets_auto_suggest" do
    it 'should pick a list item with just a few keystrokes' do
      # Just press ENTER
      expect(STDIN).to receive(:getch).and_return(
        "B",
        "e",
        13.chr)   # Enter
      expect(gets_auto_suggest(@list)).to eq("Beach Ball")
    end

    it 'should be case-insensitive' do
      expect(STDIN).to receive(:getch).and_return(
        "b",
        "E",
        "A",
        13.chr)   # Enter
      expect(gets_auto_suggest(@list)).to eq("Beach Ball")
    end

    it 'should just return the typed text when the first few letters match but not the whole thing' do
      expect(STDIN).to receive(:getch).and_return(
        "B",
        "e",
        "a",
        "X",
        13.chr)   # Enter
      expect(gets_auto_suggest(@list)).to eq("BeaX")
    end

    it 'should allow arrow keys to edit the text' do
      expect(STDIN).to receive(:getch).and_return(
        "e",
        27.chr, 91.chr, 68.chr, # Left arrow
        "B",
        27.chr, 91.chr, 67.chr, # Right arrow
        "a",
        13.chr)                 # Enter
      expect(gets_auto_suggest(@list)).to eq("Beach Ball")
    end

    it 'should allow backspace and delete keys to edit the text' do
      expect(STDIN).to receive(:getch).and_return(
        "X",
        "B",
        "e",
        "X",
        127.chr,                # Backspace
        "a",
        "c",
        27.chr, 91.chr, 68.chr, # Left arrow
        27.chr, 91.chr, 68.chr, # Left arrow
        27.chr, 91.chr, 68.chr, # Left arrow
        27.chr, 91.chr, 68.chr, # Left arrow
        27.chr, 91.chr, 68.chr, # Left arrow
        126.chr,                # Delete
        13.chr)                 # Enter
      expect(gets_auto_suggest(@list)).to eq("Beach Ball")
    end
  end
end
