-- 003_progression.sql — outbreak_intel + outbreak_opportunities. Idempotent. Apply only when [outbreak_progression] is enabled.
CREATE TABLE IF NOT EXISTS outbreak_intel (
  citizenid VARCHAR(64) NOT NULL, intel_id VARCHAR(64) NOT NULL,
  state VARCHAR(16) NOT NULL, reliability VARCHAR(16), source VARCHAR(32),
  discovered_at TIMESTAMP NULL, updated_at TIMESTAMP NULL,
  PRIMARY KEY (citizenid, intel_id)
);
CREATE TABLE IF NOT EXISTS outbreak_opportunities (
  opp_id VARCHAR(64) PRIMARY KEY, state VARCHAR(16) NOT NULL, stage INT NOT NULL DEFAULT 0, data LONGTEXT,
  started_at BIGINT NULL, resolved_at BIGINT NULL, outcome VARCHAR(32) NULL, cooldown_until BIGINT NULL
);
CREATE TABLE IF NOT EXISTS outbreak_opp_participants (
  opp_id VARCHAR(64) NOT NULL, citizenid VARCHAR(64) NOT NULL, role VARCHAR(32), contributions LONGTEXT,
  PRIMARY KEY (opp_id, citizenid)
);
CREATE TABLE IF NOT EXISTS outbreak_opp_log (
  id INT AUTO_INCREMENT PRIMARY KEY, opp_id VARCHAR(64), event VARCHAR(48), citizenid VARCHAR(64) NULL, data LONGTEXT, at TIMESTAMP
);
CREATE TABLE IF NOT EXISTS outbreak_camps (
  camp_id VARCHAR(64) PRIMARY KEY, population INT, food INT, water INT, meds INT, ammo INT, power INT, defenses INT, morale INT, threat INT,
  state VARCHAR(16) NOT NULL DEFAULT 'alive', data LONGTEXT
);
