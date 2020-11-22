import pandas as pd

def run():
    for f in ["runtimes_per_data_type.csv", "runtimes_per_column_type.csv"]:
        print(pd.read_csv(f).groupby("type")["runtime"].agg("sum"))

if __name__ == "__main__":
    run()