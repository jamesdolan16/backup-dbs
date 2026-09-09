(require :asdf)

(asdf:load-asd
 (merge-pathnames "backup-dbs.asd"
                  *load-truename*))

(asdf:load-system :backup-dbs)

(sb-ext:save-lisp-and-die
 "backup-dbs"
 :toplevel #'backup-dbs:main
 :executable t)
