public with sharing class APIGateway {
	private String ACCESS_KEY;
	private String SECRET_KEY;

	private final String ALGORITHM = 'AWS4-HMAC-SHA256';
	private final String SERVICE = 'execute-api';
	private final String CONTENT_TYPE = 'application/x-www-form-urlencoded';

	private String baseUrl;
	private String region;

	private Datetime dt;
	private String d;
	private String timestamp;
	private String scope;
	private String canonicalRequest;

	private String requestPath;
	private String host;
	private String method;
	private String content;
	private String body;

	public APIGateway(String baseUrl, String region) {
		this.baseUrl = baseUrl;
		this.region = region;
		this.host = this.baseUrl.substring(8);

		AWS_Configuration__c awsConfig = AWS_Configuration__c.getOrgDefaults();
		this.ACCESS_KEY = awsConfig.Access_Key__c;
		this.SECRET_KEY = awsConfig.Secret_Key__c;
	}

	public String sendRequest(String functionName, String method, String content, String stage) {
		this.requestPath = '/' + stage + '/' + functionName;
		this.method = method;
		this.content = content;
		
		Http http = new Http();
		HttpRequest req = this.getRequest();
		HttpResponse resp = http.send(req);
		String respBody = resp.getBody();
		system.debug(respBody);

		return respBody;
	}

	/**
	* Generate the HTTP request to get the list of files in the specified folder.
	*/
	public HttpRequest getRequest() {
		this.dt = Datetime.now();
		this.d = this.getDate();
		this.timestamp = this.getTimestamp();

		String url = this.baseUrl + this.requestPath;

		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod(this.method);
		req.setHeader('Content-Type', this.CONTENT_TYPE);
		req.setHeader('Host', this.host);
		req.setHeader('X-Amz-Date', this.timestamp);
		req.setHeader('Authorization', this.getAuthHeader());
		req.setBody(this.content);

		return req;
	}

	/**
	* Generate the authorization header for the list bucket operation.
	*/
	private String getAuthHeader() {
		String authHeader = this.ALGORITHM + ' ';
		this.scope = this.getScope();
		this.canonicalRequest = this.getCanonicalRequest();

		authHeader += 'Credential=' + this.ACCESS_KEY + '/' + this.scope + ', ';
		authHeader += 'SignedHeaders=content-type;host;x-amz-date, ';
		authHeader += 'Signature=' + this.getSignature();

		return authHeader;
	}

	/**
	* Returns the current date in string format (YYYYMMDD)
	*/
	private String getDate() {
		return String.valueOf(this.dt.yearGmt()) + 
				this.getString(this.dt.monthGmt()) + 
				this.getString(this.dt.dayGmt());
	}

	/**
	* Returns the current timestamp in ISO format (YYYYMMDDTHHMMSSZ)
	*/
	private String getTimestamp() {
		return this.getString(this.dt.yearGmt()) + 
				this.getString(this.dt.monthGmt()) + 
				this.getString(this.dt.dayGmt()) + 'T' + 
				this.getString(this.dt.hourGmt()) + 
				this.getString(this.dt.minuteGmt()) + 
				this.getString(this.dt.secondGmt()) + 
				'Z';
	}

	/**
	* Convert a date/time component to string format (prependig a '0' if necessary).
	*/
	private String getString(Integer comp) {
		String s = String.valueOf(comp);
		if (s.length() == 1) {
			return '0'+s;
		}
		return s;
	}

	/**
	* Construct the AWS scope parameter.
	*/
	private String getScope() {
		return this.d + '/' + this.region + '/' + this.SERVICE + '/aws4_request';
	}

	/**
	* Generate the request signature
	*/
	private String getSignature() {
		return EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', this.getStringToSign(), this.getSigningKey()));
	}

	/**
	* Generate the string to sign for API Gateway authorization.
	*/
	private Blob getStringToSign() {
		String stringToSign = this.ALGORITHM + '\n' + 
				this.timestamp + '\n' + 
				this.scope + '\n' + 
				EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(this.canonicalRequest)));
		return Blob.valueOf(stringToSign);
	}

	/**
	* Generate the canonical request needed for the list bucket operation.
	*/
	private String getCanonicalRequest() {
		String canonicalRequest = 'POST\n' + 
				this.requestPath + '\n\n' + 
				'content-type:' + this.CONTENT_TYPE + '\n' + 
				'host:' + this.host + '\n' + 
				'x-amz-date:' + this.timestamp + '\n\n' + 
				'content-type;host;x-amz-date\n' + 
				EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(this.content)));
		return canonicalRequest;
	}

	/**
	* Generate the AWS signing key.
	*/
	private Blob getSigningKey() {
		Blob kDate = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.d), Blob.valueOf('AWS4' +this.SECRET_KEY));
		Blob kRegion = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.region), kDate);
		Blob kService = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.SERVICE), kRegion);
		Blob kSigning = Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'), kService);
		return kSigning;
	}
}