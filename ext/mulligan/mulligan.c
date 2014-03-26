#include <ruby.h>

// -----------------------------------------------------------
//  DECLARATIONS
// -----------------------------------------------------------

static VALUE rb_mg_raise(int argc, VALUE *argv, VALUE self);

static ID id___process_exception_from_raise__ = 0;
static VALUE mKernel = 0;

// ===========================================================
//  MAIN ENTRY POINT
// ===========================================================

void Init_mulligan(void)
{
  VALUE mMulligan = rb_define_module("Mulligan");
  mKernel = rb_define_module_under(mMulligan, "Kernel");
  rb_define_method(mKernel, "mg_raise", rb_mg_raise, -1);
  rb_define_method(mKernel, "mg_fail", rb_mg_raise, -1);

  id___process_exception_from_raise__ = rb_intern("__process_exception_from_raise__");
}


/* -----------------------------------------------------------
//  Here is the template ruby code that we are approximating
//  in C. Native-only calls are surround by <<>>
// -----------------------------------------------------------
def raise(*args)
  e = <<make_exception(*args)>>
  Mulligan::Kernel.send(:__process_exception_from_raise__, e)
  <<rb_exc_raise(e)>>
end
// -----------------------------------------------------------
// We only call `rb_exc_raise` from the current frame. This is
// important because we want the stack-trace and current
// stack-frame to be identical to what they were if we just
// called the standard #raise method. If we call
// `rb_exc_raise` within a block or call super, we will lose
// that stack-frame context.
// -----------------------------------------------------------*/


static VALUE
rb_mg_raise(int argc, VALUE *argv, VALUE self)
{
    // -----------------------------------------------------------
    //  Get a reference to the Exception object
    // -----------------------------------------------------------
    VALUE e = rb_make_exception(argc, argv);

    if (NIL_P(e)) {
      // get whatever is in $!. I'm sure this is slow
      e = rb_eval_string("$!");
      // what I'd like to use really like to use
//       e = rb_rubylevel_errinfo(); // internal ruby call, yet necessary
    }

    if (NIL_P(e)) {
      e = rb_exc_new(rb_eRuntimeError, 0, 0);
    }

    // -----------------------------------------------------------
    //  With the Exception in place, add the recoveries
    // -----------------------------------------------------------
    rb_funcall(mKernel, id___process_exception_from_raise__, 1, e);

    // -----------------------------------------------------------
    //  raise the exception
    // -----------------------------------------------------------
    rb_exc_raise(e);

//     UNREACHABLE;
}

