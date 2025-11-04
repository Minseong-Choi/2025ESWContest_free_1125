import pymysql
import json
import os
from contextlib import contextmanager
from dotenv import load_dotenv

load_dotenv()

try:
    import sys
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from config import DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
except ImportError:
    DB_HOST = os.environ.get('DB_HOST', 'localhost')
    DB_USER = os.environ.get('DB_USER', 'root')
    DB_PASSWORD = os.environ.get('DB_PASSWORD', '')
    DB_NAME = os.environ.get('DB_NAME', 'drawing_db')

DB_CONFIG = {
    'host': DB_HOST,
    'user': DB_USER,
    'password': DB_PASSWORD,
    'database': DB_NAME,
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

@contextmanager
def get_db_connection():
    conn = None
    try:
        conn = pymysql.connect(**DB_CONFIG)
        yield conn
        conn.commit()
    except Exception as e:
        if conn:
            conn.rollback()
        raise e
    finally:
        if conn:
            conn.close()

def init_database():
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS drawings (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                category VARCHAR(100) NOT NULL,
                image_url VARCHAR(500),
                part1_contours JSON,
                part2_contours JSON,
                part3_contours JSON,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_category (category),
                INDEX idx_name (name)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """)
        conn.commit()

def save_contours_to_db(name, category, image_url, part1, part2, part3):
    with get_db_connection() as conn:
        cursor = conn.cursor()
        try:
            cursor.execute("""
                INSERT INTO drawings (name, category, image_url, part1_contours, part2_contours, part3_contours)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                name,
                category,
                image_url,
                json.dumps(part1, ensure_ascii=False),
                json.dumps(part2, ensure_ascii=False),
                json.dumps(part3, ensure_ascii=False)
            ))
            drawing_id = cursor.lastrowid
            print(f"Successfully saved drawing '{name}' to DB with ID: {drawing_id}")
            return drawing_id
        except Exception as e:
            print(f"Error saving to DB: {str(e)}")
            raise

def get_random_drawing_by_category(category):
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, name, image_url, part1_contours, part2_contours, part3_contours
            FROM drawings
            WHERE category = %s
            ORDER BY RAND()
            LIMIT 1
        """, (category,))
        result = cursor.fetchone()
        if result:
            return {
                'id': result['id'],
                'name': result['name'],
                'imageUrl': result['image_url'],
                'part1Contours': json.loads(result['part1_contours']) if result['part1_contours'] else [],
                'part2Contours': json.loads(result['part2_contours']) if result['part2_contours'] else [],
                'part3Contours': json.loads(result['part3_contours']) if result['part3_contours'] else []
            }
        return None

def get_wrong_answers_by_category(category, exclude_id, limit=3):
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT name
            FROM drawings
            WHERE category = %s AND id != %s
            ORDER BY RAND()
            LIMIT %s
        """, (category, exclude_id, limit))
        results = cursor.fetchall()
        return [r['name'] for r in results]

