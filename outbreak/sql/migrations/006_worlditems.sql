-- 006_worlditems.sql — placed objects and taken map props
CREATE TABLE IF NOT EXISTS outbreak_world_items (
  id INT PRIMARY KEY, item VARCHAR(48), count INT, metadata LONGTEXT, model BIGINT, x FLOAT, y FLOAT, z FLOAT, rx FLOAT, ry FLOAT, rz FLOAT,
  placed_by VARCHAR(64), placed_at TIMESTAMP, house_id VARCHAR(64) NULL, storage TINYINT(1) DEFAULT 0, locked TINYINT(1) DEFAULT 0
);
CREATE TABLE IF NOT EXISTS outbreak_hidden_props (
  id INT AUTO_INCREMENT PRIMARY KEY, model BIGINT, x FLOAT, y FLOAT, z FLOAT, item VARCHAR(48), taken_at TIMESTAMP
);
