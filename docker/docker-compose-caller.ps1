#Install docker image
docker-compose -f docker/docker-compose.yml up -d

#Open ClickHouse client
docker exec -it local-clickhouse clickhouse-client --password "your_password"

#Execute SQL Kafka Integration
Get-Content sql/03_kafka_integration.sql -Raw | docker exec -i local-clickhouse clickhouse-client --password "your_password"

# Create a virtual environment folder named 'venv'
python -m venv venv

# Activate the virtual environment in PowerShell
.\venv\Scripts\Activate.ps1

# Upgrade pip inside the environment
python -m pip install --upgrade pip

# Install dbt-clickhouse and kafka dependencies
pip install dbt-clickhouse kafka-python clickhouse-connect pandas numpy

# Initialize dbt project
dbt init dbt_aeso

# Navigate into the project folder
cd dbt_aeso

# Run dbt telling it to look in the current directory (.) for profiles.yml
dbt debug --profiles-dir .
dbt run --profiles-dir .

# Validate the data in Clickhouse
docker exec -it local-clickhouse clickhouse-client --password "your_password" --query "SELECT * FROM alberta_energy.fct_regional_power_hourly LIMIT 10 FORMAT Pretty"

# Run the producer 
pip install kafka-python
python scripts/kafka_producer.py

