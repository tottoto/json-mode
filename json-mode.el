;;; json-mode.el --- A major mode for editing JSON source code

;; Copyright (C) 2020 tottoto

;; Author: tottoto <tottotodev@gmail.com>
;; Maintainer: tottoto <tottotodev@gmail.com>
;; Keywords: lisp html
;; Homepage: https://github.com/tottoto/json-mode

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'smie)

(defgroup json-mode nil
  "Support for JSON code"
  :link '(url-link "https://github.com/tottoto/json-mode")
  :group 'languages)

(defcustom json-indent-offset 4
  "Indent JSON code by this number of spaces."
  :type 'integer
  :safe 'integerp)

(defvar json-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?\: "." table)
    (modify-syntax-entry ?\, "." table)
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\r ">" table)
    (modify-syntax-entry ?\n ">" table)
    table))

(defconst json-singleton-keywords
  '("true" "false" "null"))

(defconst json-singleton-re
  (regexp-opt json-singleton-keywords))

(defconst json-delimiter-keywords
  '("{" "}" "[" "]" ":" ","))

(defconst json-delimiter-re
  (regexp-opt json-delimiter-keywords))

(defvar json-font-lock-keywords
  `((,json-singleton-re . font-lock-constant-face)))

(defconst json-smie-token-re
  (mapconcat 'identity
             (list json-singleton-re
                   json-delimiter-re)
             "\\|"))

(defconst json-smie-grammar
  (smie-prec2->grammar
   (smie-bnf->prec2
    '((string)
      (number)
      (boolean ("true") ("false"))
      (null ("null"))
      (object ("{" pairs "}"))
      (array ("[" values "]"))
      (values (values "," values)
              (value))
      (pairs (pairs "," pairs)
             (pair))
      (pair (string ":" value))
      (value (object)
             (array)
             (string)
             (number)
             (boolean)
             (null)))
    '((assoc ":"))
    '((assoc ",")))))

(defun json-smie-forward-token ()
  (forward-comment (point-max))
  (skip-syntax-forward "-")
  (cond
   ((looking-at json-smie-token-re)
    (goto-char (match-end 0))
    (match-string-no-properties 0))
   (t
    (buffer-substring-no-properties
     (point)
     (progn (skip-syntax-forward "w_\"")
            (point))))))

(defun json-smie-backward-token ()
  (forward-comment (- (point)))
  (skip-syntax-backward "-")
  (cond
   ((looking-back json-smie-token-re (- (point) 2) t)
    (goto-char (match-beginning 0))
    (match-string-no-properties 0))
   (t
    (buffer-substring-no-properties
     (point)
     (progn (skip-syntax-backward "w_\"")
            (point))))))

(defun json-smie-rules (kind token))

(define-derived-mode json-mode prog-mode "JSON"
  "A major mode for editing JSON source code."
  (set-syntax-table json-mode-syntax-table)
  (setq-local font-lock-defaults '(json-font-lock-keywords nil nil))
  (setq-local comment-start "# ")
  (setq-local smie-indent-basic json-indent-offset)
  (smie-setup json-smie-grammar 'json-smie-rules
              :forward-token 'json-smie-forward-token
              :backward-token 'json-smie-backward-token))

(provide 'json-mode)
;;; json-mode.el ends here
