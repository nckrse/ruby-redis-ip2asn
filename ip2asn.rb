#!/usr/bin/env ruby

require 'curb'
require 'redis'
require 'optparse'

def ip2long(ip)
  ipAry = ip.split(/\./)
  long = ipAry[3].to_i | ipAry[2].to_i << 8 | ipAry[1].to_i << 16 | ipAry[0].to_i << 24
  long
end

def getMask(ipLong)
  redis = Redis.new
  (0..31).each {|msk|
    ipRef = (ipLong >> msk) << msk
    if redis.get(ipRef).nil?
    else
      return ipRef
    end
  }
end

def redisImport
  redis = Redis.new
  redis.flushall
  http = Curl.get("http://thyme.apnic.net/current/data-raw-table")
  http.body_str.each_line {|s|
    s.scan(/([0-9.]+)\/[0-9]+\s+([0-9]+)/) {|x,y|
      z = ip2long(x)
  	  redis.set(z, y)
    }
  }
  http = Curl.get("http://thyme.apnic.net/current/data-used-autnums")
  http.body_str.each_line {|s|
    s.scan(/([0-9]+)\s+(.*)/) {|x,y|
      redis.set(x, y)
    }
  }
end

userIp = ARGV[0]
redis = Redis.new

ARGV.options do |opts|
  opts.on("--charge")	{ puts "Charging Redis..." ; redisImport ; exit}
  opts.parse!
end

ipLong = ip2long(userIp)
zMask = getMask(ipLong)
zAsn = redis.get(zMask)

puts "(" + userIp + ") belongs to ASN " + zAsn + " - " + redis.get(zAsn)
