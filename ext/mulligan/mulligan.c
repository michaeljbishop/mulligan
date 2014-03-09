#include <ruby.h>


// -----------------------------------------------------------
//  UTILITIES
// -----------------------------------------------------------

#define ARRAY_SIZE(var) (sizeof(var)/sizeof(var[0]))

// -----------------------------------------------------------
//  DECLARATIONS
// -----------------------------------------------------------

static VALUE rb_mulligan_raise(int argc, VALUE *argv, VALUE self);
static VALUE callcc_block(VALUE c, VALUE in_context, int argc, VALUE argv[]);
static VALUE __set_continuation__block(VALUE unused, VALUE in_context, int argc, VALUE argv[]);

static ID id_recoveries = 0;
static ID id_empty_ = 0;
static ID id_send = 0;
static ID id_callcc = 0;
static ID id_call = 0;
static ID id___set_continuation__ = 0;
static ID id_puts = 0;

// ===========================================================
//  MAIN ENTRY POINT
// ===========================================================

void Init_mulligan(void)
{
  VALUE mMulligan = rb_define_module("Mulligan");
  VALUE mKernel = rb_define_module_under(mMulligan, "Kernel");
  rb_define_method(mKernel, "raise", rb_mulligan_raise, -1);

  rb_require("continuation");
  id_recoveries = rb_intern("recoveries");
  id_empty_ = rb_intern("empty?");
  id_send = rb_intern("send");
  id_callcc = rb_intern("callcc");
  id_call = rb_intern("call");
  id___set_continuation__ = rb_intern("__set_continuation__");
  id_puts = rb_intern("puts");
}


/* -----------------------------------------------------------
//  Here is the template ruby code that we are approximating
//  in C. Native-only calls are surround by <<>>
// -----------------------------------------------------------
def raise(*args)
  e = <<make_exception(*args)>>
  yield e if block_given?

  # only use callcc if there are restarts otherwise re-raise it
  <<rb_exc_raise(e)>> if e.send(:recoveries).empty?
  should_raise = true
  result = callcc do |c|
    e.send(:__set_continuation__) do |*args,&block|
      should_raise = false
      c.call(*args,&block)
    end
  end
  <<rb_exc_raise(e)>> if should_raise
  result
end
// -----------------------------------------------------------
// There is one big difference which is at all costs, we only
// call `rb_exc_raise` from the current frame. This is important
// because we want the stack-trace and current stack-frame to
// be identical to what they were if we just called the standard
// #raise method. If we call `rb_exc_raise` within a block or
// call super, we will lose that stack-frame context.
// For this reason, you'll see that awkward `should_raise` variable
// in the source above.
// -----------------------------------------------------------*/


static VALUE
rb_mulligan_raise(int argc, VALUE *argv, VALUE self)
{
    // -----------------------------------------------------------
    //  Get a reference to the Exception object
    // -----------------------------------------------------------
    VALUE e = rb_make_exception(argc, argv);
    
    // -----------------------------------------------------------
    //  With the Exception in place, yield to the block
    // -----------------------------------------------------------
    if (rb_block_given_p())
      rb_yield(e);

    // -----------------------------------------------------------
    //  If there are no recoveries, just throw it without a callcc
    // -----------------------------------------------------------
    VALUE recoveries = rb_funcall(e, id_send, 1, ID2SYM(id_recoveries));
    VALUE is_empty = rb_funcall(recoveries, id_empty_, 0);
    if (RTEST(is_empty))
        goto raise;
    
    // -----------------------------------------------------------
    //  There are recoveries so we first capture the continuation
    //  using callcc
    // -----------------------------------------------------------

    // A note about should_raise_ary:
    // 2 callbacks from now (in `__set_continuation__block`) we are
    // going to want to change the value of this from true to false. Since Qtrue
    // is not a pointer, we are going to make a ghetto-pointer by putting it in
    // an array of one. That array will be passed to the callback where it will be
    // modified and we can read it still in this context after all the callbacks
    // are complete.
    VALUE should_raise_ary = rb_ary_to_ary(Qtrue);

    VALUE contextVars[] = {self, should_raise_ary, e};
    VALUE context = rb_ary_new4(ARRAY_SIZE(contextVars), contextVars);
    
    VALUE result = rb_block_call(
        self,
        id_callcc,
        0, // argc
        0, // argv
        RUBY_METHOD_FUNC(callcc_block),
        context
        );

    // Here we read our "pointer"
    if (!RTEST(rb_ary_entry(should_raise_ary, 0)))
      return result;

raise:
    rb_exc_raise(e);
    UNREACHABLE;
}

static VALUE
callcc_block(VALUE c, VALUE in_context, int argc, VALUE argv[])
{
    VALUE self =             rb_ary_entry(in_context, 0);
    VALUE should_raise_ary = rb_ary_entry(in_context, 1);
    VALUE e =                rb_ary_entry(in_context, 2);

    VALUE contextVars[] = {self, should_raise_ary, c};
    VALUE context = rb_ary_new4(ARRAY_SIZE(contextVars), contextVars);
    VALUE block_argv[1] = {ID2SYM(id___set_continuation__)};

    return rb_block_call(
        e,
        id___set_continuation__,
        0, // argc
        0, // argv
        RUBY_METHOD_FUNC(__set_continuation__block),
        context // data2
        );
}

static VALUE
__set_continuation__block(VALUE unused, VALUE in_context, int argc, VALUE argv[])
{
    VALUE self =             rb_ary_entry(in_context, 0);
    VALUE should_raise_ary = rb_ary_entry(in_context, 1);
    VALUE c =                rb_ary_entry(in_context, 2);

    // Here we set our `should_raise` pointer back to false
    rb_ary_store(should_raise_ary, 0, Qfalse);
    
    VALUE proc = rb_block_proc();
    
    return rb_funcall_with_block(c, id_call, argc, argv, proc);
}





