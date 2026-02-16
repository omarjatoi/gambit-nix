(define-library (my-library)
  (export hello-library)
  (import (scheme base))
  (begin
    (define (hello-library name)
      (string-append "Hello " name " from my-library!"))))
