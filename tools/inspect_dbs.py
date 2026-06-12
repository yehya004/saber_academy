import sqlite3
import os

db_files = ["database.sqlite", "quran.db", "text.sqlite2.db", "text.sqlite3.db"]

for db_file in db_files:
    path = os.path.join(r"C:\Users\Yehya\Pictures\Saber Academy", db_file)
    if not os.path.exists(path):
        print(f"Database {db_file} not found.")
        continue
        
    print(f"\n--- Inspecting {db_file} ---")
    try:
        conn = sqlite3.connect(path)
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        print(f"Tables in {db_file}: {[t[0] for t in tables]}")
        
        # Check schemas of interesting tables
        for table in tables:
            t_name = table[0]
            if any(x in t_name.lower() for x in ["surah", "sura", "page", "mushaf", "chapter", "pdf"]):
                print(f"Schema for {t_name}:")
                cursor.execute(f"PRAGMA table_info({t_name});")
                print(cursor.fetchall())
                
                # Show first 3 rows
                try:
                    cursor.execute(f"SELECT * FROM {t_name} LIMIT 3;")
                    print(f"Sample data from {t_name}: {cursor.fetchall()}")
                except Exception as e:
                    print(f"Error querying {t_name}: {e}")
        conn.close()
    except Exception as e:
        print(f"Error reading {db_file}: {e}")
