import std.algorithm	: map, reduce;
import std.base64	: Base64;
import std.conv		: to;
import std.datetime	: Clock, SysTime, DateTime, dur;
import std.json		: JSONValue, parseJSON;
import std.net.curl	: HTTP, post;
import std.stdio	: write, writeln, readln;
import std.string	: join, split, chomp, format, rightJustify;
import std.uri		: encodeComponent;

import deimos.openssl.ssl;

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
