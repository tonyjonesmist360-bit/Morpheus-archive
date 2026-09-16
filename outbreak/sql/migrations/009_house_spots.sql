-- 009_house_spots.sql — v0.23 bugfix 3: named search spots INSIDE houses (kitchen counter, bathroom cabinet...)
-- Rows are placed in game with /ob_spot; config defaults seed the table on first boot (see outbreak_housing/server).
CREATE TABLE IF NOT EXISTS outbreak_house_spots (
  id INT AUTO_INCREMENT PRIMARY KEY, house_id VARCHAR(48) NOT NULL, name VARCHAR(48) NOT NULL, tbl VARCHAR(32) NOT NULL DEFAULT 'house',
  x FLOAT, y FLOAT, z FLOAT, UNIQUE KEY house_name (house_id, name)
);
