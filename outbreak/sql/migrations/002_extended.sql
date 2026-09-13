-- 002_extended.sql — only when [outbreak_extended] is enabled.
CREATE TABLE IF NOT EXISTS outbreak_scuffs (id INT AUTO_INCREMENT PRIMARY KEY, reporter VARCHAR(64), x FLOAT, y FLOAT, z FLOAT, note VARCHAR(200), reported_at TIMESTAMP);
