from os import environ
from flask import Flask, render_template
app = Flask(__name__)
 
@app.route('/')
def home():
   return render_template(environ['html_name'])
if __name__ == '__main__':
   app.run()
   

# To run the app, set the environment variable 'html_name' to the desired HTML file name.
# For example:
# export html_name='blue.html'  # or 'green.html'# Then execute:
# python blue-green.py  # Ththe 'templates' directory.         
# The app will serve the specified HTML file at the root URL.
# Make sure the HTML files are in the 'templates' directory.
# Example HTML files: 'blue.html' and 'green.html' should be placed in
# to build the docker image and run the flask appplication.
#you can change the html files as per your requirement.
#i have used the dockhub platfrom for the storing image you can use ecr acr artifect registry or any other platform.
#docker build -t blue-green-app . 