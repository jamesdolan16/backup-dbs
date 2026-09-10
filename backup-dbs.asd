(asdf:defsystem "backup-dbs"
  :description "Backup tool for Magn8 production databases"
  :author "James Dolan"
  :serial t
  :components
  ((:file "package")
   (:file "config")
   (:file "mysql")
   (:file "backup")
   (:file "main")))
