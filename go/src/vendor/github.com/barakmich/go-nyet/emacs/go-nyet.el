;;; go-nyet.el --- Add go-nyet to flycheck

(require 'flycheck)

(flycheck-define-checker go-nyet
  "A Go syntax checker using the `go-nyet` command.

  See URL `https://github.com/barakmich/go-nyet'."
  :command ("go-nyet" source)
  :error-patterns
  ((warning line-start (file-name) ":" line ":" column ":" (message) line-end))
  :modes go-mode)
(add-to-list 'flycheck-checkers 'go-nyet 'append)
; The default go next-checker chain is complicated; the simplest place to
; plug in is after go-build and go-test (one of which is always run),
; but before go-errcheck (which is last when it exists but is not always there).
(flycheck-add-next-checker 'go-build '(warning . go-nyet))
(flycheck-add-next-checker 'go-test '(warning . go-nyet))
(flycheck-add-next-checker 'go-nyet '(warning . go-errcheck))

(provide 'go-nyet)
;;; go-nyet.el ends here
