#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra/base'
require 'net/http'
require 'cgi'
require 'uri'
require 'pp'

SERVERS = [
  { :name => 'main', :host => 'puppetdb1.vm', :port => 8080, },
  { :name => 'secondary', :host => 'puppetdb1.vm', :port => 8080, }
]

class App < Sinatra::Base
  helpers do
    def urlencode(param)
      items = []

      params.each do |key,value|
        if value.class == Array
          value.each do |x|
            items.push "#{CGI.escape key.to_s}[]=#{CGI.escape x.to_s}"
          end
        else
          items.push "#{CGI.escape key.to_s}=#{CGI.escape value.to_s}"
        end
      end

      items.join '&'
    end

    def proxy_get(host, port, url)
      res = Net::HTTP.start(host, port) do |http|
        logger.info "getting: #{url}"
        http.get url
      end
    end

    def proxy_post(host, port, url, body)
      res = Net::HTTP.start(host, port) do |http|
        logger.info "posting: #{url}"
        http.post url, body
      end
    end
  end

  before do
    content_type 'application/json'
  end

  # proxy to the remote
  get "/*" do
    servers = SERVERS.dup

    url = params['splat'].join("/")
    extension = url.split(".").last

    params.delete('splat')
    params.delete('captures')

    url = "/#{url}"
    newparams = urlencode params
    url += "?#{newparams}" unless newparams.empty?

    # Main server
    main = servers.shift
    res = proxy_get(main[:host], main[:port], url)

    # Dark servers
    servers.each do |server|
      dark_result = proxy_get(main[:host], main[:port], url)
      puts "result code from #{server[:name]}: #{dark_result.code}"
    end

    # Grab headers from the Net::HTTP request
    new_headers = res.to_hash
    # Remove chunk-encoding, we aren't streaming now
    new_headers.delete('transfer-encoding')

    status res.code
    headers new_headers
    body res.body
  end

  post '/*' do
    body = request.body.read

    servers = SERVERS.dup

    url = params['splat'].join("/")
    extension = url.split(".").last

    params.delete('splat')
    params.delete('captures')

    url = "/#{url}"
    newparams = urlencode params
    #url += "?#{newparams}" unless newparams.empty?

    # Main server
    main = servers.shift
    res = proxy_post(main[:host], main[:port], url, body)

    # Dark servers
    servers.each do |server|
      dark_result = proxy_post(main[:host], main[:port], url, body)
      puts "result code from #{server[:name]}: #{dark_result.code}"
    end

    # Grab headers from the Net::HTTP request
    new_headers = res.to_hash
    # Remove chunk-encoding, we aren't streaming now
    new_headers.delete('transfer-encoding')

    status res.code
    headers new_headers
    body res.body
  end
end
