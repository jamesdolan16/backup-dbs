(in-package :backup-dbs)

(defun main ()
  "CLI entry-point"
  (handler-case
      (let ((args (uiop:command-line-arguments)))
        (cond
          ((equal args '("setup"))
           (setup (ensure-config)))
          ((equal args '("run"))
           (run (ensure-config)))
          (t
           (error "Unknown arguments '~A', options are 'setup', 'run'" args)))
        (uiop:quit 0))
    (error (e)
      (format *error-output* "ERROR: ~A~%" e)
      (uiop:quit 1))))

(defun setup (config)
  (ensure-dependencies)
  (ensure-login config))

(defun run (config)
  (let* ((current-date (current-date-string))
         (backup-dir-path (getf config :backup-dir))
         (this-backup-path (format nil "~A/~A" backup-dir-path current-date)))
    (make-this-backup-dir this-backup-path)
    (format t "-> Backup started at ~A" (current-time-string))
    (backup-databases config (list-databases config))
    (format t "-> Backup completed at ~A, stored files at ~A"
            (current-time-string)
            this-backup-path)))
