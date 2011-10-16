require "dm-core"
require "dm-do-adapter"
require "data_mapper/sql_finders/sql_builder"
require "data_mapper/sql_finders/sql_parser"
require "data_mapper/sql_finders/adapter"
require "data_mapper/sql_finders/query"
require "data_mapper/sql_finders/sql_helper"
require "data_mapper/sql_finders/version"
require "data_mapper/sql_finders"

DataMapper::Model.append_extensions(DataMapper::SQLFinders)
