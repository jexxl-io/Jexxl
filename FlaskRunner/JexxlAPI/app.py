import logging
from flask import Flask, request, redirect
import SuiteQLTool

app = Flask(__name__)

# Configure logging
logging.basicConfig(filename='access.log', level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %I:%M:%S %p CST')

@app.route('/', methods=['GET'])
def home():
    app.logger.info('Request to \'/\' was made')

    return redirect("https://www.jexxl.io", code=302)

@app.route('/suiteql', methods=['POST'])
def suiteql():
    app.logger.info('Request to \'/suiteql\' was made')
    
    auth = request.headers.get('open-ai-key')
    request_data = request.get_json()
    question = request_data['question']

    answer = SuiteQLTool.buildQuery(auth, question)
    return answer

if __name__ == '__main__':
    app.run()