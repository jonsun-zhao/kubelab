#!/usr/bin/env ruby

require 'json'
require 'pp'

input = `kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[0].address}{"|"}{end}'`.split('|').map do |node|
  node.strip.split(' ')
end

clusters = []
nodes = []

input.each_with_index do |value,index|
  zone = index + 1
  hostname = value[0]
  ip = value[1]

  node = {
    'node' => {
      'hostnames' =>
          {
            'manage' => [hostname],
            'storage' => [ip],
          },
      'zone' => zone
    },
    'devices' => ['/dev/sdb']
  }

  nodes << node
end

clusters << {'nodes' => nodes}

out = {'clusters' => clusters}
puts JSON.pretty_generate(out)
