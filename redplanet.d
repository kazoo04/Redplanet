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

import deimos.openssl.ssl;

immutable consumer_key = "gi9QcwbtYnsEKQf2HWBGg";
immutable consumer_secret = "iztMAGvqAVKejVLRHwtxvQD251Z06C3MoWXjtDC6A";

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

/*
string[char[]] loadKeys()
{
  auto file = new BufferedFile("keys.conf");

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
*/

void showSplash()
{
  writeln(`
     _____
    |  _  \         _                             _
    | |_)  |___  __| |____  _ __  ___ _____  ___ | |_
    |  _ _/  _ \/ _  |  _ \| '__/ _  |  _  \/ _ \| __|
    | | \ \  __/ (_| | |_) | | / (_| | | | |  __/| |_
    |_|  \_\___|\____|  __/|_| \_____|_| |_|\___| \__|
                     |_|

  `);
}

void getAccessToken()
{


}

void main(string args[])
{
  //auto keys = loadKeys();
  

  showSplash();
   auto join_query = (string[string] p) =>
    p.keys.sort.map!(k => k ~ "=" ~ p[k]).join("&");

  auto split_query = (string query) {
    string[string] p = null;
    foreach(q; query.split("&")) {
      auto s = q.split("=");
      p[s[0]] = s[1];
    }
    return p;
  };

  auto hmac_sha1 = (string key, string data) {
    auto result = new ubyte[SHA_DIGEST_LENGTH];
    HMAC(EVP_sha1(), key.ptr, cast(int)key.length, cast(ubyte*)(data.ptr), 
        data.length, result.ptr, null);
    return result;
  };

  auto oauth_signature = (string method, string url, string query, string csec, string asec = null) {
    auto base = [method, url, query].reduce!((xs, x) => xs ~ "&" ~ x.encodeComponent);
    auto key = [csec, asec].reduce!((xs, x) => xs ~ "&" ~ x.encodeComponent);
    return encodeComponent(cast(immutable)Base64.encode(hmac_sha1(key, base)));
  };

  auto oauth_header = (string[string] p) =>
    "OAuth " ~ p.keys.sort.map!(k => k ~ "=\"" ~ p[k] ~ "\"").join(",");

  auto oauth_post = (string uri, string[string] ps, string asec = null, string status = null) {
    auto param = [
      "oauth_consumer_key"      : consumer_key,
      "oauth_nonce"             : Clock.currTime.toUnixTime.to!string,
      "oauth_signature_method"  : "HMAC-SHA1",
      "oauth_timestamp"         : Clock.currTime.toUnixTime.to!string,
      "oauth_version"           : "1.0"];

    foreach(k; ps.keys) param[k] = ps[k];


    auto signature = oauth_signature("POST", uri, join_query(param), consumer_secret, asec);
    param["oauth_signature"] = signature;

    auto str = (status is null) ? "" : "status=" ~ status;
    auto http = HTTP();
    http.addRequestHeader("Authorization", oauth_header(param));

    writeln("signature = ", signature);
    writeln("param = ", param);
    writeln("\turi = ", uri);
    writeln("\tstr = ", str);
    writeln("\thttp = ", http);

    auto result = cast(immutable)post(uri, str, http);

    writeln("\tresult = ", result);

    return result;
  };

  // run from here
  writeln("get request token");
  auto request_token = (() =>
      split_query(oauth_post(Api.request_token, null))) ();

  writeln("oauth verify");
  auto oauth_verifier = () {
    writeln("open the following url and allow:");
    writeln("\t" ~  Api.authorize ~ "?oauth_token=" ~ request_token["oauth_token"]);
    writeln("input pin:\n\t");
    return readln.chomp;
  }();

  writeln("get access token");
  auto access_token = (() => split_query(
        oauth_post(Api.access_token,
          [ "oauth_verifier" : oauth_verifier, "oauth_token" : request_token["oauth_token"]],
          request_token["oauth_token_secret"]))) ();


  auto param = [
    "oauth_consumer_key"      : consumer_key,
    "oauth_nonce"             : Clock.currTime.toUnixTime.to!string,
    "oauth_signature_method"  : "HMAC-SHA1",
    "oauth_timestamp"         : Clock.currTime.toUnixTime.to!string,
    "oauth_version"           : "1.0",
    "oauth_token"             : access_token["oauth_token"]];

  auto signature = oauth_signature("GET", Stream.user,
      join_query(param), consumer_secret, access_token["oauth_token_secret"]);
  param["oauth_signature"] = signature;
  param["replies"] = "all";

  auto created_at = (JSONValue v) {
    auto d = v.object["created_at"].str.split;
    const t = SysTime(DateTime.fromSimpleString(
      d[5] ~ "-" ~ d[1] ~ "-" ~ d[2] ~ " " ~ d[3])) + dur!"hours"(9);

    return [t.hour, t.minute, t.second].map!(x => x.to!string.rightJustify(2, '0')).join(":");
  };

  auto screen_name = (JSONValue v) => v.object["user"].object["screen_name"].str;
  auto text = (JSONValue v) => v.object["text"].str;

  auto http = HTTP(Stream.user);
  http.addRequestHeader("Authorization", oauth_header(param));
  http.addRequestHeader("User-Agent", "the unspeakable one");
  http.dataTimeout = dur!"seconds"(-1);
  http.onReceive = (ubyte[] data) {
    auto j = (cast(string)data == "\r\n") ? JSONValue() : (cast(string)data).parseJSON;
    if("text" in j.object)
      format("%-15s: %s at %s", screen_name(j), text(j), created_at(j)).writeln;
    return data.length;
  };

  http.perform;


}

