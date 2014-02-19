# Mulligan

"a free shot sometimes given a golfer in informal play when the previous shot was poorly played"

## Installation

Add this line to your application's Gemfile:

    gem 'mulligan'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mulligan

## Usage

The Mulligan gem allows you to decouple the code that a exception-handling strategy from the code which decides which strategy to use.

In other words, when you handle a `Mulligan::Exception` in your rescue clause, you can choose from a set of strategies (called "restarts") exposed by the exception to take the stack back to where `Kernel#raise` was called, execute your strategy, and pretend that the exception was never raised.

More documentation coming, but for now, look in the spec directory for usage.

## Influences
- [Beyond Exception Handling: Conditions and Restarts](http://www.gigamonkeys.com/book/beyond-exception-handling-conditions-and-restarts.html) -- (from [Practical Common Lisp](http://www.gigamonkeys.com/book/))
- [Things You Didn't Know About Exceptions](http://avdi.org/talks/rockymtnruby-2011/things-you-didnt-know-about-exceptions.html) (Avdi Grimm)
- [Restartable Exceptions](http://chneukirchen.org/blog/archive/2005/03/restartable-exceptions.html) (Christian Neukirchen)
- [Common Lisp conditions](https://www.ruby-forum.com/topic/179474) (Ruby Forum)

## Contributing

1. Fork it ( http://github.com/michaeljbishop/mulligan)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
