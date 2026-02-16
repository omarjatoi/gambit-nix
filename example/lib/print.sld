(define-library (print)
  (export hello-message fancy-hello)
  (import (scheme base))
  (include "print-impl.scm"))
