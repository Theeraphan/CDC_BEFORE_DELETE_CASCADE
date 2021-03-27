
--Drop test table
DROP TABLE IF EXISTS pet; --Granchild
DROP TABLE IF EXISTS children; --Child
DROP TABLE IF EXISTS parents; --Parent

--Create table
CREATE TABLE parents (
    parent_id INTEGER NOT NULL PRIMARY KEY,
  	p_name VARCHAR(100) NULL
);

CREATE TABLE children (
    child_id INTEGER NOT NULL PRIMARY KEY,
  	ck_name VARCHAR(100) NULL,
    parent_id INTEGER NOT NULL REFERENCES parents(parent_id)
	ON DELETE CASCADE --ref by parent_id
);

CREATE TABLE pet (
    pet_id INTEGER NOT NULL PRIMARY KEY,
  	pe_name VARCHAR(100) NULL,
    child_id INTEGER NOT NULL REFERENCES children(child_id)
	ON DELETE CASCADE --ref by child_id
);


--delete record counter table
DROP TABLE IF EXISTS results;
CREATE TABLE results (
    result_id SERIAL PRIMARY KEY,
    table_name VARCHAR(10) NOT NULL,
    trigger_when VARCHAR(10) NOT NULL,
    deleted_parent_id INTEGER NOT NULL,
    deleted_children_count INTEGER NOT NULL
);


--Function to return 

--CREATE OR REPLACE FUNCTION trigen(tbl text) RETURNS void AS $T1$
--BEGIN
--    EXECUTE format(
--'
      CREATE OR REPLACE FUNCTION children_parent_id() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO results (table_name, trigger_when, deleted_parent_id, deleted_children_count)
    VALUES
    ('Parents',TG_WHEN,(SELECT parent_id FROM parents WHERE parent_id = OLD.parent_id),(SELECT COUNT(*) FROM parents WHERE parent_id = OLD.parent_id))
   ,('Children',TG_WHEN,(SELECT parent_id FROM parents WHERE parent_id = OLD.parent_id),(SELECT COUNT(*) FROM children WHERE parent_id = OLD.parent_id))
   ,('Pet',TG_WHEN,(SELECT DISTINCT pa.parent_id 
                    FROM children c
                    JOIN parents pa
       				ON c.parent_id = pa.parent_id
       				WHERE pa.parent_id = OLD.parent_id)
                    --WHERE parent_id = (SELECT DISTINCT parent_id FROM parents WHERE parent_id = OLD.parent_id))
     ,(SELECT COUNT(pet_id) 
       FROM pet pe
       JOIN children c
       ON pe.child_id = c.child_id
       JOIN parents pa
       ON c.parent_id = pa.parent_id
       WHERE pa.parent_id = OLD.parent_id)
       --parent_id = (SELECT DISTINCT parent_id FROM parents WHERE parent_id = OLD.parent_id)
    )
    ;
    RETURN OLD;
    
END; $$ LANGUAGE plpgsql;--', tbl, quote_nullable(tbl));

--trigger BEFORE DELETE procedure for each child table
CREATE TRIGGER tr_parents_bd_children_parent_id
BEFORE DELETE ON parents
FOR EACH ROW EXECUTE PROCEDURE children_parent_id();

--Insert test data
INSERT INTO parents (parent_id) VALUES (1);
INSERT INTO parents (parent_id) VALUES (2);
INSERT INTO parents (parent_id) VALUES (3);
INSERT INTO parents (parent_id,p_name) VALUES (4,'Luka');
INSERT INTO parents (parent_id,p_name) VALUES (5,'Andre');

INSERT INTO children (child_id, parent_id) VALUES (101, 1);
INSERT INTO children (child_id, parent_id) VALUES (102, 1);
INSERT INTO children (child_id, parent_id) VALUES (103, 2);
INSERT INTO children (child_id, parent_id) VALUES (104, 2);
INSERT INTO children (child_id, parent_id) VALUES (105, 2);
INSERT INTO children (child_id, parent_id) VALUES (106, 3);
--INSERT INTO children (child_id, parent_id) VALUES (1066, 3);
INSERT INTO children (child_id, parent_id, ck_name) VALUES (107, 4,'A');
INSERT INTO children (child_id, parent_id, ck_name) VALUES (108, 4,'B');

INSERT INTO pet (pet_id, child_id) VALUES (1193, 101);
INSERT INTO pet (pet_id, child_id) VALUES (2098, 101);
INSERT INTO pet (pet_id, child_id) VALUES (2099, 101);
INSERT INTO pet (pet_id, child_id) VALUES (2498, 102);
INSERT INTO pet (pet_id, child_id) VALUES (2497, 102);
INSERT INTO pet (pet_id, child_id) VALUES (2096, 103);
INSERT INTO pet (pet_id, child_id) VALUES (2195, 104);
INSERT INTO pet (pet_id, child_id) VALUES (2298, 105);
INSERT INTO pet (pet_id, child_id) VALUES (2201, 106);
--INSERT INTO pet (pet_id, child_id) VALUES (2211, 106);
INSERT INTO pet (pet_id,pe_name, child_id) VALUES (5581,'July', 107);
INSERT INTO pet (pet_id,pe_name, child_id) VALUES (5582,'June', 107);
INSERT INTO pet (pet_id,pe_name, child_id) VALUES (3081,'May', 108);


--delete to trigger
DELETE FROM parents WHERE parent_id < 4;


--deleted record by parent_id
--SELECT *
--FROM results
--WHERE deleted_children_count > 0;

--deleted record by table
SELECT table_name,SUM(deleted_children_count) AS deleted_count 
FROM results 
GROUP BY table_name 
--HAVING SUM(deleted_children_count) > 0
ORDER BY table_name;
--
--remain record
SELECT parent_id AS id,p_name AS _name_ FROM parents
UNION ALL
SELECT child_id,ck_name FROM children
UNION ALL
SELECT pet_id,pe_name FROM pet