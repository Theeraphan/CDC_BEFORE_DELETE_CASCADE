DROP TABLE IF EXISTS pet;
DROP TABLE IF EXISTS children;
DROP TABLE IF EXISTS parents;
CREATE TABLE parents (
    parent_id INTEGER NOT NULL PRIMARY KEY
);

CREATE TABLE children (
    child_id INTEGER NOT NULL PRIMARY KEY,
    parent_id INTEGER NOT NULL REFERENCES parents(parent_id)
	ON DELETE CASCADE
);

CREATE TABLE pet (
    pet_id INTEGER NOT NULL PRIMARY KEY,
    parent_id INTEGER NOT NULL REFERENCES parents(parent_id)
	ON DELETE CASCADE
);

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
    VALUES (
    'Children',  
	--TG_TABLE_NAME,
	TG_WHEN,
       (SELECT parent_id FROM parents WHERE parent_id = OLD.parent_id),
      (SELECT COUNT(*) FROM children --%s 
       WHERE parent_id = OLD.parent_id)
   );

    RETURN OLD;
END; $$ LANGUAGE plpgsql;--', tbl, quote_nullable(tbl));

      CREATE OR REPLACE FUNCTION pet_parent_id() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO results (table_name, trigger_when, deleted_parent_id, deleted_children_count)
    VALUES (
    'Pet',  
	--TG_TABLE_NAME,
	TG_WHEN,
       (SELECT parent_id FROM parents WHERE parent_id = OLD.parent_id),
      (SELECT COUNT(*) FROM Pet --%s 
       WHERE parent_id = OLD.parent_id)
   );

    RETURN OLD;
END; $$ LANGUAGE plpgsql;

--trigger BEFORE DELETE procedure for each child table
CREATE TRIGGER tr_parents_bd_children_parent_id
BEFORE DELETE ON parents
FOR EACH ROW EXECUTE PROCEDURE children_parent_id();

CREATE TRIGGER tr_parents_bd_pet_parent_id
BEFORE DELETE ON parents
FOR EACH ROW EXECUTE PROCEDURE pet_parent_id();

--Insert and Delete test
INSERT INTO parents (parent_id) VALUES (1);
INSERT INTO parents (parent_id) VALUES (2);
INSERT INTO parents (parent_id) VALUES (3);
INSERT INTO parents (parent_id) VALUES (4);
INSERT INTO children (child_id, parent_id) VALUES (1, 1);
INSERT INTO children (child_id, parent_id) VALUES (2, 1);
INSERT INTO children (child_id, parent_id) VALUES (3, 2);
INSERT INTO children (child_id, parent_id) VALUES (35, 2);
INSERT INTO children (child_id, parent_id) VALUES (100, 2);
INSERT INTO children (child_id, parent_id) VALUES (98, 3);
INSERT INTO children (child_id, parent_id) VALUES (101, 4);
INSERT INTO pet (pet_id, parent_id) VALUES (93, 3);
DELETE FROM parents WHERE parent_id < 4;



--deleted record by parent_id
SELECT *
FROM results
WHERE deleted_children_count > 0;

--deleted record by table
SELECT table_name,SUM(deleted_children_count) AS deleted_count 
FROM results 
GROUP BY table_name 
HAVING SUM(deleted_children_count) > 0
ORDER BY table_name;