-- 008_supply.sql — settlements (a claimed safehouse with residents and a stockpile) and the World Director's log. Idempotent.
CREATE TABLE IF NOT EXISTS outbreak_settlements (house_id VARCHAR(64) PRIMARY KEY, residents INT NOT NULL DEFAULT 0, morale INT NOT NULL DEFAULT 60, names TEXT, debt TEXT, flags TEXT, log LONGTEXT, last_tick BIGINT NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS outbreak_director_log (id INT AUTO_INCREMENT PRIMARY KEY, house_id VARCHAR(64), action VARCHAR(48), detail VARCHAR(255), at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
