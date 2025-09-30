from flask import Flask, request
import psycopg2
import os
from datetime import datetime
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time

app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency')

# Database connection function
def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=os.environ.get('DB_HOST', 'localhost'),
            database=os.environ.get('DB_NAME', 'devops_demo'),
            user=os.environ.get('DB_USER', 'postgres'),
            password=os.environ.get('DB_PASSWORD', 'password')
        )
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

# Initialize database table
def init_db():
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            cur.execute('''
                CREATE TABLE IF NOT EXISTS visits (
                    id SERIAL PRIMARY KEY,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    ip_address VARCHAR(50)
                )
            ''')
            conn.commit()
            cur.close()
            conn.close()
            print("Database initialized successfully")
        except Exception as e:
            print(f"Database init error: {e}")

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    # Record metrics
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()
    
    # Record latency
    if hasattr(request, 'start_time'):
        REQUEST_LATENCY.observe(time.time() - request.start_time)
    
    return response

@app.route('/')
def home():
    conn = get_db_connection()
    visit_count = 0
    
    if conn:
        try:
            cur = conn.cursor()
            # Record this visit
            cur.execute("INSERT INTO visits (ip_address) VALUES (%s)", (request.remote_addr or '127.0.0.1',))
            conn.commit()
            
            # Get total visits
            cur.execute("SELECT COUNT(*) FROM visits")
            visit_count = cur.fetchone()[0]
            
            cur.close()
            conn.close()
        except Exception as e:
            print(f"Database error: {e}")
    
    return f'''
    <h1>DevOps Demo Application</h1>
    <p>This app has been visited <strong>{visit_count}</strong> times!</p>
    <p>Powered by PostgreSQL database</p>
    <p><a href="/health">Health Check</a> | <a href="/visits">View All Visits</a> | <a href="/metrics">Metrics</a></p>
    '''

@app.route('/health')
def health():
    conn = get_db_connection()
    db_status = "connected" if conn else "disconnected"
    if conn:
        conn.close()
    
    return {
        'status': 'healthy', 
        'database': db_status,
        'timestamp': datetime.now().isoformat()
    }

@app.route('/visits')
def visits():
    conn = get_db_connection()
    if not conn:
        return "Database not available"
    
    try:
        cur = conn.cursor()
        cur.execute("SELECT id, timestamp FROM visits ORDER BY timestamp DESC LIMIT 10")
        visits = cur.fetchall()
        cur.close()
        conn.close()
        
        html = "<h2>Recent Visits</h2><ul>"
        for visit in visits:
            html += f"<li>Visit #{visit[0]} at {visit[1]}</li>"
        html += "</ul><a href='/'>Back to Home</a>"
        return html
    except Exception as e:
        return f"Error: {e}"

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
