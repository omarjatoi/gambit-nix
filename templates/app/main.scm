;; Simple Gambit Scheme application
(declare (extended-bindings) (not constant-fold) (not safe))

(define (main)
  (println "Hello from Gambit Scheme!")
  (println "Built with Nix flakes"))

;; Entry point
(main)