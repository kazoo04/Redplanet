/**
 *  Authors:
 *    @kazoo04
 *
 *  See_Also:
 *    http://wllwmiilmmw.tumblr.com/post/21429448637/d-2
 */

import std.algorithm	: map, reduce;
import std.base64	: Base64;
import std.conv		: to;
import std.datetime	: Clock, SysTime, DateTime, dur;
import std.json		: JSONValue, parseJSON;
import std.net.curl	: HTTP, post;
import std.stdio	: write, writeln, readln;
import std.string	: join, split, chomp, format, rightJustify;
import std.uri		: encodeComponent;
import std.regex;
import std.stream;

import deimos.openssl.ssl;

enum Api : string
{
  host            = "http://api.twitter.com",
  request_token   = host ~ "/oauth/request_token",
  authorize       = host ~ "/oauth/authorize",
  access_token    = host ~ "/oauth/access_token",
  statuses_update = host ~ "/statuses/update.json",
}

enum Stream : string
{
  host = "https://userstream.twitter.com/2/",
  user = host ~ "user.json",
}

string[char[]] loadKeys()
{
  Stream file = new BufferedFile("keys.conf");

  string[char[]] keys;

  foreach(char[] _line; file) {
    string line = replace(cast(string)_line, regex(r"\s", "g"), "");
    
    if(line.length == 0) continue;
    if(line[0] == '#') continue;

    string key = split(line, "=")[0];
    string val = split(line, "=")[1];

    keys[key] = val;
  }

 
  return keys;
}

void main(string args[])
{
  auto join_query - (string[string] p) =>
    p.keys.sort.map!(k => k ~
  auto keys = loadKeys();

  immutable consumer_key = keys["consumer_key"];
  immutable consumer_secret = keys["consumer_secret"];


}

/++
immutable consumer_key = ""

void main(string args[])
{
  // Pass the Twitter ID to the first argument
  assert(args[1], "invalid argument");

  immutable uri = "http://twitter.com/statuses/user_timeline/" ~ args[1] ~ ".json";

  auto created_at = (string date) {
    const d = date.split();

    const time = SysTime(DateTime.fromSimpleString(d[5] ~ "-" ~ d[1] ~ "-" ~ d[2] ~ " " ~ d[3]));

    const duration = time - Clock.currTime() + dur!"hours"(9);

    return
      (duration.weeks < 0)    ? text(time.month, "/", time.day) :
      (duration.days < 0)     ? text(-duration.days, "日前") :
      (duration.hours < 0)    ? text(-duration.hours, "時間前") :
      (duration.minutes < 0)  ? text(-duration.minutes, "分前") :
      text(-duration.seconds, "秒前");
  };

  foreach(o; get(uri).parseJSON().array) {
    writeln(o.object["text"].str, " ", created_at(o.object["created_at"].str));
  }
}
+/
