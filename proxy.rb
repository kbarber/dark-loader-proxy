#!/usr/bin/env ruby

require 'net/http'

res = Net::HTTP.start('puppetdb1.vm',8080) do |http|
  http.get '/v3/catalogs/puppetdb1.vm'
end
res.body
