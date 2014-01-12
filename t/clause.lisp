(in-package :cl-user)
(defpackage t.sxql.clause
  (:use :cl
        :cl-test-more
        :sxql.sql-type
        :sxql.operator
        :sxql.clause
        :sxql.compile)
  (:shadowing-import-from :t.sxql.prepare
                          :is-error))
(in-package :t.sxql.clause)

(plan 47)

(ok (make-clause :where (make-op := :a 10)))
(is (multiple-value-list
     (yield (make-clause :where (make-op := :a 10))))
    (list "WHERE (`a` = ?)" '(10)))
(is-error (make-clause :where
                       (make-op := :a 10)
                       (make-op :!= :b 20))
          program-error)

(ok (make-clause :from (make-sql-symbol "table-name")))
(ok (make-clause :from (make-op :as :table-name :a)))
(is (multiple-value-list
     (yield (make-clause :from (make-sql-symbol "table-name"))))
    (list "FROM `table-name`" nil))
(is (multiple-value-list
     (yield (make-clause :from
                         (make-op :as :table-name :a))))
    (list "FROM `table-name` AS `a`" nil))

(ok (make-clause :order-by (make-sql-symbol "a")))
(is (multiple-value-list
     (yield
      (make-clause :order-by (make-sql-symbol "a"))))
    (list "ORDER BY `a`" nil)
    "ORDER BY")
(is (multiple-value-list
     (yield
      (make-clause :order-by
                   (make-sql-list
                    (make-sql-symbol "a")
                    (make-sql-symbol "b")))))
    (list "ORDER BY (`a`, `b`)" nil))
(is (multiple-value-list
     (yield
      (make-clause :order-by
                   (make-sql-list
                    (make-op :desc (make-sql-symbol "a"))
                    (make-sql-symbol "b")))))
    (list "ORDER BY (`a` DESC, `b`)" nil))

(ok (make-clause :group-by (make-sql-symbol "a")))
(ok (make-clause :group-by
                 (make-sql-list
                  (make-sql-symbol "a")
                  (make-sql-symbol "b"))))
(ok (make-clause :group-by (make-op :+
                                    (make-sql-symbol "a")
                                    (make-sql-variable 1))))
(is (multiple-value-list
     (yield
      (make-clause :group-by (make-sql-symbol "a"))))
    (list "GROUP BY `a`" nil))
(is (multiple-value-list
     (yield
      (make-clause :group-by
                   (make-sql-list
                    (make-sql-symbol "a")
                    (make-sql-symbol "b")))))
    (list "GROUP BY (`a`, `b`)" nil))
(is (multiple-value-list
     (yield
      (make-clause :group-by
                   (make-op :+ (make-sql-symbol "a") (make-sql-variable 1)))))
    (list "GROUP BY (`a` + ?)" '(1)))

(ok (make-clause :limit (make-sql-variable 1)) "LIMIT")
(ok (make-clause :limit (make-sql-variable 0) (make-sql-variable 10)))
(is (multiple-value-list
     (yield
      (make-clause :limit (make-sql-variable 1))))
    (list "LIMIT 1" nil))
(is (multiple-value-list
     (yield
      (make-clause :limit
                   (make-sql-variable 0)
                   (make-sql-variable 10))))
    (list "LIMIT 0, 10" nil))
(is-error (make-clause :limit (make-sql-symbol "a")) type-error)
(is-error (make-clause :limit
                       (make-sql-variable 1)
                       (make-sql-variable 2)
                       (make-sql-variable 2))
          program-error)

(ok (make-clause :offset (make-sql-variable 1)))
(is (multiple-value-list
     (yield
      (make-clause :offset (make-sql-variable 1000))))
    (list "OFFSET 1000" nil))
(is-error (make-clause :offset
                       (make-sql-variable 1)
                       (make-sql-variable 2))
          program-error)

(ok (make-clause :set= :a 1) "set=")
(ok (make-clause :set= :a 1 :b 2))
(is (multiple-value-list
     (yield (make-clause :set= :a 1 :b 2)))
    (list "SET `a` = ?, `b` = ?" '(1 2)))
;(is-error (make-clause :set=) program-error)
;(is-error (make-clause :set= 'a 1 'b) program-error)
;(is-error (make-clause :set= '(a 1)) program-error)

(is (multiple-value-list
     (yield (make-clause :primary-key '(:id))))
    (list "PRIMARY KEY (`id`)" nil))
(is (multiple-value-list
     (yield (make-clause :primary-key :id)))
    (list "PRIMARY KEY (`id`)" nil))
(is (multiple-value-list
     (yield (make-clause :primary-key "primary_key_is_id"'(:id))))
    (list "PRIMARY KEY 'primary_key_is_id' (`id`)" nil))
(is (multiple-value-list
     (yield (make-clause :unique-key '(:name :country))))
    (list "UNIQUE KEY (`name`, `country`)" nil))
(is (multiple-value-list
     (yield (make-clause :unique-key "name_and_country_index" '(:name :country))))
    (list "UNIQUE KEY 'name_and_country_index' (`name`, `country`)" nil))
(is (multiple-value-list
     (yield (make-clause :key '(:id))))
    (list "KEY (`id`)" nil))
(is (multiple-value-list
     (yield (make-clause :key "id_is_unique" '(:id))))
    (list "KEY 'id_is_unique' (`id`)" nil))

(ok (sxql.clause::make-references-clause
     (sxql.sql-type:make-sql-symbol "project")
     (sxql.sql-type:make-sql-list (sxql.sql-type:make-sql-symbol "id"))))

(is (multiple-value-list
     (yield (make-clause :foreign-key '(:project_id) :references '(:project :id))))
    (list "FOREIGN KEY (`project_id`) REFERENCES `project` (`id`)" nil))

(is (multiple-value-list
     (yield (make-clause :add-column :updated_at
                         :type 'integer
                         :default 0
                         :not-null t
                         :after :created_at)))
    (list "ADD COLUMN `updated_at` INTEGER NOT NULL DEFAULT ? AFTER `created_at`"
          '(0)))

(is (multiple-value-list
     (yield (make-clause :modify-column
                         :updated_at
                         :type 'datetime
                         :not-null t)))
    (list "MODIFY COLUMN `updated_at` DATETIME NOT NULL" nil))

(is (multiple-value-list
     (yield (make-clause :change-column
                         :updated_at :updated_on)))
    (list "CHANGE COLUMN `updated_at` `updated_on`" nil))

(is (multiple-value-list
     (yield (make-clause :drop-column
                         :updated_on)))
    (list "DROP COLUMN `updated_on`" nil))

(is (multiple-value-list
     (yield
      (sxql.clause::make-column-definition-clause
       (make-sql-symbol "name")
       :type (make-op :char (make-sql-variable 64))
       :not-null t
       :default (make-sql-variable "No Name"))))
    '("`name` CHAR(64) NOT NULL DEFAULT ?" ("No Name"))
    "column-definition")

(is (multiple-value-list
     (yield
      (sxql.clause::make-column-definition-clause
       (make-sql-symbol "id")
       :type (make-sql-keyword "bigint")
       :primary-key t
       :auto-increment t)))
    '("`id` BIGINT AUTO_INCREMENT PRIMARY KEY" nil)
    "column-definition")

(is (multiple-value-list
     (yield
      (sxql.clause::make-column-definition-clause
       (make-sql-symbol "email")
       :type (make-sql-keyword "text")
       :not-null t
       :unique t)))
    '("`email` TEXT NOT NULL UNIQUE" nil)
    "column-definition")

(diag "sql-compile clause")

(ok (sql-compile (make-clause :limit 10)))

(is (multiple-value-list
     (yield (sql-compile (make-clause :limit 10))))
    '("LIMIT 10" ()))

(finalize)
