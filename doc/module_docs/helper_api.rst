.. _sec_helper_api:

Multi-UART Helper API
======================

This API provides a number of functions that allow the access of architecture specific functionality within C where XC semantics are not available.

.. doxygenfunction:: get_time

.. doxygenfunction:: wait_for

.. doxygenfunction:: wait_until

.. doxygenfunction:: send_streaming_int

.. doxygenfunction:: get_streaming_uint

.. doxygenfunction:: get_streaming_token
