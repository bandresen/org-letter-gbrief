;; load this file with `load'

;; letter export
(setq org-export-kill-product-buffer-when-displayed t)
(add-to-list 'org-export-latex-classes
             '("brief"
               "\\documentclass[11pt,ngerman]{g-brief2}
                [DEFAULT-PACKAGES]
                [NO-PACKAGES]
                [EXTRA]"
               ("%%" . "%%")
               ("\\begin{g-brief}" . "\\end{g-brief}")))

(defun org-letter-option-get (option)
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (let (results)
        (while (re-search-forward (concat "^#\\+" option ":[ \t]*\\(.*?\\)[ \t]*$") nil t)
          (add-to-list 'results (concat (org-match-string-no-properties 1 nil))))
        results))))


(setq org-letter-options-format-alist '(("Anrede" . "{%s}")
                                        ("Unterschrift" . "{%s}")
                                        ("Gruss" . "{%s}{1cm}")
                                        ("Betreff" . "{%s}")
                                        ("Datum" . "{%s}")
                                        ("Adresse" . "{%s}")
                                        ("IhrZeichen" . "{%s}")
                                        ("IhrSchreiben" . "{%s}")
                                        ("MeinZeichen" . "{%s}")))

(defun org-letter-buffer-brief-p ()
  (string= "brief" (plist-get (org-infile-export-plist) :latex-class)))

(defun org-letter-add-options-to-latex-headers ()
  (when (org-letter-buffer-brief-p)
    (let* ((current-headers (plist-get org-export-latex-options-plist
                                       :latex-header-extra))
           (new-headers (mapconcat '(lambda (x)
                                     (when (org-letter-option-get (car x))
                                       (let ((lst (org-letter-option-get (car x))))
                                         (concat "\n" "\\" (car x) " "
                                                 (format (cdr x)
                                                         (if (> (length lst) 1)
                                                             (mapconcat 'identity (reverse lst) "\\\\")
                                                             (car lst)))))))
                                   org-letter-options-format-alist "")))
      (plist-put org-export-latex-options-plist
                 :latex-header-extra (concat current-headers new-headers)))))

(add-hook 'org-export-latex-after-initial-vars-hook 'org-letter-add-options-to-latex-headers)

(defun org-letter-add-gbrief-end-section ()
  (let ((gbrief-p (string-match "\\\\documentclass\\(\\[[^][]*?\\]\\)?{g-brief2}"
                                org-export-latex-header)))
    (when gbrief-p
      (goto-char (point-max))
      (forward-line -1)
      (insert "\\end{g-brief}"))))

(add-hook 'org-export-latex-final-hook 'org-letter-add-gbrief-end-section)

; hack because `org-export-latex-title-command' is not allowed to be set via file local variables (**)
(add-hook 'org-export-first-hook '(lambda ()
                                   (when (org-letter-buffer-brief-p)
                                     (set (make-local-variable 'org-export-latex-title-command) ""))))