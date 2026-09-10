(in-package :backup-dbs)

(defun make-this-backup-dir (this-backup-path)
  (format t "-> Creating backup location ~A" this-backup-path)
  (ensure-directories-exist this-backup-path))

(defun dump-dbs (config)
  (format t "-> Dumping DBs")
  (backup-databases config (list-databases config)))

(defun backup-databases (config this-backup-path databases)
  (dolist (db databases)
    (backup-database config this-backup-path db)))

(defun current-date-string ()
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (get-universal-time))
    (declare (ignore second minute hour))
    (format nil "~4,'0D-~2,'0D-~2,'0D"
            year month day)))

(defun current-time-string ()
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (get-universal-time))
    (declare (ignore day month year))
    (format nil "~2,'0D:~2,'0D:~2,'0D"
            hour minute second)))
