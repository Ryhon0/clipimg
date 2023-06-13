module net;

import requests;
public import requests : Response;
public import std.uri : urlEncode = encode;

class RequestBuilder
{
	string url;
	string[string] params;
	string[string] headers;

	this(string url)
	{
		this.url = url;
	}


	RequestBuilder setParameter(string key, string value)
	{
		if(value) params[key] = value;
		return this;
	}

	RequestBuilder setParameter(T)(string key, T value)
	{
		import std.conv : to;
		return setParameter(key, value.to!string);
	}

	RequestBuilder setHeader(string name, string value)
	{
		headers[name] = value;
		return this;
	}

	Request createRequest()
	{
		Request r = Request();
		r.sslSetVerifyPeer(false);
		r.addHeaders(headers);
		return r;
	}

	Response get()
	{
		Request r = createRequest();
		return r.get(url, params);
	}

	Response put()
	{
		Request r = createRequest();
		import requests.utils : aa2params;
		return r.put(url, params.aa2params);
	}

	Response put(T)(T data, string contentType)
	{
		import std.stdio;
		Request r = createRequest();
		return r.put(url, data, contentType);
	}

	Response post()
	{
		Request r = createRequest();
		return r.post(url, params);
	}

	Response post(T)(T data, string contentType)
	{
		Request r = createRequest();
		return r.post(url, data, contentType);
	}

	Response del()
	{
		Request r = createRequest();
		return r.deleteRequest(url, params);
	}
}