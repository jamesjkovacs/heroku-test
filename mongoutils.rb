require "yaml"
require "mongo"

module MongoUtils
  def MongoUtils.mongodb_config(env = "development")
    if env.nil?
      env='development'
    end
    @config ||= YAML.load_file("mongodb.yml")
    raise "missing '#{env}' section mongodb.yml" if @config[env].nil?
    @config[env]
  end


  def MongoUtils.mongodb_connect(env = "development")
    if env.nil?
      env='development'
    end
    config = mongodb_config(env)
    if ! config["MONGOLABS_HOST"].nil?
      mongo_host = config["MONGOLABS_HOST"]
      puts "[#{Time.now}] connecting to #{config["MONGOLABS_DATABASE"]} on #{config["MONGOLABS_HOST"]}"
      db_connection = Mongo::Connection.new(mongo_host, config["MONGOLABS_PORT"]).db(config["MONGOLABS_DATABASE"])
      db_connection.authenticate(config["MONGOLABS_USER"], config["MONGOLABS_PASSWD"])
      db_connection
    else
      raise "missing MONGOLABS_URL or MONGOLABS_HOST_LIST for #{env} environment"
    end
  end  
end