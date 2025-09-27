from flask import Flask
import os

app = Flask(__name__)

# Simple counter (in production, this would be in a database)
visit_count = 0

@app.route('/')
def home():
    global visit_count
    visit_count += 1
    return f'''
    <h1>DevOps Demo Application</h1>
    <p>This app has been visited <strong>{visit_count}</strong> times!</p>
    <p><a href="/health">Health Check</a></p>
    '''

@app.route('/health')
def health():
    return {'status': 'healthy', 'visits': visit_count}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
