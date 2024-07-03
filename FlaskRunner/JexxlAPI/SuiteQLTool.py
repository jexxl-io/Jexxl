from langchain_core.runnables import RunnableLambda
from langchain_openai import OpenAI
from langchain.prompts import PromptTemplate
import logging

# Configure logging
logging.basicConfig(filename='access.log', level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %I:%M:%S %p CST')

def buildQuery(openai_api_key, question):

    template = """
    These are the only available tables to choose from:
    1. transaction
    2. transactionLine
    3. transactionAccountingLine
    4. subsidiary
    5. currency
    6. accountingPeriod
    7. account
    8. vendor
    9. entity

    These are the only available joins:
    1. transactionLine.subsidiary = subsidiary.id
    2. transactionLine.transaction = transaction.id
    3. transaction.currency = currency.id
    4. accountingPeriod.id = transaction.postingPeriod
    5. transactionAccountingLine.transaction = transaction.id
    6. transactionAccountingLine.account = account.id
    7. transactionLine.entity = entity.id
    8. transactionLine.entity = vendor.id

    Considering all that I've told you above, produce a SuiteQL query based on the question. Ensure that you never break these 5 rules:
    1. If you are unable to generate a SuiteQL query with confidence, respond that you are unable to.
    2. If you are unable to determine which columns to return, use SELECT *.
    3. All dates must be formatted 'MM/dd/YYYY'.
    4. Query format must be in SuiteQL.
    5. Only use the joins and tables that you need to.

    Question: {question}
    """

    prompt_template = PromptTemplate(template=template, input_variables=["question"])

    def format_prompt(inputs):
        return prompt_template.format(**inputs)
    
    runnable_prompt = RunnableLambda(format_prompt)
    llm = OpenAI(api_key=openai_api_key, temperature=0.7, max_tokens=150)
    runnable_llm = RunnableLambda(lambda prompt: llm.invoke(prompt))

    sequence = runnable_prompt | runnable_llm

    inputs = {
        "question": question
    }

    try:
        response = sequence.invoke(inputs)
        logging.info("Query executed successfully")

        # Ensure the response is properly parsed
        if isinstance(response, str):
            return response.replace('\n', ' ').strip()
        elif isinstance(response, dict) and 'choices' in response and len(response['choices']) > 0:
            return response['choices'][0]['text'].replace('\n', ' ').strip()
        else:
            logging.error("Unexpected response format from OpenAI API")
            raise ValueError("Unexpected response format from OpenAI API")
    except Exception as e:
        logging.error(f"Failed to execute query: {e}")
        raise