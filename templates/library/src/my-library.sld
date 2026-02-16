(define-library (my-library)
  (export hello-library add-numbers)
  (import (scheme base))
  (begin
    (define (hello-library name)
      (string-append "Hello " name " from my-library!"))

    (define (add-numbers a b)
      (+ a b))))
