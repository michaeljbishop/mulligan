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
