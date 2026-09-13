-- 005_radio.sql — radio range model (repeaters, base stations)
CREATE TABLE IF NOT EXISTS outbreak_repeaters   (repeater_id VARCHAR(32) PRIMARY KEY, active TINYINT(1) NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS outbreak_base_radios (citizenid VARCHAR(64) PRIMARY KEY, x FLOAT, y FLOAT, z FLOAT);
