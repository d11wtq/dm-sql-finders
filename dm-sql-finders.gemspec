# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "data_mapper/sql_finders/version"

Gem::Specification.new do |s|
  s.name        = "dm-sql-finders"
  s.version     = DataMapper::SQLFinders::VERSION
  s.authors     = ["d11wtq"]
  s.email       = ["chris@w3style.co.uk"]
  s.homepage    = "https://github.com/d11wtq/dm-sql-finders"
  s.summary     = %q{Query DataMapper models using raw SQL, without sacrificing property and table name abstraction}
  s.description = %q{dm-sql-finders add #by_sql to your DataMapper models and provides a clean mechanism for using
                     the names of the properties in your model, instead of the actual fields in the database. Any SQL
                     is supported and actual DataMapper Query objects wrap the SQL, thus delaying its execution until
                     a kicker method materializes the records for the query.  You can also chain standard DataMapper
                     query methods onto the #by_sql call to refine the query.}

  s.rubyforge_project = "dm-sql-finders"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  DM_VERSION ||= "~> 1.2.0"

  s.add_runtime_dependency "dm-core",               DM_VERSION
  s.add_runtime_dependency "dm-do-adapter",         DM_VERSION

  s.add_development_dependency "rspec",             "~> 2.6"
  s.add_development_dependency "dm-migrations",     DM_VERSION
  s.add_development_dependency "dm-sqlite-adapter", DM_VERSION
end
