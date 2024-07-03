import logging
from flask import Flask

app = Flask(__name__)

# Configure logging
logging.basicConfig(filename='access.log', level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s', datefmt='%I:%M:%S %p CST')

@app.route('/')
def hello():
    app.logger.info('Hello request received')
    return "Welcome to Jexxl Pages!"

if __name__ == '__main__':
    app.run()