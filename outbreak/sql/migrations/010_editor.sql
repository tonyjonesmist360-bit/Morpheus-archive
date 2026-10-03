-- 010_editor.sql — the World Editor (v0.27): everything placed, painted, wired or written in F10 -> Editor
CREATE TABLE IF NOT EXISTS outbreak_editor_npcs (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(48), look VARCHAR(220), model VARCHAR(64) NOT NULL, x FLOAT, y FLOAT, z FLOAT, h FLOAT, behaviour LONGTEXT, stance VARCHAR(16) DEFAULT 'neutral', data LONGTEXT);
CREATE TABLE IF NOT EXISTS outbreak_editor_hidden_peds (id INT AUTO_INCREMENT PRIMARY KEY, model BIGINT NOT NULL, x FLOAT, y FLOAT, z FLOAT, note VARCHAR(64));
CREATE TABLE IF NOT EXISTS outbreak_editor_interactions (id INT AUTO_INCREMENT PRIMARY KEY, target LONGTEXT NOT NULL, label VARCHAR(64) NOT NULL, icon VARCHAR(64), hold_ms INT DEFAULT 0, anim VARCHAR(32), conditions LONGTEXT, actions LONGTEXT, enabled TINYINT(1) DEFAULT 1);
CREATE TABLE IF NOT EXISTS outbreak_editor_zones (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(48), kind VARCHAR(24) NOT NULL, x FLOAT, y FLOAT, z FLOAT, radius FLOAT, data LONGTEXT);
CREATE TABLE IF NOT EXISTS outbreak_editor_kv (k VARCHAR(64) PRIMARY KEY, v LONGTEXT);
CREATE TABLE IF NOT EXISTS outbreak_editor_missions (id VARCHAR(48) PRIMARY KEY, def LONGTEXT NOT NULL, enabled TINYINT(1) DEFAULT 1);
CREATE TABLE IF NOT EXISTS outbreak_editor_once (interaction_id INT, citizenid VARCHAR(64), at BIGINT, PRIMARY KEY (interaction_id, citizenid));
