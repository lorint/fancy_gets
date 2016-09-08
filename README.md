# FancyGets

This gem exists to banish crusty UX that our users endure at the command line.

For far too long we've been stuck with just gets and getc.  When prompting the
user with a list of choices, wouldn't it be nice to have the feel of a < select >
in HTML?  Or to auto-suggest options as they type?  Or perhaps offer a password
entry with asterisks instead of just sitting silent, which confuses many users?

Read on.

## Installation

Very straightforward ... this simple entry in the Gemfile, after which make sure to run "bundle":

```ruby
gem 'fancy_gets'
```

Or have it end up in your /usr/lib/ruby/gems/... folder with:

    $ gem install fancy_gets

And at the top of any CLI app do the require and include:

```ruby
require 'fancy_gets'
include FancyGets
```

And then you can impress all manner of people accustomed to the stark limitations
of command line apps.  Heck, this even makes them fun again.

## gets_list

Imagine you have this cool array of beach things.  Have the user pick one.

```ruby
toys = ["Skimboard", "Volleyball", "Kite", "Beach Ball", "Water Gun", "Frisbee"]
picked_toy = gets_list(toys)
puts "\nBringing a #{picked_toy} sounds like loads of fun at the beach."
```

And perhaps a little later you'd like to ask again what they'd like, plus
give a default of what they had picked before.

```ruby
new_toy = gets_list(toys, picked_toy)
puts "\nCool!  This time you've brought a #{new_toy}."
```

If you don't prefer the default > Toy Name < prompts, feel free to have your own
prefix and suffix applied to choices as the user arrows up and down, and supply
your own prompt text if you like.  This is the full syntax for gets_list, and
the false indicates it's not doing multiple choice.

```ruby
another_toy = gets_list(toys, false, nil, "==>", "<== PARTY TIME!", "Use arrows to pick something awesome.")
puts "\nSo much to love about #{another_toy}."
```

Another cool thing this allows is to change the color of selected items.  You may want
to check out Michał Kalbarczyk's [colorize gem](https://github.com/fazibear/colorize "Michał loves all things \033") for more info.

```ruby
another_toy = gets_list(toys, false, nil, "\033[1;31m", "\033[0m <==", "Use arrows to pick something awesome.")
puts "\nSo much to love about #{another_toy}."
```

Easy to have multiple choices, and bring back an array.  In this case it already
has chosen the kite and water gun.

```ruby
picked_toys = gets_list(toys, true, ["Kite", "Water Gun"])
puts "\nYou've picked #{picked_toys.join(", ")}."
```

## gets_auto_suggest

Still using the same cool array of things, let's have the user see auto-suggest text
as they type.  As soon as the proper term appears, they can hit ENTER and the full
string for that item is returned.  The search is case and color insensitive.

```ruby
toys = ["Skimboard", "Volleyball", "Kite", "Beach Ball", "Water Gun", "Frisbee"]
picked_toy = gets_auto_suggest(toys)
puts "\nYou chose #{picked_toy}."
```

And as above, you can offer a default choice.  This can be set with a full or partial
string.

```ruby
new_toy = gets_auto_suggest(toys, picked_toy[0..2])
puts "\nChanging it up for #{new_toy}."
```

## gets_password

The final bit of coolness is a simple guarded password entry.  All variables used
by the gem are local, so after returning a response any plain text which was entered
does not stick around past a garbage collection.

```ruby
pwd = gets_password
puts "\nI think I heard you whisper, \"#{pwd}\"."
```

This also allows default text to be provided, although I can't easily think of a
circumstance in which that's useful.  But perhaps to you it could be.

Bug reports and pull requests are welcome: https://github.com/lorint/fancy_gets.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
