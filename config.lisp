(in-package :backup-dbs)

(defparameter *config-path* #p"~/.backup-dbs/config.lisp")

(defun default-config ()
  '(:backup-dir "/var/backups/mysql"
    :mysql-user "nightly-backup"
    :mysql-login-path "nightly-backup"
    :excluded-databases
    ("information_schema"
     "performance_schema"
     "mysql"
     "sys")))

(defun read-config (pathname)
  (with-open-file (stream
                   pathname
                   :if-does-not-exist nil)
    (when stream
      (let ((*read-eval* nil))
        (read stream nil nil)))))

(defun write-config (path config)
  (ensure-directories-exist path)

  (with-open-file (stream path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (write config
           :stream stream
           :pretty t)
    (terpri stream))

  config)

(defun ensure-config ()
  (format t "Checking for config")
  (or (read-config *config-path*)
      (progn
        (format t "No config file found at ~A, creating default config and using that" *config-path*)
        (write-config *config-path*
                     (default-config)))))

(defun ensure-dependencies ()
  (format t "Checking for dependencies")
  (let ((deps (list "mysql_config_editor" "mysqlpump" "mysqldump" "pigz"))
        (missing (list)))
    (dolist (dep deps)
      (unless (command-exists-p dep)
        (push dep missing)))
    (when (> (length missing) 0)
      (error "ERROR: Missing the following bash utilities: ~{~A~^, ~}" missing))))

(defun ensure-login (config)
  (let ((login-path (getf config :mysql-login-path)))
    (loop
      (unless (mysql-login-path-exists-p login-path)
        (create-login-path config))

      (when (mysql-login-valid-p login-path)
        (return t))

      (format t "MySQL login path ~A is missing or invalid; please re-enter the password.~%"
              login-path)

      (remove-bad-login-path login-path))))

(defun command-exists-p (command)
  (multiple-value-bind (out err code)
      (uiop:run-program (list "which" command)
                        :output :string
                        :error-output :string
                        :ignore-error-status t)
    (declare (ignore out err))
    (zerop code)))
