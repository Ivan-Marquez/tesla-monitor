USE powerwall

CREATE RETENTION POLICY raw ON powerwall duration 3d replication 1

ALTER RETENTION POLICY autogen ON powerwall duration 365d

CREATE RETENTION POLICY kwh ON powerwall duration INF replication 1
	
CREATE RETENTION POLICY daily ON powerwall duration INF replication 1

CREATE RETENTION POLICY monthly ON powerwall duration INF replication 1
	
CREATE CONTINUOUS QUERY cq_autogen ON powerwall BEGIN SELECT mean(home) AS home, mean(solar) AS solar, mean(from_pw) AS from_pw, mean(to_pw) AS to_pw, mean(from_grid) AS from_grid, mean(to_grid) AS to_grid, last(percentage) AS percentage INTO powerwall.autogen.:MEASUREMENT FROM (SELECT load_instant_power AS home, solar_instant_power AS solar, abs((1+battery_instant_power/abs(battery_instant_power))*battery_instant_power/2) AS from_pw, abs((1-battery_instant_power/abs(battery_instant_power))*battery_instant_power/2) AS to_pw, abs((1+site_instant_power/abs(site_instant_power))*site_instant_power/2) AS from_grid, abs((1-site_instant_power/abs(site_instant_power))*site_instant_power/2) AS to_grid, percentage FROM raw.http) GROUP BY time(1m), month, year fill(linear) END
	
CREATE CONTINUOUS QUERY cq_kwh ON powerwall RESAMPLE EVERY 1m BEGIN SELECT integral(home)/1000/3600 AS home, integral(solar)/1000/3600 AS solar, integral(from_pw)/1000/3600 AS from_pw, integral(to_pw)/1000/3600 AS to_pw, integral(from_grid)/1000/3600 AS from_grid, integral(to_grid)/1000/3600 AS to_grid INTO powerwall.kwh.:MEASUREMENT FROM autogen.http GROUP BY time(1h), month, year tz('America/Puerto_Rico') END
	
CREATE CONTINUOUS QUERY cq_daily ON powerwall RESAMPLE EVERY 1h BEGIN SELECT sum(home) AS home, sum(solar) AS solar, sum(from_pw) AS from_pw, sum(to_pw) AS to_pw, sum(from_grid) AS from_grid, sum(to_grid) AS to_grid INTO powerwall.daily.:MEASUREMENT FROM powerwall.kwh.http GROUP BY time(1d), month, year tz('America/Puerto_Rico') END 
	
CREATE CONTINUOUS QUERY cq_monthly ON powerwall RESAMPLE EVERY 1h BEGIN SELECT sum(home) AS home, sum(solar) AS solar, sum(from_pw) AS from_pw, sum(to_pw) AS to_pw, sum(from_grid) AS from_grid, sum(to_grid) AS to_grid INTO powerwall.monthly.:MEASUREMENT FROM powerwall.daily.http GROUP BY time(365d), month, year END