build:
	meltano install

pipeline:
	meltano run tap-spreadsheets-anywhere add-timestamps target-parquet
	mkdir -p data/data_catalog/conformed
	mkdir -p data/data_catalog/prep
	mkdir -p data/data_catalog/raw
	meltano invoke dbt-duckdb deps
	meltano invoke dbt-duckdb run-operation elo_rollforward
	meltano invoke dbt-duckdb build

superset-visuals:
	meltano invoke superset fab create-admin --username admin --firstname lebron --lastname james --email admin@admin.org --password password
	meltano invoke superset import-datasources -p visuals/datasources.yml
	meltano invoke superset import-dashboards -p visuals/dashboards.json
	meltano invoke superset:ui

docker-build:
	docker build -t mdsbox .

docker-run:
	docker run \
		--publish 8088:8088 \
	 	--env MELTANO_CLI_LOG_LEVEL=WARNING \
		--env MDS_SCENARIOS=1000 \
		--env MDS_INCLUDE_ACTUALS=true \
		--env MDS_LATEST_RATINGS=true \
		--env MDS_ENABLE_EXPORT=true \
		mdsbox make pipeline superset-visuals 

evidence-build:
	cd analyze && npm update

evidence-run:
	mkdir -p data_catalog
	cp -r /workspaces/nba-monte-carlo/data/data_catalog/* /workspaces/nba-monte-carlo/analyze/data_catalog
	cp /workspaces/nba-monte-carlo/analyze/data_catalog/mdsbox.db /workspaces/nba-monte-carlo/analyze/
	cd analyze && npm run dev