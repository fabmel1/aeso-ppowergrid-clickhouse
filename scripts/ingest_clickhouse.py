import random
from datetime import datetime, timedelta
import clickhouse_connect
import pandas as pd
import numpy as np

def generate_mock_aeso_data(num_rows=100_000):
    regions = ['CALGARY', 'EDMONTON', 'CENTRAL', 'NORTH', 'SOUTH']
    asset_types = ['GAS', 'WIND', 'SOLAR', 'HYDRO']
    
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(days=7)
    
    timestamps = [start_time + timedelta(seconds=random.randint(0, 7 * 86400)) for _ in range(num_rows)]
    
    df = pd.DataFrame({
        'recorded_at': pd.to_datetime(timestamps),
        'region_id': np.random.choice(regions, size=num_rows),
        'asset_type': np.random.choice(asset_types, size=num_rows, p=[0.5, 0.25, 0.15, 0.10]),
        'megawatts': np.random.uniform(10.0, 850.0, size=num_rows).astype(np.float32),
        'pool_price_cad': np.random.uniform(15.0, 150.0, size=num_rows).astype(np.float32),
        'grid_frequency_hz': np.random.normal(60.0, 0.02, size=num_rows).astype(np.float32)
    })
    
    # Sort locally before insertion to match MergeTree primary key
    return df.sort_values(by=['region_id', 'asset_type', 'recorded_at'])

def main():
    print("Connecting to ClickHouse...")
    client = clickhouse_connect.get_client(host='localhost', port=8123, username='default', password='password')
    
    # Execute DDL
    with open('sql/01_schema.sql', 'r') as f:
        for stmt in f.read().split(';'):
            if stmt.strip():
                client.command(stmt)
                
    with open('sql/02_materialized_views.sql', 'r') as f:
        for stmt in f.read().split(';'):
            if stmt.strip():
                client.command(stmt)

    print("Generating 100,000 synthetic AESO power grid events...")
    df = generate_mock_aeso_data(100_000)

    print("Ingesting batch into ClickHouse MergeTree...")
    client.insert_df('alberta_energy.grid_telemetry', df)
    
    print("Ingestion complete! Checking row count:")
    result = client.query("SELECT count() FROM alberta_energy.grid_telemetry")
    print(f"Total raw records: {result.result_rows[0][0]:,}")
    
    mv_result = client.query("SELECT count() FROM alberta_energy.hourly_regional_summary")
    print(f"Aggregated records in Materialized View: {mv_result.result_rows[0][0]:,}")

if __name__ == '__main__':
    main()