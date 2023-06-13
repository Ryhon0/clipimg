import std.stdio;

import standardpaths;
import std.process;
import std.json;
import std.file;
import matrix;
import json;
import net;

int main(string[] args)
{
	string configDir = writablePath(StandardPath.config, "clipimg", FolderFlag.create);
	string configPath = configDir ~ "/config.json";
	if(!exists(configPath))
	{
		stderr.writeln("Config file '" ~ configPath ~ "' does not exist!");

		return 1;
	}
	Config cfg = fromJson!Config(parseJSON(readText(configPath)));

	string target = null;
	foreach (t; getClipboardTargets)
	{
		import std.string;
		import std.array;
		if(t.startsWith("image/"))
		{
			target = t;
			break;
		}
	}
	
	if(!target)
	{
		stderr.writeln("Could not find an image target in clipboard!");
		return 1;
	}

	MatrixClient mx = new MatrixClient("https://ryhn.link");
	mx.tokenLogin(cfg.matrixToken, null);

	writeln("Logged in as " ~ mx.userId);
	
	ubyte[] img = getClipboardContents(target);
	auto uf = mx.uploadFile(img, "image", target);

	JSONValue sl = shortenLink(cfg.ryhnLinkToken, cfg.domain, uf.getDownloadURL("https://ryhn.link"));

	string shorturl = "https://" ~ sl["info"]["domain"].str ~ "/" ~ sl["info"]["slug"].str;
	writeln(shorturl);
	setClipboardContents(shorturl);

	return 0;
}

string[] getClipboardTargets()
{
	string[] opts = ["xclip", "-selection", "clipboard", "-t", "TARGETS", "-o"];

	auto p = pipeProcess(opts, Redirect.stdout);
	wait(p.pid);

	string[] s;
	while (!p.stdout.eof)
	{
		string ln = p.stdout.readln();
		if(ln.length)
			s ~= ln[0..$-1];
	}

	return s;
}

ubyte[] getClipboardContents(string target)
{
	string[] opts = ["xclip", "-selection", "clipboard", "-t", target, "-o"];

	auto p = pipeProcess(opts, Redirect.stdout);
	wait(p.pid);

	ubyte[] buf;
	foreach (ubyte[] rbuf; chunks(p.stdout, 4096))
		buf ~= rbuf;
	
	return buf;
}

void setClipboardContents(string contents)
{
	auto p = pipeProcess(["xclip", "-selection", "clipboard"], Redirect.stdin);
	p.stdin.write(contents);
	p.stdin.close();
	wait(p.pid);
}

JSONValue shortenLink(string token, string domain, string link)
{
	Response r = new RequestBuilder("https://ryhn.link/api/links")
		.setHeader("cookie", "login_token=" ~ token)
		.setParameter("domain", domain)
		.setParameter("url", link)
		.post();

	return parseJSON(r.responseBody.toString);
}

class Config
{
	string domain = "ryhn.link";
	string matrixToken, ryhnLinkToken;
}
