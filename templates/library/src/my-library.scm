;; Gambit Scheme library template
(declare (extended-bindings) (not constant-fold) (not safe))

;; Export public functions
(declare (export hello-library add-numbers))

(define (hello-library name)
  "Return a greeting message"
  (string-append "Hello " name " from my-library!"))

(define (add-numbers a b)
  "Add two numbers together"
  (+ a b))