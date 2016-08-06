;;; company-mysql.el --- Provides term completion for company based on your MySQL DB

;; Copyright (C) 2016 Adrien Brochard

;; Author: Adrien Brochard
;; URL: https://github.com/abrochard/company-mysql
;; Created: August 5th 2016
;; Version: 0.1.0
;; Keywords: sql, company, mysql, completion

;;; License:

;; This file is not part of GNU Emacs

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

;; Provide your credentials and databases names
;;
;; (setq company-mysql-host "localhost")
;; (setq company-mysql-user "user")
;; (setq company-mysql-password "password")
;; (setq company-mysql-db (list "db1" "db2" "db3"))

;; Plug into company as a backend
;;
;; (add-hook 'sql-mode-hook
;;           '(lambda ()
;;              (company-mode t)
;;              (add-to-list 'company-backends 'company-mysql-backend)))

;;; Requirements:

;; Requires sed and mysql installed on your local machine




;;; Code:

(defconst company-mysql-version "0.1.0" "company mysql version.")

(defgroup company-mysql nil
  "Company backend for MySQL based on your table schemas"
  :group 'extensions
  :group 'tools
  :link '(url-link :tag "Repository" "https://github.com/abrochard/company-mysql"))

(require 'sql)
(require 'company)
(require 'cl-lib)

(setq mysql-symbol-hash nil)
(setq company-mysql-host "localhost")
(setq company-mysql-user "user")
(setq company-mysql-password "password")
(setq company-mysql-db (list "db1" "db2"))

(setq mysql-keywords '("ascii" "avg" "bdmpolyfromtext" "bdmpolyfromwkb" "bdpolyfromtext"
                       "bdpolyfromwkb" "benchmark" "bin" "bit_and" "bit_length" "bit_or"
                       "bit_xor" "both" "cast" "char_length" "character_length" "coalesce"
                       "concat" "concat_ws" "connection_id" "conv" "convert" "count"
                       "curdate" "current_date" "current_time" "current_timestamp" "curtime"
                       "elt" "encrypt" "export_set" "field" "find_in_set" "found_rows" "from"
                       "geomcollfromtext" "geomcollfromwkb" "geometrycollectionfromtext"
                       "geometrycollectionfromwkb" "geometryfromtext" "geometryfromwkb"
                       "geomfromtext" "geomfromwkb" "get_lock" "group_concat" "hex" "ifnull"
                       "instr" "interval" "isnull" "last_insert_id" "lcase" "leading"
                       "length" "linefromtext" "linefromwkb" "linestringfromtext"
                       "linestringfromwkb" "load_file" "locate" "lower" "lpad" "ltrim"
                       "make_set" "master_pos_wait" "max" "mid" "min" "mlinefromtext"
                       "mlinefromwkb" "mpointfromtext" "mpointfromwkb" "mpolyfromtext"
                       "mpolyfromwkb" "multilinestringfromtext" "multilinestringfromwkb"
                       "multipointfromtext" "multipointfromwkb" "multipolygonfromtext"
                       "multipolygonfromwkb" "now" "nullif" "oct" "octet_length" "ord"
                       "pointfromtext" "pointfromwkb" "polyfromtext" "polyfromwkb"
                       "polygonfromtext" "polygonfromwkb" "position" "quote" "rand"
                       "release_lock" "repeat" "replace" "reverse" "rpad" "rtrim" "soundex"
                       "space" "std" "stddev" "substring" "substring_index" "sum" "sysdate"
                       "trailing" "trim" "ucase" "unix_timestamp" "upper" "user" "variance"
                       "action" "add" "after" "against" "all" "alter" "and" "as" "asc"
                       "auto_increment" "avg_row_length" "bdb" "between" "by" "cascade"
                       "case" "change" "character" "check" "checksum" "close" "collate"
                       "collation" "column" "columns" "comment" "committed" "concurrent"
                       "constraint" "create" "cross" "data" "database" "default"
                       "delay_key_write" "delayed" "delete" "desc" "directory" "disable"
                       "distinct" "distinctrow" "do" "drop" "dumpfile" "duplicate" "else"
                       "enable" "enclosed" "end" "escaped" "exists" "fields" "first" "for"
                       "force" "foreign" "from" "full" "fulltext" "global" "group" "handler"
                       "having" "heap" "high_priority" "if" "ignore" "in" "index" "infile"
                       "inner" "insert" "insert_method" "into" "is" "isam" "isolation" "join"
                       "key" "keys" "last" "left" "level" "like" "limit" "lines" "load"
                       "local" "lock" "low_priority" "match" "max_rows" "merge" "min_rows"
                       "mode" "modify" "mrg_myisam" "myisam" "natural" "next" "no" "not"
                       "null" "offset" "oj" "on" "open" "optionally" "or" "order" "outer"
                       "outfile" "pack_keys" "partial" "password" "prev" "primary"
                       "procedure" "quick" "raid0" "raid_type" "read" "references" "rename"
                       "repeatable" "restrict" "right" "rollback" "rollup" "row_format"
                       "savepoint" "select" "separator" "serializable" "session" "set"
                       "share" "show" "sql_big_result" "sql_buffer_result" "sql_cache"
                       "sql_calc_found_rows" "sql_no_cache" "sql_small_result" "starting"
                       "straight_join" "striped" "table" "tables" "temporary" "terminated"
                       "then" "to" "transaction" "truncate" "type" "uncommitted" "union"
                       "unique" "unlock" "update" "use" "using" "values" "when" "where"
                       "with" "write" "xor" "bigint" "binary" "bit" "blob" "bool" "boolean"
                       "char" "curve" "date" "datetime" "dec" "decimal" "double" "enum"
                       "fixed" "float" "geometry" "geometrycollection" "int" "integer"
                       "longblob" "longtext" "mediumblob" "mediumint" "mediumtext"
                       "multicurve" "multilinestring" "multipoint" "multipolygon"
                       "multisurface" "national" "numeric" "point" "polygon" "precision"
                       "real" "smallint" "surface" "text" "time" "timestamp" "tinyblob"
                       "tinyint" "tinytext" "unsigned" "varchar" "year" "year2" "year4"
                       "line" "linearring" "linestring" "zerofill"
                       ))

(defun hash-mysql-keywords ()
  "Goes through the keywords and puts them in the hash"
  (dolist (keyword mysql-keywords)
    (puthash keyword t mysql-symbol-hash)))

(defun hash-mysql-tables (db)
  "Dumps the schema of the db and parses it into a hash"
  (with-temp-buffer
    (call-process-shell-command (concat "mysqldump -h " company-mysql-host " -u " company-mysql-user  " -p" company-mysql-password " --no-data " db " | sed -n 's/[CREATE TABLE] `.*`/&/p'") nil t)
    (goto-char (point-min))
    (while (re-search-forward "`[0-9a-zA-Z$_]*`" (point-max) t)
      (puthash (substring (match-string 0) 1 -1) t mysql-symbol-hash))))

(defun company-mysql-backend (command &optional arg &rest ignored)
  "Man function that plugs as a backend for company"
  (case command
    (prefix (and (eq major-mode 'sql-mode)
                 (company-grab-symbol)))
    (sorted t)
    (candidates (all-completions
                 arg
                 (if (and (boundp 'mysql-symbol-hash)
                          mysql-symbol-hash)
                     mysql-symbol-hash
                   (progn
                     (setq mysql-symbol-hash (make-hash-table :test 'equal))
                     (hash-mysql-keywords)
                     (dotimes (i (length company-mysql-db))
                       (hash-mysql-tables (nth i company-mysql-db)))))))))



(provide 'company-mysql)
;;; company-mysql.el ends here
