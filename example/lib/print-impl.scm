(define (hello-message name)
  (string-append "Hello, " name "!"))

(define (fancy-hello name)
  (let ((msg (hello-message name)))
    (string-append "*** " msg " ***")))
