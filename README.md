# Salesforce AWS API Gateway

### Purpose
This is a simple Apex class that sends a request to an AWS API Gateway endpoint.

### Deployment
<a href="https://githubsfdeploy.herokuapp.com?owner=cheynepierce&repo=Salesforce-AWS-API-Gateway">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

### Usage
Create a new organizational level AWS Configuration custom setting, and set your AWS access key and secret key.

Send a request to your API Gateway endpoint, by doing the following:

```
APIGateway gateway = new APIGateway('base url', 'region');
HttpResponse resp = gateway.sendRequest('function name', 'method', 'request content', 'function stage');
```
