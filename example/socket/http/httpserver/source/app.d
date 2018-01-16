/*
 * Collie - An asynchronous event-driven network framework using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the Apache-2.0 License.
 *
 */
import std.stdio;
import std.experimental.logger;
import std.exception;
import std.typecons;
import std.functional;

import collie.net;
import collie.codec.http;
import collie.codec.http.server;
import collie.bootstrap.serversslconfig;
import std.parallelism;

debug { 
        extern(C) __gshared string[] rt_options = [ "gcopt=profile:1"];// maxPoolSize:50" ];
}

class MyHandler : RequestHandler
{
protected:
	override void onResquest(HTTPMessage headers) nothrow
	{
		_header = headers;
//		collectException({
//			trace("************************");
//			writeln("---new HTTP request!");
//			writeln("path is : ", _header.url);
//			}());
	}

	override void onBody(const ubyte[] data) nothrow
	{
//		collectException({
//				writeln("body is : ", cast(string) data);
//			}());
	}

	override void onEOM() nothrow
	{
		collectException({
				auto build = Unique!ResponseBuilder(new ResponseBuilder(_downstream));
				//ResponseBuilder build = new ResponseBuilder(_downstream);// scoped!ResponseBuilder(_downstream);
				build.status(cast(ushort)200,HTTPMessage.statusText(200));
				build.setBody(cast(ubyte[])"string hello = \"hello world!!\";");
				build.sendWithEOM();
			}());
	}

	override void onError(HTTPErrorCode code) nothrow {
		collectException({
				writeln("on erro : ", code);
			}());
	}

	override void requestComplete() nothrow
	{
		collectException({
				writeln("requestComplete : ");
			}());
	}

private:
	HTTPMessage _header;
}


RequestHandler newHandler(RequestHandler,HTTPMessage)
{

	 auto handler = new MyHandler();
	trace("----------newHandler, handle is : ", cast(void *)handler);
	return handler;
}

void main()
{
    
    writeln("Edit source/app.d to start your project.");
   // globalLogLevel(LogLevel.warning);
	trace("----------");

	version(USE_SSL){
		ServerSSLConfig ssl = new ServerSSLConfig(SSLMode.SSLv2v3);
		ssl.certificateFile = "server.pem";
		ssl.privateKeyFile = "server.pem";
	}
	HTTPServerOptions option = new HTTPServerOptions();
	option.handlerFactories ~= (toDelegate(&newHandler));
	option.threads = totalCPUs;
	version(USE_SSL) option.ssLConfig = ssl;
	HTTPServerOptions.IPConfig ipconfig ;
	ipconfig.address = new InternetAddress("0.0.0.0", 8083);

	HttpServer server = new HttpServer(option);
	server.addBind(ipconfig);
	server.start();
}
