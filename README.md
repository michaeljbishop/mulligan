# Mulligan

"In golf,...a stroke that is replayed from the spot of the previous stroke without penalty, due to an errant shot made on the previous stroke. The result is, as the hole is played and scored, as if the first errant shot had never been made." -- [Wikipedia](http://en.wikipedia.org/wiki/Mulligan_(games)#Mulligan_in_golf)

## Usage

When rescuing an exception, the Mulligan gem allows you to execute some recovery code, then continue your program as if the exception had never been thrown in the first place

Here's a very simple contrived example:
```ruby
 1 require 'mulligan'
 2 
 3 def method_that_raises
 4   puts "RAISING"
 5   raise "You can ignore this" do |e|
 6     e.set_recovery :ignore do
 7       puts "IGNORING"
 8     end
 9   end
10   puts "AFTER RAISE"
11 end
12
13 def calling_method
14   method_that_raises
15   "SUCCESS"
16   rescue Exception => e
17     puts "RESCUED"
18     e.recover :ignore
19     puts "HANDLED"
20 end
```

Running this at the REPL shows:

```
2.0.0-p353 :009 > calling_method
RAISING
RESCUED
IGNORING
AFTER RAISE
 => "SUCCESS" 
```

### Yeah... wait, shouldn't we see "HANDLED" in that output?!

Here's what happened in detail:

1. `#method_that_raises` is called from `#calling_method` (line 14)
2. `#method_that_raises` raises an exception *but* before it is raised, a "recovery" can be added to the exception (line 6) in the block passed to `#raise`. (The exception is the parameter 'e' passed to the `#raise` block)
3. The exception is then raised (line 5) and rescued (line 16)
4. The "recovery" on the exception is called (line 18) which executes the statement in the recovery block (defined on line 7).
5. Since the exception has recovered, control taks us back to the point *immediately after the block passed to* `#raise` (line 10), continuing as if `#raise` hadn't been called in the first place.
6. The method exits (line 11) and we return to line 15 as if we never saw the exception.
7. We exit the method because there's no exception to rescue (line 20). The last value in the function was "SUCCESS" so that is returned.

### I see what you did. That's cool, but why should I care?

You should care because your `rescue` statement is likely to be far from the `raise` in your program's execution and the further away it is, the harder it is to fix the error intelligently. It's even harder if that `raise` comes from a library you are calling.

Specifying recoveries on the exception allows the lower-level code to offer strategies for fixing the exception without the higher-level code needing to know the internals of those strategies.

Better yet, it offers the ability to "go back in time" [Groundhog Day](http://en.wikipedia.org/wiki/Groundhog_Day_(film))-style, but this time, your code knows how to play the piano, how to sculpt ice, and how to speak French.

Find your favorite chair and read these:

- [Dylan Reference Manual - Conditions - Background](http://opendylan.org/books/drm/Conditions_Background)
- [Beyond Exception Handling: Conditions and Restarts](http://www.gigamonkeys.com/book/beyond-exception-handling-conditions-and-restarts.html) (keep in mind the "restarts" are what we are calling "recoveries").

### So I'm convinced this is a good thing, but what can I do with it?

Here are some use cases:

#### Fixing network connection errors

```ruby
def http_post(url, data)
  ... networking code...
  raise CredentialsExpiredException if response == 401
  raise ConnectionFailedException if response == 404
end

def post_resource(object)
  ... assemble url and data...
  http_post(url, data)
  rescue Exception => e
    retry if raise(e){|e|e.set_recovery(:retry){true}}
end

def save_resources
  post_resource(user)
  post_resource(post)
  post_resource(comment)

  rescue CredentialsExpiredException => e
    ... fix credentials...
    e.recover :retry
  rescue ConnectionFailedException => e
    ... switch from wifi to cellular...
    e.recover :retry
end
```

#### Screen Scraping (in Dylan)

[The maling list post](https://groups.google.com/d/msg/comp.lang.dylan/gszO7d7BAok/zqVbQlNDKzAJ)

This is going to be inherently messy and for a long-running program like this, potentially painful to restart if the data is found to be incorrect. Much better to just put in some recoveries and choose from them if errors are found.

#### Handling errors in parsers

You might write a parser to read XML or a log file format and it might encounter malformed entries. You can make that low-level parser code much more reusable if you specify a few recoveries in the raised exceptions. Higher level code will have many more choices to handle errors.

BTW, Here's your second chance to read [Beyond Exception Handling: Conditions and Restarts](http://www.gigamonkeys.com/book/beyond-exception-handling-conditions-and-restarts.html). There's a log file parsing example in there.

#### Ask your friendly Lisp coder. They've been solving these problems for years.

You've always known he (or she) knew Lisp and now you have something to ask him about.

## Some Notes About the Ruby Implementation

- You can pass parameters to `Exception#recover`. The first parameter is always the id of the recovery. The rest will be passed directly to the recovery block.
- You can pass an options hash to the `rescue` clause that is attached to your recovery. This is handy if you want to attach extra data about the recovery or the circumstances in which it is being raised. Pass them as the second parameter in `Exception#set_recovery`. You can retrieve them with `Exception#recovery_options`. Reserved keys are `:summary`, and `:discussion`
- `Kernel#raise` now has a return value! The return value from the recovery block is returned from the `#raise` that raised it. So you can do nifty things like this:

```ruby
begin
  ... some code ...
rescue Exception => e
  retry if raise(e){|e|e.set_recovery(:retry){true}}
end
```

### #callcc

There is more than one way to do this. In the end, I wanted something that would fit very naturally into Ruby's existing Exception mechanism, yet offer as much of the benefits of Lisp's "restart" as I could.

However, to make that happen, I had to use the `#callcc` method. I'm not completely sure how supported this is across different Ruby implementations. Additionally, I've read that it can be a rather slow method. It's important to note that if an exception is raised but does not have any attached recoveries, `#callcc` will not be called and the standard exception mechanism is used.

### Ruby 2.0 required

This is a superficial requirement. It's only because I'm using the `prepend` keyword to open up the `Exception` class and `Kernel` Module. There's an [issue for this](https://github.com/michaeljbishop/mulligan/issues/1).


### "Recovery"?

I had to make a hard choice about naming the thing that allows an exception to be recovered from. "Restart" is the word used in Lisp, but because it is used as a verb and as a noun, it makes it hard to know what a Ruby method named `#restart` would do. Does it return a "restart" or does it execute a restart?

Changing the name to a noun clears up that confusion (though arguably adds a new one for those coming from languages where the "restart" name is entrenched).

## Influences
- [Beyond Exception Handling: Conditions and Restarts](http://www.gigamonkeys.com/book/beyond-exception-handling-conditions-and-restarts.html) -- (from [Practical Common Lisp](http://www.gigamonkeys.com/book/))
- [Things You Didn't Know About Exceptions](http://avdi.org/talks/rockymtnruby-2011/things-you-didnt-know-about-exceptions.html) (Avdi Grimm)
- [Restartable Exceptions](http://chneukirchen.org/blog/archive/2005/03/restartable-exceptions.html) (Christian Neukirchen)
- [Common Lisp conditions](https://www.ruby-forum.com/topic/179474) (Ruby Forum)

## Installation

Add this line to your application's Gemfile:

    gem 'mulligan'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mulligan

## Contributing

1. Fork it [http://github.com/michaeljbishop/mulligan](http://github.com/michaeljbishop/mulligan)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
