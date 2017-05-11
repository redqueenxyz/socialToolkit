# Todo:

## Extract:
### Twitter: Web > CSV
### Facebook: Web > JSON

## Transform:
### Twitter: CSV > JSON
### Facebook: JSON

## Load:
### Twitter: JSON > MongoDB
### Facebook: JSON > MongoDB

# Freezing PIP in the Virtualenv
        pip freeze > requirements.txt

Setup

Use Virtualenv for Python 3.5.1 (Point to another python3 instance if you've got it)
virtualenv -p /usr/bin/python3.5 venv

Update all the dependencies you need: 
pip install -r requirements.txt
