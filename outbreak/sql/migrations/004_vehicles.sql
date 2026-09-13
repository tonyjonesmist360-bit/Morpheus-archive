-- 004_vehicles.sql — outbreak_vehicles v2 (claimed vehicles persist and respawn server-side)
CREATE TABLE IF NOT EXISTS outbreak_vehicles (
  plate VARCHAR(12) PRIMARY KEY, model BIGINT, fuel FLOAT, battery VARCHAR(8), hotwired TINYINT(1), locked TINYINT(1), part VARCHAR(48) NULL,
  claimed TINYINT(1) NOT NULL DEFAULT 0, owner VARCHAR(64) NULL, x FLOAT, y FLOAT, z FLOAT, heading FLOAT, data LONGTEXT
);
