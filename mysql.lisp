(in-package :backup-dbs)

(defun dump-users-and-grants (config this-backup-path)
  (format t "-> Dumping Users and Grants")
  (let* ((user (getf config :mysql-user))
         (login-path (getf config :mysql-login-path))
         (users-and-grants-path (format nil "~A/usersandgrants.sql" this-backup-path)))

    (with-open-file (stream users-and-grants-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (with-command ("mysqlpump"
                     "--exclude-databases=%"
                     "--users"
                     "--add-drop-user"
                     (format nil "--exclude-users='root,mysql.infoschema,mysql.session,mysql.sys,~A'" user)
                     "--skip-watch-progress"
                     (format nil "--login-path=~A" login-path))
        (write out :stream stream)))))

(defun backup-database (config db)
  (format t "  -> Backing up ~A..." db)
  (let* ((date (current-date-string))
         (backup-dir-path (getf config :backup-dir))
         (this-backup-path (format nil "~A/~A" backup-dir-path date))
         (login-path (getf config :mysql-login-path))
         (output-path (format nil "~A/~A.sql.gz" this-backup-path db))
         (command (format nil "mysqldump \
--login-path=~A \
--single-transaction \
--routines \
--events \
--triggers \
~A | pigz > ~A"
                          login-path
                          db
                          output-path)))
    (with-command ("/bin/bash"
                   "-o" "pipefail"
                   "-c" command)
      (format t "Successfully backed up ~A" db)
      :on-error (format t "Error whilst backing up ~A: ~A" db err))))

(defun list-databases (config)
  (let* ((login-path (getf config :mysql-login-path))
         (excluded (getf config :excluded-databases))
         (output
           (with-command ("mysql"
                          (format nil "--login-path=~A" login-path)
                          "-N"
                          "-e"
                          "SHOW DATABASES;")
             out)))
    (remove-if
     (lambda (db)
       (member db excluded :test #'string=))
     (remove ""
             (uiop:split-string output :separator '(#\Newline))
             :test #'string=))))

(defun create-login-path (config)
  (let ((user (getf config :mysql-user))
        (login-path (getf config :mysql-login-path)))
    (format t "Creating MySQL login path ~A for ~A.~%"
            login-path user)

    (uiop:run-program
     (list "mysql_config_editor"
           "set"
           (format nil "--login-path=~A" login-path)
           "--host=localhost"
           (format nil "--user=~A" user)
           "--password")
     :input :interactive
     :output :interactive
     :error-output :interactive)))

(defun remove-bad-login-path (login-path)
  (multiple-value-bind (out err code)
      (uiop:run-program
       (list "mysql_config_editor"
             "remove"
             (format nil "--login-path=~A" login-path))
       :output :string
       :error-output :string
       :ignore-error-status t)
    (declare (ignore out err))
    (zerop code)))


(defun mysql-login-valid-p (login-path)
  (multiple-value-bind (out err code)
      (uiop:run-program
       (list "mysql"
             (format nil "--login-path=~A" login-path)
             "-N"
             "-e"
             "SELECT 1;")
       :output :string
       :error-output :string
       :ignore-error-status t)
    (declare (ignore out err))
    (zerop code)))

(defun mysql-login-path-exists-p (login-path)
  (with-command ("mysql_config_editor"
                 "print"
                 (format nil "--login-path=~A" login-path))
    (not (null
          (search (format nil "[~A]" login-path)
                  out)))))
