#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)

require 'dotenv/load'
require 'active_support/all'

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/app")
loader.setup

App.start ARGV
