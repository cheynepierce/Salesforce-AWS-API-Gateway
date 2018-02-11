@isTest
private class APIGateway_Test {
	static testMethod void testAPIGateway() {
		Test.setMock(HttpCalloutMock.class, getRequestMock());

		String baseUrl = 'https://testendpoint.com';
		String region = 'us-east-1';
		APIGateway gateway = new APIGateway(baseUrl, region);

		Test.startTest();
			HttpResponse resp = gateway.sendRequest('HelloWorld', 'POST', 'content', 'prod');			
		Test.stopTest();

		system.assertEquals(200, resp.getStatusCode());
		Map<String, Object> respMap = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody());
		system.assertEquals('Hello, world', respMap.get('content'));
	}

	static SingleRequestMock getRequestMock() {
		Map<String, String> responseHeaders = new Map<String, String>{
			'Content-Type' => 'application/x-www-form-urlencoded'
		};

		SingleRequestMock mock = new SingleRequestMock(
			200, 'Success', '{"content": "Hello, world"}', responseHeaders
		);

		return mock;
	}
}