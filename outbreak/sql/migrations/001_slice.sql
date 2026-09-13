-- 001_slice.sql — everything the vertical slice persists. Idempotent.
CREATE TABLE IF NOT EXISTS outbreak_players   (citizenid VARCHAR(64) PRIMARY KEY, first_spawn TIMESTAMP DEFAULT CURRENT_TIMESTAMP, dead TINYINT(1) NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS outbreak_needs     (citizenid VARCHAR(64) PRIMARY KEY, data LONGTEXT NOT NULL);
CREATE TABLE IF NOT EXISTS outbreak_identity  (citizenid VARCHAR(64) PRIMARY KEY, callsign VARCHAR(32), former VARCHAR(48), description VARCHAR(200), traits TEXT);
CREATE TABLE IF NOT EXISTS outbreak_skills    (citizenid VARCHAR(64) PRIMARY KEY, xp TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS outbreak_houses    (house_id VARCHAR(64) PRIMARY KEY, owner VARCHAR(64) NULL, barricade INT NOT NULL DEFAULT 0, visited TINYINT(1) NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS outbreak_loot      (container_id VARCHAR(128) PRIMARY KEY, searched_at BIGINT NOT NULL);
CREATE TABLE IF NOT EXISTS outbreak_memorial  (id INT AUTO_INCREMENT PRIMARY KEY, citizenid VARCHAR(64), name VARCHAR(128), days_survived INT, cause VARCHAR(64), died_at TIMESTAMP);
CREATE TABLE IF NOT EXISTS outbreak_corpses   (stash_id VARCHAR(96) PRIMARY KEY, citizenid VARCHAR(64), name VARCHAR(128), x FLOAT, y FLOAT, z FLOAT, died_at TIMESTAMP);
CREATE TABLE IF NOT EXISTS outbreak_reputation(citizenid VARCHAR(64), faction VARCHAR(32), value INT NOT NULL DEFAULT 0, PRIMARY KEY (citizenid, faction));
