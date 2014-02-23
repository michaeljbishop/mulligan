Features
========

Specify restart strategies for a given Exception
------------------------------------------------
Simply put, this adds "restarts" to the `Exception` class which allows exception raisers to specify multiple strategies for recovering from the exception. The strategies are attached to the Exception instance which travel as the stack unwinds to the enclosing `rescue` clause higher up on the stack. That rescue clause can then invoke a recovery strategy.

What is special is that when the recovery strategy is invoked, the stack is recreated to the point in time where the Exception was raised and the recovery strategy is invoked in *that* context, as if the exception were never raised to begin with. This allows code higher up in abstraction to inject recovery into low-level code making the low-level code more reusable.

In pseudocode:

    def inner_function
      raise
      <specify some restarts here>
    end

    def outer_function
      inner_function # will cause an exception with restarts
    rescue Exception => e
      # here we specify a recovery and we are able to repair the lower
      # level code as if it never threw an exception to begin with
      e.restart <strategy id>
    end


Restart strategies can accept parameters
----------------------------------------
In addition, restarts can accept parameters to affect their implementation. In this way, when a restart is invoked, some state can be passed to it, affecting its execution.

Future Ideas
============

Specify restarts using a nice DSL
---------------------------------
We should be be able to specify restart clauses using a nice, concise language.

Here are some examples:

    raise Exception, "Could not do the thing!" do
      restart :ignore do
        # simply doing nothing ignores the error
      end
      restart :replace_entry do |replacement|
        replacement
      end
    end


Be able to catch an exception and add restarts to it before rethrowing it
-------------------------------------------------------------------------
We should be able to catch an exception from below, and add our own strategies to it

Here is an example:

    def rethrow
      should_retry = false
      inner_call
    rescue Exception => e
      e.add_restarts do
        restart :retry do
          should_retry = true
        end
      end
      retry if should_retry
    end

When overriding a restart, should be able to call previous restart (super?)
-------------------------------------------------------------------------

Here is an example:

    def rethrow
      inner_call
    rescue Exception => e
      e.add_restarts do |super_restarts|
        restart :fix do
          super_restarts[:fix].call
        end
      end
    end

Restarts can have some metadata associated with them
----------------------------------------------------
Like LISP, it would be nice to be able to handle these in the debugger by default. The debugger should be able to specify a nice interface to the user by outputting messages from the metatdata associated with a restart strategy (like a description of what it does and what parameters it will take)


`#raise` will return the strategy chosen and the return value of the strategy
-----------------------------------------------------------------------------
    chosen = raise "can't to the thing" do
      restart :ignore do
        5
      end
    end

    puts chosen # => [:ignore, 5]


Exceptions can carry data with them from the raise condition that the rescuers can use
--------------------------------------------------------------------------------------
I'm not sure if this is totally needed and think it's a separate item, *but* here's what it might look like:

    class Exception
      attr_reader :restart_data
      def initialize(m, message = "", c = callback, options={}, &restart_block)
        @restart_data = options[:restart_data]
      end
    end


Smalltalk has some built-in strategies
--------------------------------------
- #exit, #resume (like ignore, it means just continue as if it hadn't been thrown)
- #outer (reraise with the same strategy identifier except that now returns to this point)
- #pass (reraise the exception)
- #resignalAs:. Raise a different class of exception in place of the current exception, as if the new class of exception had been raised in the first place.
- #retry (note: not sure how we can make this a built-in)The try-block associated with the handler (i.e. the receiver of the #on:do: to which it is the last argument) is re-evaluated. Of course it is pointless retrying if the same exception will be raised, and this is an easy way to create an infinite loop (though Ctrl+Break should
#retryUsing: Substitute the argument as the new try block, and #retry. This has particular application for operations which have fast implementations for commonly used execution paths, and slower implementations for less common usages. get you out of trouble). - Super-interesting. Wonder if we might try it.

Dylan has a way of attaching a standard set of recoveries to a given Exception class
------------------------------------------------------------------------------------
So a given Exception class would have a documented set of recoveries (they refer to it as a protocol)

You can use a global variable to reference the last restart taken
-----------------------------------------------------------------
One of the difficult problems to solve is, what should #raise return? Currently, it returns the array of the restart chosen and the result of the restart block. I really like that we can get the result of the restart block, but I really don't like that methods written with raise that are ignored suddenly implicitly return an array. Yet to implement a property retry, it's important to know which restart was executed. I'd like the cleanliness of #raise returning only the return value of the block and the cleanliness of being able to know which restart was chosen.

One solution is to have #raise return the value straight through and use a thread-local global variable that holds the id of the last invoked restart. So far, the only use case I've seen that requires that information is to do a retry inside a rescue clause.


