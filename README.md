[![Build Status](https://travis-ci.org/michaeljbishop/mulligan.png?branch=master)](https://travis-ci.org/michaeljbishop/mulligan)

<img src="images/mulligan-logo.png" height="159" width="396" alt="Mulligan">

"In golf, a mulligan is a stroke that is replayed from the spot of the previous stroke without penalty, due to an errant shot made on the previous stroke. The result is, as the hole is played and scored, as if the first errant shot had never been made." -- [Wikipedia](http://en.wikipedia.org/wiki/Mulligan_(games)#Mulligan_in_golf)

## Usage

### Two Stories

#### The Spy Before Radios Were Invented

> Once upon a time, there was a spy who had to infiltrate a 17 floor building, each new floor thick with guards. On the top floor was a safe to which he was given a combination. The safe would blow up if the wrong combination was used so he had to be careful. He successfully arrived at the safe after sneaking through all the floors and then he realized on his notes, the combination he was given was "66-99-66".
>
> To his dismay, he couldn't tell if he was reading it upside-down, and because radios hadn't yet been invented, Intelligence couldn't be contacted and not knowing what to do, he bailed on the mission by jumping out the window and was rescued on the ground by the allies. They told him he was holding the combination upside-down but now he'd have to again go through all 17 floors.

This the current state of Ruby exception handling. Once an exception is raised, you "abort the mission" and jump out the window where you are rescued. But then you have to start the mission again.

#### The Spy After Radios Were Invented

Here's the story again, but let's pretend radios now exist:

> Once upon a time, there was a spy ... yada yada yada... It was then that he realized the combination he was given was 66-99-66.
>
> ***Because this mission now includes radios***, he was able to call intelligence, tell them what was happening and they told him he was holding the note upside-down. He then continued the mission by turning the note right-side-up and opening the safe.

The Mulligan gem adds to your exception handling, the radio from the second story. The Ruby `rescue` clause is like 'Intelligence' who receives the call (as an Exception instance). But attached to that Exception instance are 'recovery objects' which contain data about how to solve the problem. By invoking a recovery object, the code continues to exit without the mission aborting.

### Code Example

Here's a very simple contrived example:
```ruby
 1 require 'mulligan'
 2 
 3 def method_that_raises
 4   puts "RAISING"
 5   case recovery
 6   when IgnoringRecovery
 7     puts "IGNORING"
 8   else
 9     raise "You can ignore this"
10   end
11   puts "AFTER RAISE"
12 end
13
14 def calling_method
15   method_that_raises
16   "SUCCESS"
17 rescue Exception => e
18   puts "RESCUED"
19   recover IgnoringRecovery
10   puts "HANDLED"
21 end
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

### How come we didn't see "HANDLED" in that output?

Here's what happened in detail:

1. `#method_that_raises` is called from `#calling_method` (line 15)
2. `#method_that_raises` raises an exception *but* before it is raised, a "recovery" can be added to the exception (line 6). That 'when' statement actually creates a an instance of `IgnoringRecovery`.
3. The exception is then raised (line 9) and rescued (line 17)
4. The "recovery" on the exception is called (line 19) which takes program execution back to line 7.
5. Now, we are inside code that has succeeded the test in then `when` of line 6. Now it hits the `else` clause and skips the `#raise`
6. The method exits (line 12) and we return to line 16 as if we never saw the exception.
7. We exit the method because there's no exception to rescue (line 21). The last value in the function was "SUCCESS" so that is returned.

### Use Cases

The truth is, often when we throw an exception in code, we probably could actually continue if we just knew what to do. Specifying recoveries allows you to suggest some options to the rescuing code.

Not only that, you can apply a recovery strategy to large parts of code by handling exceptions at a high level and recovering from them.

From the Dylan Language Manual:

> A condition is an object used to locate and provide information to a handler. A condition represents a situation that needs to be handled. Examples are errors, warnings, and attempts to recover from errors.

("condition" is what we are calling "exception" in Ruby)

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
    case recovery
    when RetryingRecovery
      retry
    else
      raise e
    end
end

def save_resources
  post_resource(user)
  post_resource(post)
  post_resource(comment)

  rescue CredentialsExpiredException => e
    ... fix credentials...
    recover RetryingRecovery
  rescue ConnectionFailedException => e
    ... switch from wifi to cellular...
    recover RetryingRecovery
end
```

#### Screen Scraping (in Dylan)

[I'm glad I used Dylan (comp.lang.dylan)](https://groups.google.com/d/msg/comp.lang.dylan/gszO7d7BAok/zqVbQlNDKzAJ)

This is going to be inherently messy and for a long-running program like this, potentially painful to restart if the data is found to be incorrect. Much better to just put in some recoveries and choose from them if errors are found.

#### Handling errors in parsers

You might write a parser to read XML or a log file format and it might encounter malformed entries. You can make that low-level parser code much more reusable if you specify a few recoveries in the raised exceptions. Higher level code will have many more choices to handle errors.

#### Ask your friendly Lisp coder. They've been solving these problems for years.

You've always known he (or she) knew Lisp and now you have something to ask him about.

## Basic API
### Kernel#recovery

#### To Start A Case Statement

`recovery` is used at the beginning of a `case` structure to indicate that each `when` clause is defining a `Recovery` instance to be attached to the next raised `Exception` instance.

Here is the structure for using it:

```ruby
case recovery
when <recovery_class>           # or
  ...code
when <recovery_class>.new(...)  # or
  ...code
when <method_or_statement_that_returns_recovery_instance_or_class>
  ...code
else
  raise <exception>
end
```

The structure for this has to be quite strict. You *have* to put the raise inside the `else` and not before. (For more explanation, see the Appendix)

#### To Retrieve a Recovery

You can also call `recovery(<recovery_class>)` when inside a rescue statement to see if there is a recovery attached to the exception that fits that class.

```ruby
rescue Exception => e
  recover(IgnoringRecovery) unless recovery(IgnoringRecovery).nil?
```

### Kernel#recover

Inside a `rescue` clause, this invokes the recovery object. There is no return value from this. Code execution now proceeds back down into the stack to to the location in the case statement that matches the recovery class.

```ruby
rescue Exception => e
  recover(IgnoringRecovery) unless recovery(IgnoringRecovery).nil?
```

Also note that you can pass arguments which can be retrieved by the code implementing the `Recovery`.

### Mulligan::Recovery

`Mulligan::Recovery` is the base class of all recoveries. Use this in the same way you use the `Exception` hierarchy, but for recoveries. You can define your own subclasses with different properties that can be read by the `rescue` clauses.

#### 'message' attribute
This is a human-readable description of what the `Recovery` does. It can be set at the time of raising, or if it's not set, will return `#default_message`

#### #default_message
It's very important that you specify the `#default_message` method in your subclass. If your exception bubbles to the top-level within Pry, you can inspect the attached `Recovery` instances and execute them yourself. Without that `#default_message` method, you'll have no idea what a given Recovery will do.

## Supported Rubies

[![Build Status](https://travis-ci.org/michaeljbishop/mulligan.png?branch=master)](https://travis-ci.org/michaeljbishop/mulligan)
Mulligan fully supports MRI versions 1.9.3 -> 2.1.1

Mulligan will gracefully degrade to standard exception handling on other platforms. Though the API will be there, no recoveries will be attached to Exceptions.

- If `Kernel#recover` is called in a Ruby that doesn't fully support Mulligan, it will be ignored and code execution will continue. This allows you to first try a recovery and after that, write the code that you would do before you had Mulligan.

```ruby
rescue TimeoutException => e
  # retry the operation
  recover(RetryingRecovery)
  # if we get here, it's because there is no RetryingRecovery, or we don't have Mulligan
  raise e
```

## FAQ

### "Recovery"? What's wrong with "Restart"?

I had to make a hard choice about naming the thing that allows an exception to be recovered from. "Restart" is the word used in Lisp, but because it is used as a verb and as a noun, it makes it hard to know what a Ruby method named `#restart` would do. Does it return a "restart" or does it execute a restart?

Changing the name to a noun subtracts that confusion (though arguably adds some back for those coming from languages where the "restart" name is entrenched).

### Will Mulligan let me resume from all exceptions?

No. If an exception didn't have recoveries attached when it was raised, you will not be able to call them. It is incumbent on the code that raises the exception to add the recoveries so they can control the error-handling flow.

## Influences
- [Beyond Exception Handling: Conditions and Restarts](http://www.gigamonkeys.com/book/beyond-exception-handling-conditions-and-restarts.html) -- (from [Practical Common Lisp](http://www.gigamonkeys.com/book/))
- [Things You Didn't Know About Exceptions](http://avdi.org/talks/rockymtnruby-2011/things-you-didnt-know-about-exceptions.html) (Avdi Grimm)
- [Restartable Exceptions](http://chneukirchen.org/blog/archive/2005/03/restartable-exceptions.html) (Christian Neukirchen)
- [Common Lisp conditions](https://www.ruby-forum.com/topic/179474) (Ruby Forum)

### Acknowledgements
Thanks to [Ryan Angilly](https://twitter.com/angilly) of [Ramen](https://ramen.is) who graciously released the gem name 'mulligan' to be used with this project. If you've got a good software project, consider launching with them.

## Further Reading
- [Dylan Reference Manual - Conditions - Background](http://opendylan.org/books/drm/Conditions_Background)

## Appendix

I had to pull off some tricks to achieve the `case` structure in Mulligan. If I had more control over the Ruby Language, my preferred syntax for specifying recoveries would be:

```ruby
raise [Exception [, message [, backtrace]]]
  # ... code that is always executed during a recovery
recovery <Recover class>
  # ... recovery code
recovery <Recover class> => args
  # ... recovery code that uses the args passed back
end
```



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

## Add Mulligans to your API

Show off your Mulligans! Feel free to add the following html to your repo...

<textarea readonly="readonly" cols="50">&lt;a href=&quot;http://github.com/michaeljbishop/mulligan&quot;&gt;&lt;img src=&quot;images/mulligan-badge.png&quot; height=&quot;47&quot; width=&quot;66&quot; alt=&quot;Mulligan&quot;&gt;&lt;/a&gt;</textarea>

<a href="http://github.com/michaeljbishop/mulligan"><img src="images/mulligan-badge.png" height="47" width="66" alt="Mulligan"></a>


## Homepage

[http://michaeljbishop.github.io/mulligan/](http://michaeljbishop.github.io/mulligan/)
